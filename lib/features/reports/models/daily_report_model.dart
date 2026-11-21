/// Daily Report Management — domain model.
///
/// One unified [DailyReportModel] row per daily site report. Follows the same
/// local-first UUID / SHA-256 / relative-path pattern as [DocumentModel].
library;

import 'package:uuid/uuid.dart';

/// Status of a daily report's sync lifecycle.
enum DailyReportSyncStatus {
  pending,
  uploading,
  synced,
  failed,
  /// Report is not present on this device (local-first storage only).
  missingLocal;

  String get apiValue => name;

  /// Convert from SQLite TEXT value (e.g., 'pending', 'uploading', 'synced', 'failed').
  static DailyReportSyncStatus fromApi(String? value) =>
      DailyReportSyncStatus.values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => DailyReportSyncStatus.pending,
      );

  /// Convert from SQLite INTEGER (0 = pending, 1 = uploading, 2 = synced, 3 = failed, 4 = missingLocal).
  /// Note: SQLite stores sync_status as TEXT; this method is kept for backward compatibility.
  static DailyReportSyncStatus fromInt(int? value) {
    switch (value) {
      case 1:
        return DailyReportSyncStatus.uploading;
      case 2:
        return DailyReportSyncStatus.synced;
      case 3:
        return DailyReportSyncStatus.failed;
      default:
        return DailyReportSyncStatus.pending;
    }
  }

  /// Convert to SQLite INTEGER for storage.
  /// Note: SQLite stores sync_status as TEXT; this method is kept for potential use.
  int toInt() {
    switch (this) {
      case DailyReportSyncStatus.pending:
        return 0;
      case DailyReportSyncStatus.uploading:
        return 1;
      case DailyReportSyncStatus.synced:
        return 2;
      case DailyReportSyncStatus.failed:
        return 3;
      case DailyReportSyncStatus.missingLocal:
        return 4;
    }
  }
}

/// Kinds of daily report content.
enum DailyReportKind {
  text,
  image,
  pdf;

  static DailyReportKind fromString(String? v) =>
      v == 'image' ? DailyReportKind.image :
      v == 'pdf' ? DailyReportKind.pdf : DailyReportKind.text;
}

/// A single stored daily report (metadata + local/remote pointers).
class DailyReportModel {
  DailyReportModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.siteId,
    required this.date,
    this.title,
    required this.kind,
    required this.contentRef, // relative path or URL reference
    required this.fileName,
    this.mimeType,
    this.sizeBytes,
    required this.localPath, // RELATIVE path inside the app docs dir
    this.storagePath, // Firebase Storage path (users/{uid}/daily-reports/...)
    this.hash, // SHA-256 of the file (dedupe + integrity)
    this.thumbPath, // RELATIVE path to generated thumbnail (images)
    this.syncStatus = DailyReportSyncStatus.pending,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String uuid;
  final int userId;
  final int siteId;
  final DateTime date;
  final String? title;
  final DailyReportKind kind;
  final String contentRef; // relative path or URL reference
  final String fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String localPath; // RELATIVE path inside the app docs dir
  final String? storagePath; // Firebase Storage path
  final String? hash; // SHA-256 of the file
  final String? thumbPath; // RELATIVE path to generated thumbnail
  final DailyReportSyncStatus syncStatus;
  final bool isDeleted;
  final String? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Generate a new v4 uuid for a freshly captured/selected file.
  static String newUuid() => const Uuid().v4();

  /// Create a copy of this model with the given fields replaced.
  DailyReportModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? siteId,
    DateTime? date,
    String? title,
    DailyReportKind? kind,
    String? contentRef,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? localPath,
    String? storagePath,
    String? hash,
    String? thumbPath,
    DailyReportSyncStatus? syncStatus,
    bool? isDeleted,
    String? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyReportModel(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        userId: userId ?? this.userId,
        siteId: siteId ?? this.siteId,
        date: date ?? this.date,
        title: title ?? this.title,
        kind: kind ?? this.kind,
        contentRef: contentRef ?? this.contentRef,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        localPath: localPath ?? this.localPath,
        storagePath: storagePath ?? this.storagePath,
        hash: hash ?? this.hash,
        thumbPath: thumbPath ?? this.thumbPath,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt ?? this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Convert to map for SQLite storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'user_id': userId,
        'site_id': siteId,
        'date': date.toIso8601String(),
        'title': title,
        'kind': kind.toString().split('.').last,
        'content_ref': contentRef,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'local_path': localPath,
        'storage_path': storagePath,
        'hash': hash,
        'thumb_path': thumbPath,
        'sync_status': syncStatus.toInt(),
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Convert to Firestore/RTDB map for cloud sync.
  Map<String, dynamic> toFireStoreMap() => {
        'uuid': uuid,
        'userId': userId,
        'siteId': siteId,
        'date': date.toIso8601String(),
        'title': title,
        'kind': kind.toString().split('.').last,
        'contentRef': contentRef,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'storagePath': storagePath,
        'hash': hash,
        'thumbPath': thumbPath,
        'syncStatus': syncStatus.apiValue,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Construct from a SQLite map.
  factory DailyReportModel.fromMap(Map<String, dynamic> map) => DailyReportModel(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        userId: map['user_id'] as int,
        siteId: map['site_id'] as int,
        date: DateTime.parse(map['date'] as String),
        title: map['title'] as String?,
        kind: DailyReportKind.fromString(map['kind'] as String?),
        contentRef: map['content_ref'] as String,
        fileName: map['file_name'] as String,
        mimeType: map['mime_type'] as String?,
        sizeBytes: map['size_bytes'] as int?,
        localPath: map['local_path'] as String,
        storagePath: map['storage_path'] as String?,
        hash: map['hash'] as String?,
        thumbPath: map['thumb_path'] as String?,
        syncStatus: DailyReportSyncStatus.fromApi(map['sync_status'] as String?),
        isDeleted: (map['is_deleted'] as int?) == 1,
        deletedAt: map['deleted_at'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  /// Construct from a Firestore/RTDB map.
  factory DailyReportModel.fromFireStoreMap(Map<String, dynamic> map) =>
      DailyReportModel(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        userId: map['userId'] as int,
        siteId: map['siteId'] as int,
        date: DateTime.parse(map['date'] as String),
        title: map['title'] as String?,
        kind: DailyReportKind.fromString(map['kind'] as String?),
        contentRef: map['contentRef'] as String,
        fileName: map['fileName'] as String,
        mimeType: map['mimeType'] as String?,
        sizeBytes: map['sizeBytes'] as int?,
        localPath: map['localPath'] as String,
        storagePath: map['storagePath'] as String?,
        hash: map['hash'] as String?,
        thumbPath: map['thumbPath'] as String?,
        syncStatus: DailyReportSyncStatus.fromApi(map['syncStatus'] as String?),
        isDeleted: map['isDeleted'] as bool? ?? false,
        deletedAt: map['deletedAt'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}

/// A photo attachment linked to a daily report.
///
/// Follows the same local-first UUID / SHA-256 / relative-path pattern as
/// [DailyReportModel] and worker documents.
class DailyReportPhotoModel {
  DailyReportPhotoModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.dailyReportId,
    required this.fileName,
    this.mimeType,
    required this.sizeBytes,
    required this.localPath,
    this.hash,
    this.syncStatus = DailyReportSyncStatus.pending,
    this.isDeleted = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String uuid;
  final int userId;
  final int dailyReportId;
  final String fileName;
  final String? mimeType;
  final int sizeBytes;
  final String localPath; // RELATIVE path inside the app docs dir
  final String? hash; // SHA-256 of the file
  final DailyReportSyncStatus syncStatus;
  final bool isDeleted;
  final String? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Create a copy of this model with the given fields replaced.
  DailyReportPhotoModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? dailyReportId,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    String? localPath,
    String? hash,
    DailyReportSyncStatus? syncStatus,
    bool? isDeleted,
    String? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DailyReportPhotoModel(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        userId: userId ?? this.userId,
        dailyReportId: dailyReportId ?? this.dailyReportId,
        fileName: fileName ?? this.fileName,
        mimeType: mimeType ?? this.mimeType,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        localPath: localPath ?? this.localPath,
        hash: hash ?? this.hash,
        syncStatus: syncStatus ?? this.syncStatus,
        isDeleted: isDeleted ?? this.isDeleted,
        deletedAt: deletedAt ?? this.deletedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Convert to map for SQLite storage.
  Map<String, dynamic> toMap() => {
        'id': id,
        'uuid': uuid,
        'user_id': userId,
        'daily_report_id': dailyReportId,
        'file_name': fileName,
        'mime_type': mimeType,
        'size_bytes': sizeBytes,
        'local_path': localPath,
        'hash': hash,
        'sync_status': syncStatus.apiValue,
        'is_deleted': isDeleted ? 1 : 0,
        'deleted_at': deletedAt,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Convert to Firestore/RTDB map for cloud sync.
  Map<String, dynamic> toFireStoreMap() => {
        'uuid': uuid,
        'userId': userId,
        'dailyReportId': dailyReportId,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'localPath': localPath,
        'hash': hash,
        'syncStatus': syncStatus.apiValue,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Construct from a SQLite map.
  factory DailyReportPhotoModel.fromMap(Map<String, dynamic> map) =>
      DailyReportPhotoModel(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        userId: map['user_id'] as int,
        dailyReportId: map['daily_report_id'] as int,
        fileName: map['file_name'] as String,
        mimeType: map['mime_type'] as String?,
        sizeBytes: map['size_bytes'] as int,
        localPath: map['local_path'] as String,
        hash: map['hash'] as String?,
        syncStatus: DailyReportSyncStatus.fromApi(map['sync_status'] as String?),
        isDeleted: (map['is_deleted'] as int?) == 1,
        deletedAt: map['deleted_at'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  /// Construct from a Firestore/RTDB map.
  factory DailyReportPhotoModel.fromFireStoreMap(Map<String, dynamic> map) =>
      DailyReportPhotoModel(
        id: map['id'] as int?,
        uuid: map['uuid'] as String,
        userId: map['userId'] as int,
        dailyReportId: map['dailyReportId'] as int,
        fileName: map['fileName'] as String,
        mimeType: map['mimeType'] as String?,
        sizeBytes: map['sizeBytes'] as int,
        localPath: map['localPath'] as String,
        hash: map['hash'] as String?,
        syncStatus: DailyReportSyncStatus.fromApi(map['syncStatus'] as String?),
        isDeleted: map['isDeleted'] as bool? ?? false,
        deletedAt: map['deletedAt'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
        updatedAt: DateTime.parse(map['updatedAt'] as String),
      );
}