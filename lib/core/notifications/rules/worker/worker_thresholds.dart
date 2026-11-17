/// Configurable global thresholds for Phase 5 worker rules.
///
/// Per-worker values (join date, documents, performance, advances) come from the
/// existing models. This holder carries the global thresholds that have no
/// per-worker field yet (document validity, absence/performance cutoffs,
/// unpaid-salary duration, advance limit). All values are overridable — no
/// schema change.
class WorkerThresholds {
  const WorkerThresholds({
    this.documentValidityMonths = const {
      'citizenship': 120,
      'passport': 60,
      'driving_license': 60,
      'contract': 12,
    },
    this.consecutiveAbsenceLimit = 3,
    this.performanceRatingWarning = 2.0,
    this.performanceAttendanceWarning = 70.0,
    this.longUnpaidMonths = 2,
    this.advanceMonthlyLimit = 3,
    this.anniversaryReminderDays = 0,
  });

  /// Months each document type stays valid after [uploadedAt].
  final Map<String, int> documentValidityMonths;

  /// Number of consecutive 'absent' days that triggers a warning.
  final int consecutiveAbsenceLimit;

  /// Ratings at/below this value raise a performance warning.
  final double performanceRatingWarning;

  /// Attendance percentage at/below this value raises a performance warning.
  final double performanceAttendanceWarning;

  /// A salary unpaid for this many months is flagged as "long unpaid".
  final int longUnpaidMonths;

  /// Maximum approved advances allowed per worker per month.
  final int advanceMonthlyLimit;

  /// Days before a work anniversary to start reminding (0 = on the day).
  final int anniversaryReminderDays;
}
