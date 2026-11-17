import 'dart:io';

import '../platform/android_notification_service.dart';
import '../platform/platform_notification_service.dart';
import '../platform/windows_notification_service.dart';
import '../scheduler/notification_scheduler.dart';

/// Selects the correct [PlatformNotificationService] for the running OS and
/// owns the single [NotificationScheduler] instance. This is the composition
/// root for the platform layer of the notification framework.
///
/// Phase 1: only the "immediate show" path is live. Exact-time / recurring
/// scheduling and WorkManager background dispatch are prepared (see
/// [NotificationScheduler]) but not yet triggered by any rule.
class PlatformNotificationServiceFactory {
  PlatformNotificationServiceFactory._();

  static PlatformNotificationService? _instance;

  /// Returns a platform-appropriate [PlatformNotificationService], creating it
  /// lazily and initializing the underlying plugin on first use.
  static PlatformNotificationService get instance {
    _instance ??= _create();
    return _instance!;
  }

  static PlatformNotificationService _create() {
    if (Platform.isAndroid) {
      return AndroidNotificationService.instance;
    } else if (Platform.isWindows) {
      return WindowsNotificationService.instance;
    }
    // Fallback: Android implementation is the safe default for unsupported
    // desktop/other targets in this Windows+Android app.
    return AndroidNotificationService.instance;
  }

  /// The single scheduler used by the engine. Wires the platform service so
  /// scheduling (when enabled in a future phase) can deliver through the same
  /// channel as immediate notifications.
  static NotificationScheduler get scheduler =>
      NotificationScheduler(instance);
}
