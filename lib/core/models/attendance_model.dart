class AttendanceModel {
  final int? id;
  final int workerId;
  final int siteId;
  final String date; // Format: yyyy-MM-dd
  final String type; // 'full', 'half', 'absent'
  final DateTime createdAt;

  // Optional denormalized fields from joins
  final String? workerName;
  final String? siteName;

  const AttendanceModel({
    this.id,
    required this.workerId,
    required this.siteId,
    required this.date,
    required this.type,
    required this.createdAt,
    this.workerName,
    this.siteName,
  });

  bool get isFull => type == 'full';
  bool get isHalf => type == 'half';
  bool get isAbsent => type == 'absent';

  /// Returns multiplier: 1.0 for full, 0.5 for half, 0.0 for absent
  double get payMultiplier {
    switch (type) {
      case 'full':
        return 1.0;
      case 'half':
        return 0.5;
      default:
        return 0.0;
    }
  }

  AttendanceModel copyWith({
    int? id,
    int? workerId,
    int? siteId,
    String? date,
    String? type,
  }) =>
      AttendanceModel(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        siteId: siteId ?? this.siteId,
        date: date ?? this.date,
        type: type ?? this.type,
        createdAt: createdAt,
        workerName: workerName,
        siteName: siteName,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'worker_id': workerId,
        'site_id': siteId,
        'date': date,
        'type': type,
        'created_at': createdAt.toIso8601String(),
      };

  factory AttendanceModel.fromMap(Map<String, dynamic> map) => AttendanceModel(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int,
        siteId: map['site_id'] as int,
        date: map['date'] as String,
        type: map['type'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        workerName: map['worker_name'] as String?,
        siteName: map['site_name'] as String?,
      );
}
