/// Document Management — domain model + enums.
///
/// One unified [DocumentModel] row per stored file. The `documents` table is
/// additive (v19) and covers all six entity types via [DocumentEntityType].
library;

import 'package:uuid/uuid.dart';

/// The entity a document is attached to.
enum DocumentEntityType {
  worker,
  site,
  product,
  payroll,
  payment,
  service;

  String get apiValue => name;

  static DocumentEntityType fromApi(String? value) =>
      DocumentEntityType.values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => DocumentEntityType.worker,
      );
}

/// Upload/sync lifecycle for a document's binary file.
enum DocumentSyncStatus {
  pending,
  uploading,
  synced,
  failed,
  /// Binary is not present on this device (local-first storage only).
  missingLocal;

  String get apiValue => name;

  static DocumentSyncStatus fromApi(String? value) =>
      DocumentSyncStatus.values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => DocumentSyncStatus.pending,
      );
}

/// Supported binary types. `unsupported` is used when MIME/ext validation fails.
enum DocumentKind {
  image,
  pdf,
  docx,
  xlsx,
  unsupported;

  static DocumentKind fromExt(String? ext, String? mime) {
    final e = (ext ?? '').toLowerCase();
    final m = (mime ?? '').toLowerCase();
    if (m.startsWith('image/') ||
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(e)) {
      return DocumentKind.image;
    }
    if (e == 'pdf' || m == 'application/pdf') return DocumentKind.pdf;
    if (['docx', 'doc'].contains(e) ||
        m.contains('wordprocessingml') ||
        m.contains('msword')) {
      return DocumentKind.docx;
    }
    if (['xlsx', 'xls'].contains(e) ||
        m.contains('spreadsheetml') ||
        m.contains('ms-excel')) {
      return DocumentKind.xlsx;
    }
    return DocumentKind.unsupported;
  }
}

/// A single stored document (metadata + local/remote pointers).
class DocumentModel {
  DocumentModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.entityType,
    this.entityId,
    this.category,
    required this.fileName,
    this.mimeType,
    this.ext,
    required this.sizeBytes,
    required this.localPath,
    this.storagePath,
    this.thumbPath,
    this.hash,
    this.version = 1,
    this.replacesUuid,
    this.syncStatus = DocumentSyncStatus.pending,
    this.isDeleted = false,
    this.deletedAt,
    this.width,
    this.height,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String uuid;
  final int userId;
  final DocumentEntityType entityType;
  final int? entityId;
  final String? category;
  final String fileName;
  final String? mimeType;
  final String? ext;
  final int sizeBytes;
  final String localPath; // RELATIVE path inside the app docs dir
  final String? storagePath; // Firebase Storage path (users/{uid}/documents/...)
  final String? thumbPath; // RELATIVE path to generated thumbnail (images)
  final String? hash; // SHA-256 of the file (dedupe + integrity)
  final int version;
  final String? replacesUuid; // prior version's uuid (versioning chain)
  final DocumentSyncStatus syncStatus;
  final bool isDeleted;
  final DateTime? deletedAt;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final DateTime updatedAt;

  DocumentKind get kind => DocumentKind.fromExt(ext, mimeType);

  bool get isImage => kind == DocumentKind.image;
  bool get isSynced => syncStatus == DocumentSyncStatus.synced;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'uuid': uuid,
        'user_id': userId,
        'entity_type': entityType.apiValue,
        'entity_id': entityId,
        'category': category,
        'file_name': fileName,
        'mime_type': mimeType,
        'ext': ext,
        'size_bytes': sizeBytes,
        'local_path': localPath,
        'storage_path': storagePath,
        'thumb_path': thumbPath,
        'hash': hash,
        'version': version,
        'replaces_uuid': replacesUuid,
        'sync_status': syncStatus.apiValue,
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt?.toIso8601String(),
        'width': width,
        'height': height,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Parse a DB row. Never throws on missing keys (defensive for old rows).
  factory DocumentModel.fromMap(Map<String, dynamic> m) => DocumentModel(
        id: m['id'] as int?,
        uuid: m['uuid'] as String,
        userId: m['user_id'] as int,
        entityType: DocumentEntityType.fromApi(m['entity_type'] as String?),
        entityId: m['entity_id'] as int?,
        category: m['category'] as String?,
        fileName: m['file_name'] as String,
        mimeType: m['mime_type'] as String?,
        ext: m['ext'] as String?,
        sizeBytes: m['size_bytes'] as int,
        localPath: m['local_path'] as String,
        storagePath: m['storage_path'] as String?,
        thumbPath: m['thumb_path'] as String?,
        hash: m['hash'] as String?,
        version: (m['version'] as int?) ?? 1,
        replacesUuid: m['replaces_uuid'] as String?,
        syncStatus: DocumentSyncStatus.fromApi(m['sync_status'] as String?),
        isDeleted: (m['is_deleted'] as int? ?? 0) == 1,
        deletedAt: m['deleted_at'] != null
            ? DateTime.tryParse(m['deleted_at'] as String)
            : null,
        width: m['width'] as int?,
        height: m['height'] as int?,
        createdAt: DateTime.parse(m['created_at'] as String),
        updatedAt: DateTime.parse(m['updated_at'] as String),
      );

  /// Metadata blob that is mirrored into Firebase Realtime Database.
  /// Never includes the binary or the absolute file path.
  Map<String, dynamic> toFirebaseMeta() => {
        'uuid': uuid,
        'entityType': entityType.apiValue,
        'entityId': entityId,
        'category': category,
        'fileName': fileName,
        'ext': ext,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'storagePath': storagePath,
        'hash': hash,
        'version': version,
        'replacesUuid': replacesUuid,
        'syncStatus': syncStatus.apiValue,
        'width': width,
        'height': height,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  DocumentModel copyWith({
    String? storagePath,
    String? thumbPath,
    DocumentSyncStatus? syncStatus,
    String? category,
    String? fileName,
    String? hash,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) =>
      DocumentModel(
        id: id,
        uuid: uuid,
        userId: userId,
        entityType: entityType,
        entityId: entityId,
        category: category ?? this.category,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType,
        ext: ext,
        sizeBytes: sizeBytes,
        localPath: localPath,
        storagePath: storagePath ?? this.storagePath,
        thumbPath: thumbPath ?? this.thumbPath,
        hash: hash ?? this.hash,
        version: version,
        replacesUuid: replacesUuid,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt ?? this.deletedAt,
        width: width,
        height: height,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Generate a new v1 uuid for a freshly captured/selected file.
  static String newUuid() => const Uuid().v4();
}