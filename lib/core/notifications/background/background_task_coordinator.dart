import '../core/notification_logger.dart';
import '../engine/notification_engine.dart';

/// Prepares and coordinates background execution of the notification pipeline.
///
/// Phase 1 ONLY lays the foundation: it defines the contract for registering a
/// callback that evaluates + delivers notifications while the app may be
/// backgrounded, and it selects the correct platform strategy. It does NOT
/// enqueue any WorkManager task or start a timer yet — that happens in a later
/// phase once concrete rules exist and exact/periodic scheduling is needed.
///
/// Design: the coordinator is given a [NotificationEngine] and exposes
/// `runInBackground()` which rules can eventually trigger. On Android this is
/// where `workmanager` would be wired to dispatch a `OneTimeWorkRequest` that
/// calls `engine.refresh()`; on Windows, a scheduled-task abstraction would
/// live here. Keeping it isolated means enabling background delivery later
/// requires no engine changes.
class BackgroundTaskCoordinator {
  BackgroundTaskCoordinator(this.engine);

  final NotificationEngine engine;

  bool _prepared = false;

  /// Idempotently prepares the platform background channel. In Phase 1 this
  /// simply logs intent and flips [_prepared]; concrete WorkManager/Windows
  /// scheduling is deferred to the background-execution phase.
  Future<void> prepare() async {
    if (_prepared) return;
    try {
      await engine.refresh();
    } catch (e) {
      NotificationLogger.instance.warning('Background warm-up refresh failed: $e');
    }
    _prepared = true;
    NotificationLogger.instance
        .info('BackgroundTaskCoordinator prepared (no active dispatch in Phase 1)');
  }

  /// Runs one evaluation+delivery pass. Wired here (not in the engine) so the
  /// background entry point and the foreground entry point share one path.
  /// Safe to call from a worked task, app resume, or a periodic timer.
  Future<void> runInBackground() async {
    try {
      await engine.refresh();
    } catch (e, s) {
      NotificationLogger.instance.error('Background run failed', e, s);
    }
  }

  /// Tears down any active background registration. No-op until dispatch is
  /// implemented in a later phase, but present so lifecycle code is complete.
  Future<void> dispose() async {
    _prepared = false;
    NotificationLogger.instance.info('BackgroundTaskCoordinator disposed');
  }
}
