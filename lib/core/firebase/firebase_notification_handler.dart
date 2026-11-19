import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Global FCM background message handler. Must be top-level/static and
/// registered BEFORE runApp so it's active when the app is closed/terminated.
@pragma('vm:entry-point')
void _firebaseMessagingBackgroundHandler(RemoteMessage message) {
  debugPrint('[FCM] background message received: ${message.messageId}');
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
  }
}