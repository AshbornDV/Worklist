/// Document Management — local file service.
///
/// Responsibilities (offline-first):
///  • Resolve the platform base dir (Android Documents / Windows App Support).
///  • Save incoming files under a UUID name (never preserve the caller's name
///    on disk; the original name is kept only as metadata).
///  • Compute SHA-256 for dedupe + integrity.
///  • Generate a thumbnail for images.
///  • Store ONLY relative paths; resolve absolute paths lazily at read time.
library;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/document_model.dart';

class DocumentFileService {
  DocumentFileService._();
  static final DocumentFileService instance = DocumentFileService._();

  static const _dirName = 'documents';

  /// Base directory inside the app's private storage. Never user-visible path.
  Future<Directory> get baseDir async {
    final appDir = Platform.isAndroid
        ? await getApplicationDocumentsDirectory()
        : await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, _dirName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> get _thumbDir async {
    final base = await baseDir;
    final dir = Directory(p.join(base.path, 'thumbs'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Resolve a stored RELATIVE path to an absolute [File] (lazy; safe).
  Future<File> resolveFile(String relativePath) async {
    final base = await baseDir;
    return File(p.join(base.path, relativePath));
  }

  String _relative(String fileName) => fileName;

  Future<String> _sha256(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Public SHA-256 helper for an arbitrary local file.
  Future<String> hashFile(File file) => _sha256(file);

  /// Validate file type and reject unsupported formats. Returns the kind.
  DocumentKind _validate(String ext, String? mime) {
    final kind = DocumentKind.fromExt(ext, mime);
    if (kind == DocumentKind.unsupported) {
      throw const DocumentFormatException('Unsupported file type.');
    }
    return kind;
  }

  /// Persist a picked/captured [source] file as a new document asset.
  ///
  /// [originalName] is kept as metadata only. Returns the populated
  /// [DocumentModel] (with relative local_path, hash, size, dims, thumb).
  Future<DocumentModel> ingest({
    required File source,
    required int userId,
    required DocumentEntityType entityType,
    int? entityId,
    String? category,
    required String originalName,
    String? mimeType,
    String? replacesUuid,
    int version = 1,
  }) async {
    final ext = p.extension(originalName).replaceAll('.', '').toLowerCase();
    final kind = _validate(ext, mimeType);
    debugPrint('[Docs:file] ingest start ext=$ext kind=${kind.name} src=${source.path}');
    final uuid = DocumentModel.newUuid();
    final base = await baseDir;
    final destName = '$uuid.$ext';
    final dest = File(p.join(base.path, destName));
    await source.copy(dest.path);
    debugPrint('[Docs:file] copied -> ${dest.path}');

    final size = await dest.length();
    final hash = await _sha256(dest);

    String? thumbRelative;
    int? width;
    int? height;
    if (kind == DocumentKind.image) {
      final decoded = img.decodeImage(await dest.readAsBytes());
      if (decoded != null) {
        width = decoded.width;
        height = decoded.height;
        final thumb = img.copyResize(decoded,
            width: decoded.width > 320 ? 320 : decoded.width);
        final tDir = await _thumbDir;
        final thumbFile = File(p.join(tDir.path, '$uuid.jpg'));
        await thumbFile.writeAsBytes(img.encodeJpg(thumb, quality: 80));
        thumbRelative = _relative(p.join('thumbs', '$uuid.jpg'));
        debugPrint('[Docs:file] thumbnail -> ${thumbFile.path} '
            '${width}x$height');
      } else {
        debugPrint('[Docs:file] thumbnail skipped (image decode failed)');
      }
    }

    final now = DateTime.now();
    return DocumentModel(
      uuid: uuid,
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      category: category,
      fileName: originalName,
      mimeType: mimeType,
      ext: ext,
      sizeBytes: size,
      localPath: _relative(destName),
      thumbPath: thumbRelative,
      hash: hash,
      version: version,
      replacesUuid: replacesUuid,
      syncStatus: DocumentSyncStatus.pending,
      width: width,
      height: height,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Replace the binary of an existing (soft-deleted-free) document, producing
  /// a new version. The previous version remains (versioning). Returns the new
  /// [DocumentModel] (caller inserts it; sets [replacesUuid] + version+1).
  Future<DocumentModel> ingestVersion({
    required File source,
    required DocumentModel previous,
    required String originalName,
    String? mimeType,
  }) =>
      ingest(
        source: source,
        userId: previous.userId,
        entityType: previous.entityType,
        entityId: previous.entityId,
        category: previous.category,
        originalName: originalName,
        mimeType: mimeType,
        replacesUuid: previous.uuid,
        version: previous.version + 1,
      );

  /// Delete the on-disk binary + thumbnail for a document (after soft/hard
  /// delete has been recorded). Best-effort; ignores missing files.
  Future<void> deleteFiles(DocumentModel doc) async {
    try {
      final f = await resolveFile(doc.localPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
    if (doc.thumbPath != null) {
      try {
        final t = await resolveFile(doc.thumbPath!);
        if (await t.exists()) await t.delete();
      } catch (_) {}
    }
  }

  /// True when the binary currently exists on this device.
  Future<bool> existsLocally(DocumentModel doc) async {
    try {
      return await (await resolveFile(doc.localPath)).exists();
    } catch (_) {
      return false;
    }
  }
}

class DocumentFormatException implements Exception {
  const DocumentFormatException(this.message);
  final String message;
  @override
  String toString() => 'DocumentFormatException: $message';
}