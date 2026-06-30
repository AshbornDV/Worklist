class ProductModel {
  final int? id;
  final int siteId;
  final String name;
  final double quantity;
  final String unit;
  final DateTime? deliveryDate;
  final DateTime createdAt;

  const ProductModel({
    this.id,
    required this.siteId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.deliveryDate,
    required this.createdAt,
  });

  ProductModel copyWith({
    int? id,
    int? siteId,
    String? name,
    double? quantity,
    String? unit,
    DateTime? deliveryDate,
  }) =>
      ProductModel(
        id: id ?? this.id,
        siteId: siteId ?? this.siteId,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        deliveryDate: deliveryDate ?? this.deliveryDate,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'site_id': siteId,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'delivery_date': deliveryDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ProductModel.fromMap(Map<String, dynamic> map) => ProductModel(
        id: map['id'] as int?,
        siteId: map['site_id'] as int,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String,
        deliveryDate: map['delivery_date'] != null
            ? DateTime.parse(map['delivery_date'] as String)
            : null,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
