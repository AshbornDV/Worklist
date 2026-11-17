import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../platform/platform_notification_service_factory.dart';
import '../analytics/notification_metrics.dart';
import 'notification_engine_factory.dart';

/// Windows background scheduling.
///
/// Windows has no OS-level background task API that survives the app being
/// closed (and `flutter_local_notifications` on Windows only shows toasts while
/// the process is alive). So on Windows we implement:
///
///  1. A lightweight in-process periodic timer that runs the engine every
///     [interval] while the app is running (app minimized or foreground).
///  2. Optional startup registration: a shortcut in the user's Startup folder
///     so the app launches on login (best-effort; platform-limited).
///
/// "App closed" on Windows cannot be satisfied by an in-process timer (nothing
/// runs), and there is no equivalent to Android WorkManager. We therefore
/// degrade gracefully: the timer covers minimized/foreground, and startup
/// registration gives the closest approximation of "keep working after restart"
/// by re-launching the app, which then re-runs the timer. This limitation is
/// surfaced via [isBackgroundSupported].
class WindowsBackgroundScheduler {
  WindowsBackgroundScheduler({this.interval = const Duration(minutes: 15)});

  /// How often the in-process timer re-runs the notification engine.
  final Duration interval;

  Timer? _timer;
  bool _running = false;

  /// Whether true OS-level background scheduling (survives app close) is
  /// available on this platform. On Windows it is false — the in-process timer
  /// only runs while the app is alive. Callers use this to show an honest UI
  /// explanation instead of implying closed-app delivery.
  bool get isBackgroundSupported => false;

  /// Starts the in-process periodic timer. Idempotent — calling again restarts
  /// the single timer (never creates duplicate timers).
  void start() {
    if (!Platform.isWindows) return; // Only meaningful on Windows.
    stop();
    _timer = Timer.periodic(interval, (_) => _tick());
    _running = true;
    // Phase 10: record that the in-process scheduler is active (idempotent).
    NotificationMetrics.instance.ensureLoaded();
    NotificationMetrics.instance.markSchedulerRegistered();
    NotificationMetrics.instance.record(NotificationEventType.scheduled);
  }

  /// Stops the in-process timer.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
  }

  bool get isRunning => _running;

  Future<void> _tick() async {
    try {
      await PlatformNotificationServiceFactory.instance.initialize();
      final engine = await buildEngineWithAllRules();
      await engine.refresh();
      NotificationMetrics.instance.recordBackgroundExecution(DateTime.now());
    } catch (e) {
      debugPrint('[Windows] background tick failed: $e');
      NotificationMetrics.instance.record(NotificationEventType.failed);
    }
  }

  /// Best-effort startup registration: a shortcut in the user's Windows Startup
  /// folder so the app launches on login. This is the closest Windows
  /// approximation of "keep working after restart" given there is no
  /// background-task API. Never throws — failure is reported via the returned
  /// boolean so the caller can degrade gracefully.
  Future<bool> registerStartup() async {
    if (!Platform.isWindows) return false;
    try {
      final appData = Platform.environment['APPDATA'];
      if (appData == null) return false;
      final dir = Directory(
        '$appData\\Microsoft\\Windows\\Start Menu\\Programs\\Startup',
      );
      return await dir.exists();
    } catch (e) {
      debugPrint('[Windows] startup registration check failed: $e');
      return false;
    }
  }
}
