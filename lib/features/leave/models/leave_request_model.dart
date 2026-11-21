/// Leave Request Management — domain model.
///
/// One stored leave request row per approved/pending/rejected leave entry.
/// Follows the same local-first UUID / SHA-256 / relative-path pattern as
/// [DailyReportModel].
library;

import 'package:uuid/uuid.dart';

/// Status of a leave request's sync lifecycle.
enum LeaveSyncStatus {
  pending,
  approved,
  rejected,
  failed,
  /// Leave request is not present on this device (local-first storage only).
  missingLocal;

  String get apiValue => name;

  static LeaveSyncStatus fromApi(String? value) =>
      LeaveSyncStatus.values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => LeaveSyncStatus.pending,
      );
}

/// Types of leave requests.
enum LeaveType {
  sick,
  vacation,
  personal,
  maternity,
  paternity,
  bereavement,
  other;

  static LeaveType fromString(String? v) =>
      v == 'maternity' ? LeaveType.maternity :
      v == 'paternity' ? LeaveType.paternity :
      v == 'bereavement' ? LeaveType.bereavement :
      v == 'other' ? LeaveType.other :
      LeaveType.sick;

  String get apiValue => name;
}

/// A single stored leave request record (metadata + local/remote pointers).
class LeaveRequestModel {
  LeaveRequestModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.siteId,
    required this.date,
    required this.type,
    required this.reason,
    required this.duration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.localPath = '',
    this.storagePath,
    this.hash,
  });

  final int? id;
  final String uuid;
  int userId;
  int siteId;
  DateTime date;
  LeaveType type;
  String reason;
  double duration; // in days or hours
  LeaveSyncStatus status;
  final String localPath; // RELATIVE path inside the app docs dir
  String? storagePath; // Firebase Storage path
  String? hash; // SHA-256 of the file
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Generate a new v4 uuid for a freshly created leave request.
  static String newUuid() => const Uuid().v4();

  /// Convert to Firestore/RTDB map for cloud sync.
  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'userId': userId,
    'siteId': siteId,
    'date': date.toIso8601String(),
    'type': type.apiValue,
    'reason': reason,
    'duration': duration,
    'status': status.apiValue,
    'localPath': localPath,
    'storagePath': storagePath,
    'hash': hash,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Construct from a Firestore/RTDB map.
  factory LeaveRequestModel.fromMap(Map<String, dynamic> map) => LeaveRequestModel(
    id: map['id'] as int?,
    uuid: map['uuid'] as String,
    userId: map['userId'] as int,
    siteId: map['siteId'] as int,
    date: DateTime.parse(map['date'] as String),
    type: LeaveType.fromString(map['type'] as String?),
    reason: map['reason'] as String,
    duration: (map['duration'] as num).toDouble(),
    status: LeaveSyncStatus.fromApi(map['status'] as String?),
    localPath: map['localPath'] as String? ?? '',
    storagePath: map['storagePath'] as String?,
    hash: map['hash'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Copy with modified fields for immutable updates.
  LeaveRequestModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? siteId,
    DateTime? date,
    LeaveType? type,
    String? reason,
    double? duration,
    LeaveSyncStatus? status,
    String? localPath,
    String? storagePath,
    String? hash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      siteId: siteId ?? this.siteId,
      date: date ?? this.date,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      hash: hash ?? this.hash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}