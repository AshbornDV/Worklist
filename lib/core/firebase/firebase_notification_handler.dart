import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Global FCM background message handler. Must be top-level/static and
/// registered BEFORE runApp so it's active when the app is closed/terminated.
@pragma('vm:entry-point')
void _firebaseMessagingBackgroundHandler(RemoteMessage message) {
  debugPrint('[FCM] background message received: ${message.messageId}');
  FirebaseNotificationHandler.handleBackgroundMessage(message);
}

/// Singleton that sets up the Android notification channels at startup.
/// The FCM background handler is registered separately in main.dart.
class FirebaseNotificationHandler {
  FirebaseNotificationHandler._();

  static final FirebaseNotificationHandler instance = FirebaseNotificationHandler._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Initialize the FlutterLocalNotifications plugin with Android channel(s).
  /// Safe to call multiple times (idempotent).
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );
    await _plugin.initialize(
      settings: initSettings,
    );
    // Foreground messages: FCM does not show a heads-up notification while
    // the app is open by default, so surface high-priority data messages as
    // a local notification so the user sees them immediately.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Entry point for the top-level background isolate handler. Runs outside
  /// the app's isolate graph, so it must not touch providers or the database.
  /// It re-emits the message as a local notification via the plugin, which
  /// is safe to call from a background isolate.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      await instance._showRemoteMessage(message);
    } catch (e, s) {
      debugPrint('[FCM] background show failed: $e\n$s');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    instance._showRemoteMessage(message);
  }

  Future<void> _showRemoteMessage(RemoteMessage message) async {
    if (!_initialized) await initialize();
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? 'Worklist';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    if (body.isEmpty && title == 'Worklist') return;
    final priority = (message.data['priority'] as String?) == 'high'
        ? Importance.high
        : Importance.defaultImportance;
    final details = AndroidNotificationDetails(
      'worklist.fcm',
      'Worklist messages',
      channelDescription: 'Firebase Cloud Messaging notifications',
      importance: priority,
      priority: priority == Importance.high ? Priority.high : Priority.defaultPriority,
      visibility: NotificationVisibility.public,
    );
    await _plugin.show(
      id: message.hashCode & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(android: details),
    );
  }
}