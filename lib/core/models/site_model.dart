class SiteModel {
  final int? id;
  final String name;
  final String area;
  final String? googleMapsUrl;
  final double? latitude;
  final double? longitude;
  final String? workType;
  final String? workArea;
  final double rate;
  final String status;
  final double estimatedCost;
  final double advanceReceived;
  final DateTime? lastPaidDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SiteModel({
    this.id,
    required this.name,
    required this.area,
    this.googleMapsUrl,
    this.latitude,
    this.longitude,
    this.workType,
    this.workArea,
    this.rate = 0.0,
    this.status = 'active',
    this.estimatedCost = 0.0,
    this.advanceReceived = 0.0,
    this.lastPaidDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get balance => estimatedCost - advanceReceived;
  bool get isPaid => balance <= 0;
  bool get hasRemainingPayment => balance > 0;
  double get completionPercentage => estimatedCost > 0
      ? (advanceReceived / estimatedCost * 100).clamp(0.0, 100.0)
      : 0.0;

  SiteModel copyWith({
    int? id,
    String? name,
    String? area,
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    String? workType,
    String? workArea,
    double? rate,
    String? status,
    double? estimatedCost,
    double? advanceReceived,
    DateTime? lastPaidDate,
    String? notes,
    DateTime? updatedAt,
  }) =>
      SiteModel(
        id: id ?? this.id,
        name: name ?? this.name,
        area: area ?? this.area,
        googleMapsUrl: googleMapsUrl ?? this.googleMapsUrl,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        workType: workType ?? this.workType,
        workArea: workArea ?? this.workArea,
        rate: rate ?? this.rate,
        status: status ?? this.status,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        advanceReceived: advanceReceived ?? this.advanceReceived,
        lastPaidDate: lastPaidDate ?? this.lastPaidDate,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'area': area,
        'google_maps_url': googleMapsUrl,
        'latitude': latitude,
        'longitude': longitude,
        'work_type': workType,
        'work_area': workArea,
        'rate': rate,
        'status': status,
        'estimated_cost': estimatedCost,
        'advance_received': advanceReceived,
        'last_paid_date': lastPaidDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory SiteModel.fromMap(Map<String, dynamic> map) => SiteModel(
        id: map['id'] as int?,
        name: map['name'] as String,
        area: map['area'] as String,
        googleMapsUrl: map['google_maps_url'] as String?,
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        workType: map['work_type'] as String?,
        workArea: map['work_area'] as String?,
        rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'active',
        estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? 0.0,
        advanceReceived: (map['advance_received'] as num?)?.toDouble() ?? 0.0,
        lastPaidDate: map['last_paid_date'] == null
            ? null
            : DateTime.parse(map['last_paid_date'] as String),
        notes: map['notes'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
