import '../../models/notification_model.dart';

/// The eight payment-reminder windows requested for Phase 2. Each window is a
/// distinct logical reminder so the history-based dedupe (keyed by a stable id
/// that includes the window) guarantees the same reminder is never sent twice.
enum PaymentReminderWindow {
  days7Before,
  days3Before,
  days1Before,
  dueToday,
  days1Overdue,
  days3Overdue,
  days7Overdue,
  days30Overdue,
}

/// Returns the [PaymentReminderWindow] that applies when [now] is compared to
/// [dueDate], or null if no window matches (so no reminder is emitted that day).
///
/// [dueDate] semantics:
///  - Customer collections: derived as `lastPaidDate + collectionReminderDays`.
///  - Construction payments: the scheduled `paymentDate` (future = scheduled).
PaymentReminderWindow? windowForDueDate(DateTime dueDate, DateTime now) {
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final days = due.difference(today).inDays;
  switch (days) {
    case 7:
      return PaymentReminderWindow.days7Before;
    case 3:
      return PaymentReminderWindow.days3Before;
    case 1:
      return PaymentReminderWindow.days1Before;
    case 0:
      return PaymentReminderWindow.dueToday;
    case -1:
      return PaymentReminderWindow.days1Overdue;
    case -3:
      return PaymentReminderWindow.days3Overdue;
    case -7:
      return PaymentReminderWindow.days7Overdue;
    case -30:
      return PaymentReminderWindow.days30Overdue;
    default:
      return null;
  }
}

/// Human-readable label for a window, used to build notification titles/bodies.
String windowLabel(PaymentReminderWindow w) {
  switch (w) {
    case PaymentReminderWindow.days7Before:
      return 'due in 7 days';
    case PaymentReminderWindow.days3Before:
      return 'due in 3 days';
    case PaymentReminderWindow.days1Before:
      return 'due tomorrow';
    case PaymentReminderWindow.dueToday:
      return 'due today';
    case PaymentReminderWindow.days1Overdue:
      return '1 day overdue';
    case PaymentReminderWindow.days3Overdue:
      return '3 days overdue';
    case PaymentReminderWindow.days7Overdue:
      return '7 days overdue';
    case PaymentReminderWindow.days30Overdue:
      return '30 days overdue';
  }
}

/// Priority escalates as a payment becomes more overdue.
NotificationPriority priorityForWindow(PaymentReminderWindow w) {
  switch (w) {
    case PaymentReminderWindow.days7Before:
    case PaymentReminderWindow.days3Before:
    case PaymentReminderWindow.days1Before:
      return NotificationPriority.normal;
    case PaymentReminderWindow.dueToday:
    case PaymentReminderWindow.days1Overdue:
    case PaymentReminderWindow.days3Overdue:
    case PaymentReminderWindow.days7Overdue:
      return NotificationPriority.high;
    case PaymentReminderWindow.days30Overdue:
      return NotificationPriority.critical;
  }
}

bool isOverdueWindow(PaymentReminderWindow w) =>
    w == PaymentReminderWindow.days1Overdue ||
    w == PaymentReminderWindow.days3Overdue ||
    w == PaymentReminderWindow.days7Overdue ||
    w == PaymentReminderWindow.days30Overdue;
