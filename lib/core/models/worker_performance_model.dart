class WorkerPerformance {
  final int? id;
  final int workerId;
  final DateTime month; // First day of the month
  final double attendancePercentage;
  final int lateArrivals;
  final int completedWorkDays;
  final double rating; // 1.0 to 5.0
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkerPerformance({
    this.id,
    required this.workerId,
    required this.month,
    required this.attendancePercentage,
    required this.lateArrivals,
    required this.completedWorkDays,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkerPerformance copyWith({
    int? id,
    int? workerId,
    DateTime? month,
    double? attendancePercentage,
    int? lateArrivals,
    int? completedWorkDays,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WorkerPerformance(
        id: id ?? this.id,
        workerId: workerId ?? this.workerId,
        month: month ?? this.month,
        attendancePercentage: attendancePercentage ?? this.attendancePercentage,
        lateArrivals: lateArrivals ?? this.lateArrivals,
        completedWorkDays: completedWorkDays ?? this.completedWorkDays,
        rating: rating ?? this.rating,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'worker_id': workerId,
        'month': month.toIso8601String(),
        'attendance_percentage': attendancePercentage,
        'late_arrivals': lateArrivals,
        'completed_work_days': completedWorkDays,
        'rating': rating,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory WorkerPerformance.fromMap(Map<String, dynamic> map) => WorkerPerformance(
        id: map['id'] as int?,
        workerId: map['worker_id'] as int,
        month: DateTime.parse(map['month'] as String),
        attendancePercentage: (map['attendance_percentage'] as num).toDouble(),
        lateArrivals: map['late_arrivals'] as int,
        completedWorkDays: map['completed_work_days'] as int,
        rating: (map['rating'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  String get monthLabel {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  String get ratingStars {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return '★' * fullStars + (hasHalfStar ? '½' : '') + '☆' * emptyStars;
  }
}
