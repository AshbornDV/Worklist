import '../constants/app_constants.dart';

class SiteModel {
  final int? id;
  final String name;
  final String area;
  final String? googleMapsUrl;
  final double? latitude;
  final double? longitude;
  final String? workType;
  final String? workArea;
  final String? workAreaUnit;
  final double? workTypeRate;
  final double? finalCost;
  final double rate;
  final String status;
  final double estimatedCost;
  final double advanceReceived;
  final double constructionPaid;
  final String siteSize;
  final DateTime? lastPaidDate;
  final String? notes;
  final double? budget;
  final String? manager;
  final DateTime? startDate;
  final DateTime? endDate;
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
    this.workAreaUnit,
    this.workTypeRate,
    this.finalCost,
    this.rate = 0.0,
    this.status = 'active',
    this.estimatedCost = 0.0,
    this.advanceReceived = 0.0,
    this.constructionPaid = 0.0,
    this.siteSize = AppConstants.siteSizeSmall,
    this.lastPaidDate,
    this.notes,
    this.budget,
    this.manager,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalCost => finalCost ?? estimatedCost;
  double get totalReceived => advanceReceived + constructionPaid;
  double get balance => totalCost - totalReceived;
  bool get isPaid => balance <= 0;
  bool get hasRemainingPayment => balance > 0;
  double get completionPercentage => totalCost > 0
      ? (totalReceived / totalCost * 100).clamp(0.0, 100.0)
      : 0.0;

  int get collectionReminderDays => siteSize == AppConstants.siteSizeLarge
      ? AppConstants.largeSiteReminderDays
      : AppConstants.smallSiteReminderDays;

  int get daysSinceLastPayment {
    final anchor = lastPaidDate ?? createdAt;
    final today = DateTime.now();
    final anchorDay = DateTime(anchor.year, anchor.month, anchor.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    return todayDay.difference(anchorDay).inDays;
  }

  bool get isCollectionDue =>
      hasRemainingPayment && daysSinceLastPayment >= collectionReminderDays;

  SiteModel copyWith({
    int? id,
    String? name,
    String? area,
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    String? workType,
    String? workArea,
    String? workAreaUnit,
    double? workTypeRate,
    double? finalCost,
    double? rate,
    String? status,
    double? estimatedCost,
    double? advanceReceived,
    double? constructionPaid,
    String? siteSize,
    DateTime? lastPaidDate,
    String? notes,
    double? budget,
    String? manager,
    DateTime? startDate,
    DateTime? endDate,
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
        workAreaUnit: workAreaUnit ?? this.workAreaUnit,
        workTypeRate: workTypeRate ?? this.workTypeRate,
        finalCost: finalCost ?? this.finalCost,
        rate: rate ?? this.rate,
        status: status ?? this.status,
        estimatedCost: estimatedCost ?? this.estimatedCost,
        advanceReceived: advanceReceived ?? this.advanceReceived,
        constructionPaid: constructionPaid ?? this.constructionPaid,
        siteSize: siteSize ?? this.siteSize,
        lastPaidDate: lastPaidDate ?? this.lastPaidDate,
        notes: notes ?? this.notes,
        budget: budget ?? this.budget,
        manager: manager ?? this.manager,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
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
        'work_area_unit': workAreaUnit,
        'work_type_rate': workTypeRate,
        'final_cost': finalCost,
        'rate': rate,
        'status': status,
        'estimated_cost': estimatedCost,
        'advance_received': advanceReceived,
        'construction_paid': constructionPaid,
        'site_size': siteSize,
        'last_paid_date': lastPaidDate?.toIso8601String(),
        'notes': notes,
        if (budget != null) 'budget': budget,
        if (manager != null) 'manager': manager,
        if (startDate != null) 'start_date': startDate!.toIso8601String(),
        if (endDate != null) 'end_date': endDate!.toIso8601String(),
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
        workAreaUnit: map['work_area_unit'] as String?,
        workTypeRate: (map['work_type_rate'] as num?)?.toDouble(),
        finalCost: (map['final_cost'] as num?)?.toDouble(),
        rate: (map['rate'] as num?)?.toDouble() ?? 0.0,
        status: map['status'] as String? ?? 'active',
        estimatedCost: (map['estimated_cost'] as num?)?.toDouble() ?? 0.0,
        advanceReceived: (map['advance_received'] as num?)?.toDouble() ?? 0.0,
        constructionPaid: (map['construction_paid'] as num?)?.toDouble() ?? 0.0,
        siteSize: map['site_size'] as String? ?? AppConstants.siteSizeSmall,
        lastPaidDate: map['last_paid_date'] == null
            ? null
            : DateTime.parse(map['last_paid_date'] as String),
        notes: map['notes'] as String?,
        budget: (map['budget'] as num?)?.toDouble(),
        manager: map['manager'] as String?,
        startDate: map['start_date'] == null
            ? null
            : DateTime.parse(map['start_date'] as String),
        endDate: map['end_date'] == null
            ? null
            : DateTime.parse(map['end_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
