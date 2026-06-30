class WorkerModel {
  final int? id;
  final String name;
  final String phone;
  final String trade;
  final double dailyRate;
  final String status;
  final DateTime createdAt;

  const WorkerModel({
    this.id,
    required this.name,
    required this.phone,
    required this.trade,
    required this.dailyRate,
    this.status = 'active',
    required this.createdAt,
  });

  double get halfDayRate => dailyRate / 2;

  WorkerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? trade,
    double? dailyRate,
    String? status,
  }) =>
      WorkerModel(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        trade: trade ?? this.trade,
        dailyRate: dailyRate ?? this.dailyRate,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'trade': trade,
        'daily_rate': dailyRate,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory WorkerModel.fromMap(Map<String, dynamic> map) => WorkerModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        trade: map['trade'] as String,
        dailyRate: (map['daily_rate'] as num).toDouble(),
        status: map['status'] as String? ?? 'active',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
