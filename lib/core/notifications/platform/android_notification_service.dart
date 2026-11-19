import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../actions/notification_action_catalog.dart';
import '../actions/notification_action_handler.dart';
import '../core/notification_logger.dart';
import '../models/notification_action.dart';
import '../models/notification_model.dart';
import 'platform_notification_service.dart';

/// Android implementation of [PlatformNotificationService] using
/// `flutter_local_notifications`.
///
/// Phase 9 adds interactive action buttons: each notification carries the
/// actions derived from [NotificationActionCatalog] (Payment / Worker / Site /
/// Inventory / Service / General per spec). Tapping a button fires the plugin's
/// [onDidReceiveNotificationResponse] with the action id; [NotificationActionHandler]
/// (injected by the app) routes it to a deep link, a status update, or a snooze.
class AndroidNotificationService implements PlatformNotificationService {
  AndroidNotificationService._();

  static final AndroidNotificationService instance =
      AndroidNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Injected by the app at startup so OS action taps can be routed to deep
  /// links / status updates. If null, taps still deliver the notification but
  /// actions are ignored (graceful).
  static NotificationActionHandler? actionHandler;

  /// Remembers the last [NotificationModel] shown per id so the response
  /// handler can reconstruct it from the action's payload (which is the id).
  final Map<String, NotificationModel> _shownById = {};

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const initSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: initSettings);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onResponse,
    );
    _initialized = true;
    NotificationLogger.instance.info('Android notification service initialized');
  }

  void _onResponse(NotificationResponse response) {
    final id = response.payload;
    if (id == null) return;
    _resolve(id).then((notification) {
      if (notification == null) return;
      final action = notification.actions?.firstWhere(
        (a) => a.actionId == response.actionId,
        orElse: () => const NotificationAction(
          category: NotificationActionCategory.open,
          label: 'Open',
        ),
      );
      if (action == null) return;
      unawaited(actionHandler?.handle(notification, action));
    });
  }

  /// Resolves the shown notification by id. Checks the in-memory map first
  /// (warm path); falls back to the history store so a notification tapped
  /// from a cold start can still be routed to its deep link.
  Future<NotificationModel?> _resolve(String id) async {
    final cached = _shownById[id];
    if (cached != null) return cached;
    final history = actionHandler?.history;
    if (history == null) return null;
    final record = await history.read(id);
    if (record == null) return null;
    return notificationFromRecord(
      record,
      actions: NotificationActionCatalog.actionsFor(
        NotificationModel(
          id: record.id,
          title: record.title ?? '',
          body: record.body ?? '',
          type: record.type,
          createdAt: record.createdAt,
          entityType: record.entityType,
          entityId: record.entityId,
        ),
      ),
    );
  }

  @override
  Future<bool> show(NotificationModel notification) async {
    if (!_initialized) await initialize();
    try {
      final actions = notification.actions ??
          NotificationActionCatalog.actionsFor(notification);
      // Remember for the response handler (covers both tap and action taps).
      _shownById[notification.id] = notification.copyWith(actions: actions);

      final androidActions = actions
          .map(
            (a) => AndroidNotificationAction(
              a.resolvedActionId,
              a.label,
              // "Open"-style actions foreground the app to the right screen;
              // the rest run without showing the UI (fire-and-forget).
              showsUserInterface: _opensApp(a.category),
            ),
          )
          .toList();

      final details = AndroidNotificationDetails(
        'worklist.${notification.type.name}',
        'Worklist ${notification.type.name}',
        channelDescription: 'Worklist ${notification.type.name} notifications',
        importance: _importance(notification.priority),
        priority: _priority(notification.priority),
        visibility: NotificationVisibility.public,
        playSound: notification.priority != NotificationPriority.low,
        actions: androidActions,
      );
      await _plugin.show(
        id: notification.platformId,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(android: details),
        payload: notification.id,
      );
      return true;
    } catch (e, s) {
      NotificationLogger.instance
          .error('Android show failed for ${notification.id}', e, s);
      return false;
    }
  }

  bool _opensApp(NotificationActionCategory c) =>
      c == NotificationActionCategory.open ||
      c == NotificationActionCategory.openPayment ||
      c == NotificationActionCategory.openWorker ||
      c == NotificationActionCategory.openSite ||
      c == NotificationActionCategory.openInventory ||
      c == NotificationActionCategory.openService;

  @override
  Future<void> cancel(int platformId) async => _plugin.cancel(id: platformId);

  @override
  Future<void> cancelAll() async => _plugin.cancelAll();

  Importance _importance(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.critical:
        return Importance.max;
    }
  }

  Priority _priority(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.critical:
        return Priority.max;
    }
  }
}
