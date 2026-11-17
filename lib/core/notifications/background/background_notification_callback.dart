import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../platform/platform_notification_service_factory.dart';
import '../analytics/notification_metrics.dart';
import 'notification_engine_factory.dart';

/// Stable unique name for the periodic work. WorkManager persists it across
/// reboots, and re-using the same name with [ExistingPeriodicWorkPolicy.update]
/// means re-enqueuing (on every app launch / boot) never creates a duplicate
/// job — satisfying "do not duplicate scheduled jobs".
const String kNotificationWorkUniqueName = 'worklist.notifications.periodic';

/// Task name string reported to the [BackgroundTaskHandler]. Must match the
/// name we pass to [Workmanager().registerPeriodicTask].
const String kNotificationTaskName = 'worklist.notifications';

/// Top-level background entry point registered with WorkManager. It runs in a
/// separate Dart isolate (app may be closed/minimized). It does NOT depend on
/// the UI; it rebuilds a fresh engine + rules and runs one `refresh()` pass.
///
/// Returns `true` so WorkManager does not needlessly retry; dedupe in the
/// engine already prevents duplicate delivery, so a retry would be a no-op.
@pragma('vm:entry-point')
void notificationBackgroundCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName == kNotificationTaskName) {
      try {
        await PlatformNotificationServiceFactory.instance.initialize();
        final engine = await buildEngineWithAllRules();
        await engine.refresh();
        NotificationMetrics.instance.recordBackgroundExecution(DateTime.now());
      } catch (e) {
        // A background failure must not crash the worker. The next periodic run
        // retries; dedupe prevents duplicate delivery.
        debugPrint('[Workmanager] notification refresh failed: $e');
        NotificationMetrics.instance.record(NotificationEventType.failed);
      }
    }
    return Future.value(true);
  });
}

/// Initializes WorkManager and enqueues the periodic notification task exactly
/// once. Because we use a unique name with [ExistingPeriodicWorkPolicy.update],
/// calling this repeatedly (every launch, after reboot) is idempotent — no
/// duplicate jobs are ever created.
Future<void> initializeBackgroundScheduling() async {
  await Workmanager().initialize(
    notificationBackgroundCallbackDispatcher,
  );

  // 15-minute floor is enforced by Android's WorkManager; we request the
  // minimum so reminders stay reasonably fresh without breaching the OS limit.
  await Workmanager().registerPeriodicTask(
    kNotificationWorkUniqueName,
    kNotificationTaskName,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );

  // Phase 10: record that the periodic scheduler is registered (idempotent
  // across launches — record once per process to avoid inflating the counter).
  NotificationMetrics.instance.ensureLoaded();
  NotificationMetrics.instance.markSchedulerRegistered();
  NotificationMetrics.instance.record(NotificationEventType.scheduled);
}
