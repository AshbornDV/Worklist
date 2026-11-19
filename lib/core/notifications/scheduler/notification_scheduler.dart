import '../models/notification_model.dart';
import '../platform/platform_notification_service.dart';

/// Responsible for deciding WHEN a notification becomes visible and handing it
/// to the [PlatformNotificationService]. Phase 1 supports only immediate
/// delivery (`showNow`). Exact-time and recurring delivery, as well as
/// background execution via Android WorkManager, are scaffolded here but not
/// yet activated by any rule.
///
/// The scheduler is intentionally decoupled from the engine: the engine passes
/// already-evaluated, deduped, settings-filtered candidates; the scheduler
/// only concerns itself with timing + delivery.
class NotificationScheduler {
  NotificationScheduler(this.platform);

  final PlatformNotificationService platform;

  /// Delivers [notification] immediately. This is the only active path in
  /// Phase 1. Returns whether delivery succeeded.
  Future<bool> showNow(NotificationModel notification) =>
      platform.show(notification);

  /// Prepares the framework for background execution.
  ///
  /// On Android this is where a WorkManager `OneTimeWorkRequest`/`PeriodicWorkRequest`
  /// would be enqueued to evaluate rules even when the UI is closed. On Windows
  /// this is a placeholder for a background task / scheduled task abstraction.
  ///
  /// NOT triggered automatically in Phase 1 — defined so future phases can call
  /// `prepareBackground()` without changing the engine contract.
  Future<void> prepareBackground() async {
    // Intentionally a no-op in Phase 1. Concrete WorkManager wiring (and the
    // `workmanager` package dependency) is deferred to the background-execution
    // phase so this framework ships without changing build/runtime surface.
    return;
  }
}
