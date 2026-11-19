class AppConstants {
  AppConstants._();

  static const String appName = 'Worklist';
  static const String appVersion = '1.0.0';

  // Site sizes (collection reminder timing)
  static const String siteSizeSmall = 'small';
  static const String siteSizeLarge = 'large';

  static const List<String> siteSizes = [siteSizeSmall, siteSizeLarge];

  static const int smallSiteReminderDays = 2;
  static const int largeSiteReminderDays = 4;
  static const String siteStatusActive = 'active';
  static const String siteStatusCompleted = 'completed';
  static const String siteStatusPending = 'pending';
  static const String siteStatusOnHold = 'on_hold';

  static const List<String> siteStatuses = [
    siteStatusActive,
    siteStatusPending,
    siteStatusOnHold,
    siteStatusCompleted,
  ];

  // Worker statuses
  static const String workerStatusActive = 'active';
  static const String workerStatusInactive = 'inactive';

  // Attendance types
  static const String attendanceFull = 'full';
  static const String attendanceHalf = 'half';
  static const String attendanceAbsent = 'absent';

  // Advance payment statuses
  static const String advancePending = 'pending';
  static const String advanceApproved = 'approved';
  static const String advanceRejected = 'rejected';

  // Worker trades
  static const List<String> trades = [
    'Mason',
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'Welder',
    'Steel Fixer',
    'Laborer',
    'Supervisor',
    'Engineer',
    'Driver',
    'Operator',
    'Other',
  ];

  // Product units
  static const List<String> productUnits = [
    'kg',
    'tons',
    'bags',
    'units',
    'meters',
    'sq.ft',
    'sq.m',
    'liters',
    'cubic ft',
    'cubic m',
    'pieces',
    'rolls',
    'sheets',
  ];

  // Currency symbol
  static const String currencySymbol = 'Rs.';
}
