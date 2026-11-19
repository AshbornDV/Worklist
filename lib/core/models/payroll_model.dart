class PayrollModel {
  final int? id;
  final int workerId;
  final DateTime month; // First day of the month

  // Attendance-derived
  final int fullDays;
  final int halfDays;

  // Rates snapshot (captured at generation time)
  final double dailyRate;
  final double overtimeHours;
  final double overtimeRate;

  // Adjustments
  final double advanceAmount; // Approved advances for the month
  final double bonus;
  final double deductions;

  // Final computed amount (persisted so edits don't drift)
  final double netSalary;
  final String status; // 'draft', 'paid'

  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Optional denormalized fields from joins
  final String? workerName;
  final String? trade;

  const PayrollModel({
    this.id,
    required this.workerId,
    required this.month,
    required this.fullDays,
    required this.halfDays,
    required this.dailyRate,
    required this.overtimeHours,
    required this.overtimeRate,
    required this.advanceAmount,
    required this.bonus,
    required this.deductions,
    required this.netSalary,
    this.status = 'draft',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.workerName,
    this.trade,
  });

  bool get isPaid => status == 'paid';
  bool get isDraft => status == 'draft';

  /// Earnings from attendance: full days + half days.
  double get baseWage => (fullDays * dailyRate) + (halfDays * (dailyRate / 2));

  /// Total overtime pay.
  double get overtimePay => overtimeHours * overtimeRate;

  /// Earnings before adjustments.
  double get grossSalary => baseWage + overtimePay + bonus;

  int get totalDaysWorked => fullDays + halfDays;

  PayrollModel copyWith({
    int? id,
    int? workerId,
    DateTime? month,
    int? fullDays,
    int? halfDays,
    double? dailyRate,
    double? overtimeHours,
    double? overtimeRate,
    double? advanceAmount,
    double? bonus,
    double? deductions,
    double? netSalary,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PayrollModel(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        month: month ?? this.month,
        fullDays: fullDays ?? this.fullDays,
        halfDays: halfDays ?? this.halfDays,
        dailyRate: dailyRate ?? this.dailyRate,
        overtimeHours: overtimeHours ?? this.overtimeHours,
        overtimeRate: overtimeRate ?? this.overtimeRate,
        advanceAmount: advanceAmount ?? this.advanceAmount,
        bonus: bonus ?? this.bonus,
        deductions: deductions ?? this.deductions,
        netSalary: netSalary ?? this.netSalary,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        workerName: workerName,
        trade: trade,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'worker_id': workerId,
        'month': month.toIso8601String(),
        'full_days': fullDays,
        'half_days': halfDays,
        'daily_rate': dailyRate,
        'overtime_hours': overtimeHours,
        'overtime_rate': overtimeRate,
        'advance_amount': advanceAmount,
        'bonus': bonus,
        'deductions': deductions,
        'net_salary': netSalary,
        'status': status,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory PayrollModel.fromMap(Map<String, dynamic> map) => PayrollModel(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int,
        month: DateTime.parse(map['month'] as String),
        fullDays: (map['full_days'] as num?)?.toInt() ?? 0,
        halfDays: (map['half_days'] as num?)?.toInt() ?? 0,
        dailyRate: (map['daily_rate'] as num?)?.toDouble() ?? 0.0,
        overtimeHours: (map['overtime_hours'] as num?)?.toDouble() ?? 0.0,
        overtimeRate: (map['overtime_rate'] as num?)?.toDouble() ?? 0.0,
        advanceAmount: (map['advance_amount'] as num?)?.toDouble() ?? 0.0,
        bonus: (map['bonus'] as num?)?.toDouble() ?? 0.0,
        deductions: (map['deductions'] as num?)?.toDouble() ?? 0.0,
        netSalary: (map['net_salary'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'draft',
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        workerName: map['worker_name'] as String?,
        trade: map['trade'] as String?,
      );

  String get monthLabel {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }
}
