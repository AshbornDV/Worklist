class ConstructionPaymentModel {
  final int? id;
  final int siteId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConstructionPaymentModel({
    this.id,
    required this.siteId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  ConstructionPaymentModel copyWith({
    int? id,
    int? siteId,
    double? amount,
    DateTime? paymentDate,
    String? notes,
    DateTime? updatedAt,
  }) =>
      ConstructionPaymentModel(
        id: id ?? this.id,
        siteId: siteId ?? this.siteId,
        amount: amount ?? this.amount,
        paymentDate: paymentDate ?? this.paymentDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'site_id': siteId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory ConstructionPaymentModel.fromMap(Map<String, dynamic> map) =>
      ConstructionPaymentModel(
        id: map['id'] as int?,
        siteId: map['site_id'] as int,
        amount: (map['amount'] as num).toDouble(),
        paymentDate: DateTime.parse(map['payment_date'] as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
