class WorkerModel {
  final int? id;
  final String name;
  final String phone;
  final String trade;
  final double dailyRate;
  final double overtimeRate;
  final String status;
  final DateTime createdAt;
  final String? photoPath;
  final String? address;
  final String? skills;
  final DateTime? joinDate;
  final String? notes;

  const WorkerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.trade,
    required this.dailyRate,
    this.overtimeRate = 0.0,
    this.status = 'active',
    required this.createdAt,
    this.photoPath,
    this.address,
    this.skills,
    this.joinDate,
    this.notes,
  });

  double get halfDayRate => dailyRate / 2;

  WorkerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? trade,
    double? dailyRate,
    double? overtimeRate,
    String? status,
    String? photoPath,
    String? address,
    String? skills,
    DateTime? joinDate,
    String? notes,
  }) =>
      WorkerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        trade: trade ?? this.trade,
        dailyRate: dailyRate ?? this.dailyRate,
        overtimeRate: overtimeRate ?? this.overtimeRate,
        status: status ?? this.status,
        createdAt: createdAt,
        photoPath: photoPath ?? this.photoPath,
        address: address ?? this.address,
        skills: skills ?? this.skills,
        joinDate: joinDate ?? this.joinDate,
        notes: notes ?? this.notes,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'trade': trade,
        'daily_rate': dailyRate,
        'overtime_rate': overtimeRate,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        if (photoPath != null) 'photo_path': photoPath,
        if (address != null) 'address': address,
        if (skills != null) 'skills': skills,
        if (joinDate != null) 'join_date': joinDate!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  factory WorkerModel.fromMap(Map<String, dynamic> map) => WorkerModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        trade: map['trade'] as String,
        dailyRate: (map['daily_rate'] as num).toDouble(),
        overtimeRate: (map['overtime_rate'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'active',
        createdAt: DateTime.parse(map['created_at'] as String),
        photoPath: map['photo_path'] as String?,
        address: map['address'] as String?,
        skills: map['skills'] as String?,
        joinDate: map['join_date'] != null
            ? DateTime.parse(map['join_date'] as String)
            : null,
        notes: map['notes'] as String?,
      );
}
