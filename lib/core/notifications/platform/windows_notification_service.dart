import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../actions/notification_action_catalog.dart';
import '../actions/notification_action_handler.dart';
import '../core/notification_logger.dart';
import '../models/notification_action.dart';
import '../models/notification_model.dart';
import 'platform_notification_service.dart';

/// Windows implementation of [PlatformNotificationService] using
/// `flutter_local_notifications` (Windows action center).
///
/// Phase 9 — interactive actions: `flutter_local_notifications` v22's
/// [WindowsNotificationDetails] does not support native action buttons, so
/// action buttons **degrade gracefully** — the notification is still shown and
/// tapping it opens the app via the payload. The same [actionHandler] is wired
/// for the tap response, so deep-linking works on Windows; the rich action
/// buttons are simply not rendered (documented limitation, not a failure).
class WindowsNotificationService implements PlatformNotificationService {
  WindowsNotificationService._();

  static final WindowsNotificationService instance =
      WindowsNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Injected by the app at startup (see Android counterpart).
  static NotificationActionHandler? actionHandler;

  final Map<String, NotificationModel> _shownById = {};

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const initSettings = WindowsInitializationSettings(
      appName: 'Worklist',
      appUserModelId: 'com.worklist.app',
      guid: 'a3b5c7d9-e1f2-4a6b-8c0d-1e2f3a4b5c6d',
    );
    const settings = InitializationSettings(windows: initSettings);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
    );
    _initialized = true;
    NotificationLogger.instance
        .info('Windows notification service initialized');
  }

  void _onResponse(NotificationResponse response) {
    final id = response.payload;
    if (id == null) return;
    _resolve(id).then((notification) {
      if (notification == null) return;
      // Windows has no action buttons; a tap is treated as "Open".
      const open = NotificationAction(
        category: NotificationActionCategory.open,
        label: 'Open',
      );
      unawaited(actionHandler?.handle(notification, open));
    });
  }

  Future<NotificationModel?> _resolve(String id) async {
    final cached = _shownById[id];
    if (cached != null) return cached;
    final history = actionHandler?.history;
    if (history == null) return null;
    final record = await history.read(id);
    if (record == null) return null;
    return notificationFromRecord(record);
  }

  @override
  Future<bool> show(NotificationModel notification) async {
    if (!_initialized) await initialize();
    try {
      // Actions are computed for parity/inspection but not rendered natively
      // on Windows (the platform doesn't support action buttons here). They
      // remain attached to the model so the in-app Notification Center can
      // surface them.
      final actions = notification.actions ??
          NotificationActionCatalog.actionsFor(notification);
      _shownById[notification.id] = notification.copyWith(actions: actions);

      const details = WindowsNotificationDetails();
      const notifDetails = NotificationDetails(windows: details);
      await _plugin.show(
        id: notification.platformId,
        title: notification.title,
        body: notification.body,
        notificationDetails: notifDetails,
        payload: notification.id,
      );
      return true;
    } catch (e, s) {
      NotificationLogger.instance
          .error('Windows show failed for ${notification.id}', e, s);
      return false;
    }
  }

  @override
  Future<void> cancel(int platformId) async =>
      _plugin.cancel(id: platformId);

  @override
  Future<void> cancelAll() async => _plugin.cancelAll();
}
