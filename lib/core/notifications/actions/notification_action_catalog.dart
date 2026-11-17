import '../models/notification_action.dart';
import '../models/notification_model.dart';

/// Maps a [NotificationModel] to the set of interactive actions a user should
/// be able to take directly from the notification (Phase 9).
///
/// The mapping follows the product spec exactly: Payment / Worker / Site /
/// Inventory / Service / General groupings. It is pure (no business logic, no
/// I/O) so it can run on the platform layer while building the OS action
/// buttons, and again in the response handler when an action is chosen.
///
/// Summary/digest notifications (daily/weekly/monthly) get only the General
/// actions because they aggregate many entities and don't point at a single
/// one.
class NotificationActionCatalog {
  const NotificationActionCatalog._();

  static List<NotificationAction> actionsFor(NotificationModel n) {
    // Summary digests: nothing single-entity to act on.
    if (n.type == NotificationType.dailySummary ||
        n.type == NotificationType.weeklySummary ||
        n.type == NotificationType.monthlySummary) {
      return const [
        NotificationAction(
          category: NotificationActionCategory.open,
          label: 'Open',
        ),
        NotificationAction(
          category: NotificationActionCategory.markRead,
          label: 'Mark Read',
        ),
        NotificationAction(
          category: NotificationActionCategory.dismiss,
          label: 'Dismiss',
        ),
      ];
    }

    // Prefer the concrete entity type (more specific); fall back to the
    // notification category.
    final entity = n.entityType;
    if (entity == 'site') return _site;
    if (entity == 'worker') return _worker;
    if (entity == 'store_product') return _inventory;
    if (entity == 'service') return _service;

    switch (n.type) {
      case NotificationType.payment:
      case NotificationType.payroll:
        return _payment;
      case NotificationType.worker:
      case NotificationType.attendance:
        return _worker;
      case NotificationType.inventory:
        return _inventory;
      case NotificationType.site:
        return _site;
      case NotificationType.service:
        return _service;
      case NotificationType.system:
      case NotificationType.generic:
      default:
        return _general;
    }
  }

  static const List<NotificationAction> _general = [
    NotificationAction(
      category: NotificationActionCategory.open,
      label: 'Open',
    ),
    NotificationAction(
      category: NotificationActionCategory.markRead,
      label: 'Mark Read',
    ),
    NotificationAction(
      category: NotificationActionCategory.markUnread,
      label: 'Mark Unread',
    ),
    NotificationAction(
      category: NotificationActionCategory.archive,
      label: 'Archive',
    ),
    NotificationAction(
      category: NotificationActionCategory.dismiss,
      label: 'Dismiss',
    ),
  ];

  static const List<NotificationAction> _payment = [
    NotificationAction(
      category: NotificationActionCategory.markPaid,
      label: 'Mark Paid',
    ),
    NotificationAction(
      category: NotificationActionCategory.openPayment,
      label: 'Open Payment',
    ),
    NotificationAction(
      category: NotificationActionCategory.remindTomorrow,
      label: 'Remind Tomorrow',
    ),
    NotificationAction(
      category: NotificationActionCategory.snooze1Hour,
      label: 'Snooze 1h',
    ),
    NotificationAction(
      category: NotificationActionCategory.snooze1Day,
      label: 'Snooze 1d',
    ),
  ];

  static const List<NotificationAction> _worker = [
    NotificationAction(
      category: NotificationActionCategory.openWorker,
      label: 'Open Worker',
    ),
    NotificationAction(
      category: NotificationActionCategory.markAttendance,
      label: 'Mark Attendance',
    ),
    NotificationAction(
      category: NotificationActionCategory.callWorker,
      label: 'Call Worker',
    ),
    NotificationAction(
      category: NotificationActionCategory.viewDocuments,
      label: 'View Documents',
    ),
  ];

  static const List<NotificationAction> _site = [
    NotificationAction(
      category: NotificationActionCategory.openSite,
      label: 'Open Site',
    ),
    NotificationAction(
      category: NotificationActionCategory.updateProgress,
      label: 'Update Progress',
    ),
    NotificationAction(
      category: NotificationActionCategory.addPayment,
      label: 'Add Payment',
    ),
    NotificationAction(
      category: NotificationActionCategory.addMaterial,
      label: 'Add Material',
    ),
  ];

  static const List<NotificationAction> _inventory = [
    NotificationAction(
      category: NotificationActionCategory.openInventory,
      label: 'Open Inventory',
    ),
    NotificationAction(
      category: NotificationActionCategory.purchaseMaterial,
      label: 'Purchase Material',
    ),
    NotificationAction(
      category: NotificationActionCategory.markRestocked,
      label: 'Mark Restocked',
    ),
  ];

  static const List<NotificationAction> _service = [
    NotificationAction(
      category: NotificationActionCategory.openService,
      label: 'Open Service',
    ),
    NotificationAction(
      category: NotificationActionCategory.markCompleted,
      label: 'Mark Completed',
    ),
  ];
}
