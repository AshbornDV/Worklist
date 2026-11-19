import '../models/notification_model.dart';

/// Platform-agnostic contract for actually presenting a notification to the OS
/// notification shade / action center. Concrete implementations
/// ([AndroidNotificationService], [WindowsNotificationService]) wrap
/// `flutter_local_notifications` and map our [NotificationModel] to platform
/// specifics. The engine depends only on this abstraction, so new platforms
/// (iOS, Linux, macOS) can be added without touching the engine.
abstract class PlatformNotificationService {
  /// Initializes the underlying plugin and requests permissions. Safe to call
  /// repeatedly; implementations should be idempotent.
  Future<void> initialize();

  /// Shows [notification] immediately via the OS. Returns true on success.
  /// [settings] lets the platform honor sound/vibration toggles.
  Future<bool> show(NotificationModel notification);

  /// Cancels a previously shown notification by its platform id.
  Future<void> cancel(int platformId);

  /// Cancels all notifications shown by this app on the current platform.
  Future<void> cancelAll();
}
