/// Shift Management — domain model.
///
/// One stored shift row per clock-in/clock-out/break/overtime event.
/// Follows the same local-first UUID / SHA-256 / relative-path pattern as
/// [DailyReportModel].
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Status of a shift's sync lifecycle.
enum ShiftSyncStatus {
  pending,
  uploading,
  synced,
  failed,
  /// Shift is not present on this device (local-first storage only).
  missingLocal;

  String get apiValue => name;

  static ShiftSyncStatus fromApi(String? value) =>
      ShiftSyncStatus.values.firstWhere(
        (e) => e.apiValue == value,
        orElse: () => ShiftSyncStatus.pending,
      );
}

/// Kinds of shift events.
enum ShiftKind {
  clockIn,
  clockOut,
  break,
  overtime;

  static ShiftKind fromString(String? v) =>
      v == 'break' ? ShiftKind.break :
      v == 'overtime' ? ShiftKind.overtime :
      v == 'clockOut' ? ShiftKind.clockOut :
      ShiftKind.clockIn;

  String get apiValue => name;
}

/// A single stored shift record (metadata + local/remote pointers).
class ShiftModel {
  ShiftModel({
    this.id,
    required this.uuid,
    required this.userId,
    required this.siteId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.kind,
    required this.status,
    this.totalHours,
    required this.localPath, // RELATIVE path inside the app docs dir
    this.storagePath, // Firebase Storage path (users/{uid}/shifts/...)
    this.hash, // SHA-256 of any associated media
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String uuid;
  int userId;
  int siteId;
  DateTime date;
  TimeOfDay startTime;
  TimeOfDay endTime;
  ShiftKind kind;
  ShiftSyncStatus status; // e.g. pending, uploading, synced, failed, missingLocal
  double? totalHours;
  String localPath; // RELATIVE path inside the app docs dir
  String? storagePath; // Firebase Storage path
  String? hash; // SHA-256 of the file
  DateTime createdAt;
  DateTime updatedAt;

  /// Generate a new v4 uuid for a freshly recorded shift.
  static String newUuid() => const Uuid().v4();

  /// Convert to Firestore/RTDB map for cloud sync.
  Map<String, dynamic> toMap() => {
    'uuid': uuid,
    'userId': userId,
    'siteId': siteId,
    'date': date.toIso8601String(),
    'startTime': _timeOfDayToString(startTime),
    'endTime': _timeOfDayToString(endTime),
    'kind': kind.apiValue,
    'status': status.apiValue,
    'totalHours': totalHours,
    'localPath': localPath,
    'storagePath': storagePath,
    'hash': hash,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Construct from a Firestore/RTDB map.
  factory ShiftModel.fromMap(Map<String, dynamic> map) => ShiftModel(
    id: map['id'] as int?,
    uuid: map['uuid'] as String,
    userId: map['userId'] as int,
    siteId: map['siteId'] as int,
    date: DateTime.parse(map['date'] as String),
    startTime: _stringToTimeOfDay(map['startTime'] as String),
    endTime: _stringToTimeOfDay(map['endTime'] as String),
    kind: ShiftKind.fromString(map['kind'] as String?),
    status: ShiftSyncStatus.fromApi(map['status'] as String?),
    totalHours: (map['totalHours'] as num?)?.toDouble(),
    localPath: map['localPath'] as String,
    storagePath: map['storagePath'] as String?,
    hash: map['hash'] as String?,
    createdAt: DateTime.parse(map['createdAt'] as String),
    updatedAt: DateTime.parse(map['updatedAt'] as String),
  );

  /// Copy with modified fields for immutable updates.
  ShiftModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    int? siteId,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    ShiftKind? kind,
    ShiftSyncStatus? status,
    double? totalHours,
    String? localPath,
    String? storagePath,
    String? hash,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      siteId: siteId ?? this.siteId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      totalHours: totalHours ?? this.totalHours,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      hash: hash ?? this.hash,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Helper to serialize TimeOfDay to HH:mm format.
  static String _timeOfDayToString(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Helper to deserialize HH:mm string to TimeOfDay.
  static TimeOfDay _stringToTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}