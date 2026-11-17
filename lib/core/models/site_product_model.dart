class SiteProduct {
  final int? id;
  final int siteId;
  final int productId;
  final double quantity;
  final DateTime createdAt;
  String? productName;
  double? productRate;
  String? productUnit;

  SiteProduct({
    this.id,
    required this.siteId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    this.productName,
    this.productRate,
    this.productUnit,
  });

  SiteProduct copyWith({
    int? id,
    int? siteId,
    int? productId,
    double? quantity,
    DateTime? createdAt,
  }) =>
      SiteProduct(
        id: id ?? this.id,
        siteId: siteId ?? this.siteId,
        productId: productId ?? this.productId,
        quantity: quantity ?? this.quantity,
        createdAt: createdAt ?? this.createdAt,
        productName: productName,
        productRate: productRate,
        productUnit: productUnit,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'site_id': siteId,
        'product_id': productId,
        'quantity': quantity,
        'created_at': createdAt.toIso8601String(),
      };

  factory SiteProduct.fromMap(Map<String, dynamic> map) => SiteProduct(
        id: map['id'] as int?,
        siteId: map['site_id'] as int,
        productId: map['product_id'] as int,
        quantity: (map['quantity'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        productName: map['product_name'] as String?,
        productRate: (map['product_rate'] as num?)?.toDouble(),
        productUnit: map['product_unit'] as String?,
      );

  double get totalCost => quantity * (productRate ?? 0);
}
