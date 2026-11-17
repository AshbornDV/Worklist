class SiteService {
  final int? id;
  final int siteId;
  final String serviceName;
  final double rate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SiteService({
    this.id,
    required this.siteId,
    required this.serviceName,
    required this.rate,
    required this.createdAt,
    required this.updatedAt,
  });

  SiteService copyWith({
    int? id,
    int? siteId,
    String? serviceName,
    double? rate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      SiteService(
        id: id ?? this.id,
        siteId: siteId ?? this.siteId,
        serviceName: serviceName ?? this.serviceName,
        rate: rate ?? this.rate,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'site_id': siteId,
        'service_name': serviceName,
        'rate': rate,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SiteService.fromMap(Map<String, dynamic> map) => SiteService(
        id: map['id'] as int?,
        siteId: map['site_id'] as int,
        serviceName: map['service_name'] as String,
        rate: (map['rate'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
