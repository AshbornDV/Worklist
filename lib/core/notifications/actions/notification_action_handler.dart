import 'dart:async';

import '../models/notification_action.dart';
import '../models/notification_model.dart';
import '../platform/platform_notification_service.dart';
import '../repositories/notification_history_repository.dart';
import '../analytics/notification_metrics.dart';

/// Abstraction over app navigation so the notification module stays decoupled
/// from go_router. The app wires a concrete implementation at startup.
abstract class NotificationRouter {
  /// Navigate to an in-app [route] (e.g. `/sites/42`).
  Future<void> navigate(String route);

  /// Open an external URL (e.g. a `tel:` link).
  Future<void> openExternal(String url);
}

/// Resolves the deep-link route for a notification's entity, mirroring the
/// mapping used by the Notification Center so OS-tap and in-app-tap behave
/// identically.
String? deepLinkRouteFor(NotificationModel n) {
  switch (n.entityType) {
    case 'site':
      return n.entityId != null ? '/sites/${n.entityId}' : null;
    case 'worker':
      return n.entityId != null ? '/workers/${n.entityId}' : null;
    case 'store_product':
      return '/products';
    case 'service':
      return '/services';
    default:
      return null;
  }
}

/// Routes a chosen [NotificationAction] to its effect:
///  • open/perform actions  → deep link (or external call) via [NotificationRouter]
///  • status actions         → update [NotificationHistoryRepository]
///  • snooze actions         → deferred re-show via the platform service
///
/// This is the single place that gives interactive notifications their
/// behavior. It contains NO business-domain mutation logic — "Mark Paid",
/// "Mark Attendance", etc. deep-link to the screen where the user performs the
/// action, keeping the notification framework independent of payroll/site/worker
/// services.
class NotificationActionHandler {
  NotificationActionHandler({
    required this.history,
    required this.router,
    this.platform,
  });

  final NotificationHistoryRepository history;
  final NotificationRouter router;
  final PlatformNotificationService? platform;

  /// Handles [action] for [notification]. Safe to call from any isolate that
  /// has the repositories ready (the app runtime, not the WorkManager isolate).
  Future<void> handle(
    NotificationModel notification,
    NotificationAction action,
  ) async {
    switch (action.category) {
      // ── Status actions (framework-only) ──
      case NotificationActionCategory.markRead:
        await history.markRead(notification.id);
      case NotificationActionCategory.markUnread:
        await history.markUnread(notification.id);
      case NotificationActionCategory.archive:
        await history.archive(notification.id);
      case NotificationActionCategory.dismiss:
        await history.markDismissed(notification.id);

      // ── Snooze / remind → deferred re-show ──
      case NotificationActionCategory.remindTomorrow:
        await _snooze(notification, const Duration(hours: 24));
      case NotificationActionCategory.snooze1Hour:
        await _snooze(notification, const Duration(hours: 1));
      case NotificationActionCategory.snooze1Day:
        await _snooze(notification, const Duration(days: 1));

      // ── Call worker (external) ──
      case NotificationActionCategory.callWorker:
        final phone = _phoneFromPayload(notification);
        if (phone != null) {
          await router.openExternal('tel:$phone');
        } else if (deepLinkRouteFor(notification) != null) {
          await router.navigate(deepLinkRouteFor(notification)!);
        }

      // ── Open / perform actions → deep link ──
      default:
        final route = _performRoute(notification, action);
        if (route != null) {
          NotificationMetrics.instance.record(NotificationEventType.opened);
          await router.navigate(route);
        }
    }
  }

  /// "Perform" actions deep-link to the screen where the user completes them.
  String? _performRoute(NotificationModel n, NotificationAction action) {
    switch (action.category) {
      case NotificationActionCategory.markPaid:
      case NotificationActionCategory.openPayment:
      case NotificationActionCategory.openSite:
      case NotificationActionCategory.updateProgress:
      case NotificationActionCategory.addPayment:
      case NotificationActionCategory.addMaterial:
        return n.entityType == 'site' && n.entityId != null
            ? '/sites/${n.entityId}'
            : '/sites';
      case NotificationActionCategory.openWorker:
      case NotificationActionCategory.markAttendance:
      case NotificationActionCategory.viewDocuments:
        return n.entityType == 'worker' && n.entityId != null
            ? '/workers/${n.entityId}'
            : '/workers';
      case NotificationActionCategory.openInventory:
      case NotificationActionCategory.purchaseMaterial:
      case NotificationActionCategory.markRestocked:
        return '/products';
      case NotificationActionCategory.openService:
      case NotificationActionCategory.markCompleted:
        return '/services';
      case NotificationActionCategory.open:
      default:
        return deepLinkRouteFor(n) ?? '/notifications';
    }
  }

  Future<void> _snooze(NotificationModel n, Duration delay) async {
    // Cancel the live notification; re-show after the delay. The engine's
    // dedupe key is unchanged, so the re-show is not treated as a duplicate.
    // If the platform/router is unavailable (background isolate), we simply
    // let the next refresh cycle re-emit when the condition still holds.
    // The snooze *state* is also persisted so it synchronizes across devices.
    await history.markSnoozed(n.id, at: DateTime.now().add(delay));
    platform?.cancel(n.platformId);
    if (platform == null) return;
    await Future<void>.delayed(delay);
    await platform!.show(n.copyWith(actions: n.actions));
  }

  String? _phoneFromPayload(NotificationModel n) {
    final phone = n.payload?['phone'] as String?;
    return phone?.isNotEmpty == true ? phone : null;
  }
}

/// Reconstructs a [NotificationModel] from a history record so the response
/// handler can route an action even when the in-memory shown-map is empty
/// (e.g. the app was launched from a killed state by tapping the notification).
NotificationModel? notificationFromRecord(
  NotificationRecord record, {
  List<NotificationAction>? actions,
}) =>
    NotificationModel(
      id: record.id,
      title: record.title ?? '',
      body: record.body ?? '',
      type: record.type,
      priority: record.priority ?? NotificationPriority.normal,
      createdAt: record.createdAt,
      entityId: record.entityId,
      entityType: record.entityType,
      actions: actions,
    );
