class StoreProduct {
  final int? id;
  final String name;
  final String? category;
  final String? subcategory;
  /// Optional label for UI (stored as string). Examples: "Red", "#FF0000".
  final String? colorLabel;
  /// Optional barcode string for search/scan.
  final String? barcode;
  final double rate;
  final double size;
  final String unit;
  final double stock;
  final double lowStockThreshold;
  final double criticalStockThreshold;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StoreProduct({
    this.id,
    required this.name,
    this.category,
    this.subcategory,
    this.colorLabel,
    this.barcode,
    required this.rate,
    this.size = 1.0,
    this.unit = 'piece',
    this.stock = 0.0,
    this.lowStockThreshold = 10.0,
    this.criticalStockThreshold = 2.0,
    required this.createdAt,
    required this.updatedAt,
  });

  StoreProduct copyWith({
    int? id,
    String? name,
    String? category,
    String? subcategory,
    String? colorLabel,
    String? barcode,
    double? rate,
    double? size,
    String? unit,
    double? stock,
    double? lowStockThreshold,
    double? criticalStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      StoreProduct(
        id: id ?? this.id,
        name: name ?? this.name,
        category: category ?? this.category,
        subcategory: subcategory ?? this.subcategory,
        colorLabel: colorLabel ?? this.colorLabel,
        barcode: barcode ?? this.barcode,
        rate: rate ?? this.rate,
        size: size ?? this.size,
        unit: unit ?? this.unit,
        stock: stock ?? this.stock,
        lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
        criticalStockThreshold:
            criticalStockThreshold ?? this.criticalStockThreshold,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'category': category,
        'subcategory': subcategory,
        'color_label': colorLabel,
        'barcode': barcode,
        'rate': rate,
        'size': size,
        'unit': unit,
        'stock': stock,
        'low_stock_threshold': lowStockThreshold,
        'critical_stock_threshold': criticalStockThreshold,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory StoreProduct.fromMap(Map<String, dynamic> map) => StoreProduct(
        id: map['id'] as int?,
        name: map['name'] as String,
        category: map['category'] as String?,
        subcategory: map['subcategory'] as String?,
        colorLabel: map['color_label'] as String?,
        barcode: map['barcode'] as String?,
        rate: (map['rate'] as num).toDouble(),
        size: (map['size'] as num?)?.toDouble() ?? 1.0,
        unit: (map['unit'] as String?) ?? 'piece',
        stock: (map['stock'] as num?)?.toDouble() ?? 0.0,
        lowStockThreshold:
            (map['low_stock_threshold'] as num?)?.toDouble() ?? 10.0,
        criticalStockThreshold:
            (map['critical_stock_threshold'] as num?)?.toDouble() ?? 2.0,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  double get unitValue => rate * size;

  bool get isOutOfStock => stock <= 0;
  bool get isCriticalStock => stock > 0 && stock <= criticalStockThreshold;
  bool get isLowStock =>
      stock > criticalStockThreshold && stock <= lowStockThreshold;
}
