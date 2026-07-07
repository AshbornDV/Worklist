import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../constants/app_constants.dart';
import '../models/site_model.dart';

/// Shows collection reminders in the system notification panel and lock screen.
class CollectionReminderService {
  CollectionReminderService._();
  static final CollectionReminderService instance = CollectionReminderService._();

  final _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final windows = WindowsInitializationSettings(
      appName: 'Worklist',
      appUserModelId: 'com.example.worklist',
      guid: 'a3b5c7d9-e1f2-4a6b-8c0d-1e2f3a4b5c6d',
    );
    final initSettings = InitializationSettings(
      android: android,
      windows: windows,
    );

    await _notifications.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_initialized) await initialize();

    final android =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  Future<void> syncReminders(List<SiteModel> sites) async {
    if (!_initialized) await initialize();

    final dueSites = sites.where((s) => s.isCollectionDue).toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));

    await _notifications.cancelAll();

    if (dueSites.isEmpty) return;

    final totalDue =
        dueSites.fold<double>(0, (sum, site) => sum + site.balance);

    await _showNotification(
      id: 0,
      title: 'Worklist: Collect payment',
      body:
          '${dueSites.length} site(s) need payment — total ${AppConstants.currencySymbol} ${totalDue.toStringAsFixed(0)} remaining',
    );

    for (var i = 0; i < dueSites.length && i < 5; i++) {
      final site = dueSites[i];
      await _showNotification(
        id: site.id ?? (i + 1),
        title: 'Collect from ${site.name}',
        body:
            '${AppConstants.currencySymbol} ${site.balance.toStringAsFixed(0)} due · ${site.daysSinceLastPayment} days since last construction payment',
      );
    }
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'worklist_collections',
      'Payment collection reminders',
      channelDescription:
          'Reminds you when site payments are due after the last construction payment',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    final windowsDetails = WindowsNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      windows: windowsDetails,
    );

    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (error) {
      debugPrint('Collection notification failed: $error');
    }
  }
}
