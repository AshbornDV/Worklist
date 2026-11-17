/// An interactive notification action (Phase 9). Passive notifications become
/// actionable: the OS (Android) shows action buttons; the framework's response
/// handler routes the chosen action to either a deep link, a status update in
/// the notification history, or a deferred re-show (snooze).
///
/// Actions are pure data — they carry no business logic. The
/// [NotificationActionHandler] decides what each [NotificationActionCategory]
/// means at runtime, so rules and the platform layer stay declarative.
enum NotificationActionCategory {
  // General
  open,
  dismiss,
  archive,
  markRead,
  markUnread,

  // Payment
  markPaid,
  openPayment,
  remindTomorrow,
  snooze1Hour,
  snooze1Day,

  // Worker
  openWorker,
  markAttendance,
  callWorker,
  viewDocuments,

  // Site
  openSite,
  updateProgress,
  addPayment,
  addMaterial,

  // Inventory
  openInventory,
  purchaseMaterial,
  markRestocked,

  // Service
  openService,
  markCompleted,
}

/// A single actionable button attached to a notification.
///
/// [actionId] is the stable string echoed back by the platform's response
/// handler (Android `actionId` / Windows payload), so it must be unique within
/// a notification's action list and stable across launches.
class NotificationAction {
  const NotificationAction({
    required this.category,
    required this.label,
    this.icon,
    this.actionId,
  });

  final NotificationActionCategory category;
  final String label;

  /// Optional material icon name (informational; Android maps a few to native
  /// icons, the rest are text-only buttons).
  final String? icon;

  /// Stable id used by the platform response handler. Defaults to the
  /// category's enum name.
  final String? actionId;

  /// Resolved stable id (never null) used for platform action matching.
  String get resolvedActionId => actionId ?? category.name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationAction &&
          other.category == category &&
          other.label == label;

  @override
  int get hashCode => category.hashCode ^ label.hashCode;

  Map<String, dynamic> toMap() => {
        'category': category.name,
        'label': label,
        if (icon != null) 'icon': icon,
        'actionId': resolvedActionId,
      };

  factory NotificationAction.fromMap(Map<String, dynamic> m) => NotificationAction(
        category: NotificationActionCategory.values.firstWhere(
          (e) => e.name == (m['category'] as String? ?? ''),
          orElse: () => NotificationActionCategory.open,
        ),
        label: m['label'] as String,
        icon: m['icon'] as String?,
        actionId: m['actionId'] as String?,
      );
}
