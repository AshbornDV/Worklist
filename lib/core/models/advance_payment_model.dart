class AdvancePaymentModel {
  final int? id;
  final int workerId;
  final double amount;
  final DateTime requestDate;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime? approvedDate;
  final String? notes;
  final DateTime createdAt;

  // Optional denormalized field from joins
  final String? workerName;

  const AdvancePaymentModel({
    this.id,
    required this.workerId,
    required this.amount,
    required this.requestDate,
    this.status = 'pending',
    this.approvedDate,
    this.notes,
    required this.createdAt,
    this.workerName,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  AdvancePaymentModel copyWith({
    int? id,
    int? workerId,
    double? amount,
    DateTime? requestDate,
    String? status,
    DateTime? approvedDate,
    String? notes,
  }) =>
      AdvancePaymentModel(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        amount: amount ?? this.amount,
        requestDate: requestDate ?? this.requestDate,
        status: status ?? this.status,
        approvedDate: approvedDate ?? this.approvedDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        workerName: workerName,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'worker_id': workerId,
        'amount': amount,
        'request_date': requestDate.toIso8601String(),
        'status': status,
        'approved_date': approvedDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory AdvancePaymentModel.fromMap(Map<String, dynamic> map) =>
      AdvancePaymentModel(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        requestDate: DateTime.parse(map['request_date'] as String),
        status: map['status'] as String? ?? 'pending',
        approvedDate: map['approved_date'] != null
            ? DateTime.parse(map['approved_date'] as String)
            : null,
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        workerName: map['worker_name'] as String?,
      );
}
