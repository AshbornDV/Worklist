/// Document Management — provider.
///
/// UI-facing orchestration over [DocumentRepository] + [DocumentFileService] +
/// [DocumentStorageService]. Reuses the EXISTING RTDB sync (FirebaseCloudService
/// .uploadLocalUser) to push document metadata — no new sync wiring.
library;

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/firebase/firebase_cloud_service.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';
import '../services/document_file_service.dart';
import '../services/document_permissions.dart';
import '../services/document_storage_service.dart';

enum DocumentSort { dateDesc, dateAsc, nameAsc, sizeDesc }

class DocumentProvider extends ChangeNotifier {
  DocumentProvider({
    DocumentEntityType? scopedType,
    int? scopedEntityId,
  })  : _scopedType = scopedType,
        _scopedEntityId = scopedEntityId;

  final DocumentEntityType? _scopedType;
  final int? _scopedEntityId;

  final _repo = DocumentRepository();
  final _files = DocumentFileService.instance;
  final _storage = DocumentStorageService.instance;

  List<DocumentModel> _docs = const [];
  bool _loading = false;
  String _search = '';
  DocumentEntityType? _filterType = DocumentEntityType.worker;
  String? _filterCategory;
  DocumentSort _sort = DocumentSort.dateDesc;
  bool _showTrash = false;
  String? _error;

  List<DocumentModel> get docs => _docs;
  bool get loading => _loading;
  String get search => _search;
  DocumentEntityType? get filterType => _filterType;
  String? get filterCategory => _filterCategory;
  DocumentSort get sort => _sort;
  bool get showTrash => _showTrash;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = _showTrash
          ? await _repo.list(includeDeleted: true)
          : await _repo.list(
              entityType: _scopedType,
              entityId: _scopedEntityId,
            );
      _docs = _applyView(
          list.where((d) => _showTrash ? d.isDeleted : !d.isDeleted).toList());
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<DocumentModel> _applyView(List<DocumentModel> input) {
    var list = input;
    if (!_showTrash) {
      if (_filterType != null) {
        list = list.where((d) => d.entityType == _filterType).toList();
      }
      if (_filterCategory != null) {
        list = list.where((d) => d.category == _filterCategory).toList();
      }
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        list = list
            .where((d) =>
                d.fileName.toLowerCase().contains(q) ||
                (d.category ?? '').toLowerCase().contains(q))
            .toList();
      }
    }
    list = switch (_sort) {
      DocumentSort.dateDesc =>
        [...list]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      DocumentSort.dateAsc =>
        [...list]..sort((a, b) => a.updatedAt.compareTo(b.updatedAt)),
      DocumentSort.nameAsc => [...list]
        ..sort((a, b) =>
            a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase())),
      DocumentSort.sizeDesc =>
        [...list]..sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes)),
    };
    return list;
  }

  void setSearch(String value) {
    _search = value;
    load();
  }

  void setFilterType(DocumentEntityType? type) {
    _filterType = type;
    load();
  }

  void setFilterCategory(String? category) {
    _filterCategory = category;
    load();
  }

  void setSort(DocumentSort sort) {
    _sort = sort;
    load();
  }

  void toggleTrash() {
    _showTrash = !_showTrash;
    load();
  }

  /// Categories available among the current view (for the filter chip row).
  List<String> get availableCategories => _docs
      .map((d) => d.category)
      .whereType<String>()
      .toSet()
      .toList()
    ..sort();

  // ───────────────────────── MUTATIONS ─────────────────────────

  Future<void> _ingestAndUpload(DocumentModel doc) async {
    debugPrint('[Docs:provider] insert uuid=${doc.uuid} '
        'entity=${doc.entityType.name} name=${doc.fileName}');
    await _repo.insert(doc);
    notifyListeners();
    try {
      await _storage.upload(doc, onProgress: (_) {});
    } catch (e) {
      debugPrint('[Docs:provider] upload queued (offline?): $e');
    }
    await _pushMetadata();
    await load();
  }

  /// Capture from camera (images only). Returns true on success.
  Future<bool> captureFromCamera({
    required BuildContext context,
    required DocumentEntityType entityType,
    int? entityId,
    String? category,
  }) async {
    final granted =
        await DocumentPermissions.instance.requestCamera(context);
    if (!granted) return false;
    final picked = await ImagePicker().pickImage(source: ImageSource.camera);
    if (picked == null) {
      debugPrint('[Docs:provider] camera cancelled');
      return false;
    }
    debugPrint('[Docs:provider] camera picked ${picked.path}');
    await _ingestPath(
      File(picked.path),
      entityType: entityType,
      entityId: entityId,
      category: category,
      mimeType: 'image/${picked.path.split('.').last}',
    );
    return true;
  }

  /// Pick from gallery / file system (images, PDF, DOCX, XLSX).
  /// Returns the number of files ingested (0 if cancelled/denied).
  Future<int> pickFiles({
    required BuildContext context,
    required DocumentEntityType entityType,
    int? entityId,
    String? category,
    bool multiple = true,
  }) async {
    final granted =
        await DocumentPermissions.instance.requestGallery(context);
    if (!granted) return 0;
    final result = await FilePicker.pickFiles(
      allowMultiple: multiple,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx', 'xlsx'],
      withData: false,
    );
    if (result == null) {
      debugPrint('[Docs:provider] file picker cancelled');
      return 0;
    }
    var count = 0;
    for (final f in result.files) {
      if (f.path == null) continue;
      debugPrint('[Docs:provider] picked file ${f.path}');
      await _ingestPath(
        File(f.path!),
        entityType: entityType,
        entityId: entityId,
        category: category,
        mimeType: f.xFile.mimeType,
      );
      count++;
    }
    return count;
  }

  Future<void> _ingestPath(
    File file, {
    required DocumentEntityType entityType,
    int? entityId,
    String? category,
    String? mimeType,
  }) async {
    final userId = DatabaseHelper().requireUserId();
    final doc = await _files.ingest(
      source: file,
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      category: category,
      originalName: file.path.split(RegExp(r'[/\\]')).last,
      mimeType: mimeType,
    );
    await _ingestAndUpload(doc);
  }

  /// Replace a document with a new binary -> new version (history preserved).
  Future<void> replaceWith(File file, DocumentModel previous) async {
    final newDoc = await _files.ingestVersion(
      source: file,
      previous: previous,
      originalName: file.path.split(RegExp(r'[/\\]')).last,
      mimeType: previous.mimeType,
    );
    await _repo.insert(newDoc);
    notifyListeners();
    try {
      await _storage.upload(newDoc, onProgress: (_) {});
    } catch (e) {
      debugPrint('[Docs] replace upload queued: $e');
    }
    await _pushMetadata();
    await load();
  }

  Future<void> rename(DocumentModel doc, String newName) async {
    await _repo.update(doc.copyWith(
      fileName: newName,
      updatedAt: DateTime.now(),
    ));
    await _pushMetadata();
    await load();
  }

  Future<void> setCategory(DocumentModel doc, String? category) async {
    await _repo.update(doc.copyWith(
      category: category,
      updatedAt: DateTime.now(),
    ));
    await _pushMetadata();
    await load();
  }

  Future<void> softDelete(DocumentModel doc) async {
    debugPrint('[Docs:provider] softDelete ${doc.uuid}');
    await _repo.softDelete(doc.uuid);
    await _pushMetadata();
    await load();
  }

  Future<void> restore(DocumentModel doc) async {
    debugPrint('[Docs:provider] restore ${doc.uuid}');
    await _repo.restore(doc.uuid);
    await _pushMetadata();
    await load();
  }

  /// Purge: remove DB row + local binary + Storage binary.
  Future<void> purge(DocumentModel doc) async {
    debugPrint('[Docs:provider] purge ${doc.uuid}');
    await _storage.deleteFromStorage(doc);
    await _files.deleteFiles(doc);
    await _repo.hardDelete(doc.uuid);
    await _pushMetadata();
    await load();
  }

  /// Retry failed/pending uploads (also called when connectivity returns).
  Future<void> retryQueue() async {
    await _storage.processQueue();
    await _pushMetadata();
    await load();
  }

  /// Ensure the document binary is available locally (download if needed).
  /// Returns `null` if the binary is not present on this device.
  Future<File?> ensureLocal(DocumentModel doc) async {
    if (await _files.existsLocally(doc)) {
      final f = await _files.resolveFile(doc.localPath);
      debugPrint('[Docs:provider] ensureLocal present ${f.path}');
      return f;
    }
    debugPrint('[Docs:provider] ensureLocal MISSING for ${doc.uuid}');
    return _storage.download(doc, onProgress: (_) {});
  }

  /// Re-push document metadata through the EXISTING RTDB sync path.
  Future<void> _pushMetadata() async {
    try {
      final uid = DatabaseHelper().requireUserId();
      await FirebaseCloudService.instance
          .uploadLocalUser(uid, reason: 'documents');
    } catch (e) {
      debugPrint('[Docs] metadata push skipped: $e');
    }
  }

  /// Walk the replaces_uuid chain for a document's version history.
  List<DocumentModel> versionHistory(DocumentModel doc) {
    final chain = <DocumentModel>[];
    DocumentModel? cur = doc;
    while (cur != null && chain.length < 50) {
      chain.add(cur);
      cur = _docs.where((d) => d.uuid == cur!.replacesUuid).firstOrNull;
    }
    return chain;
  }
}