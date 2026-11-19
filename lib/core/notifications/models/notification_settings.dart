import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show TimeOfDay;

import 'notification_model.dart';

/// User-facing notification preferences. Phase 1 defines the model and a
/// SharedPreferences-backed repository. No UI is built in this phase.
@immutable
class NotificationSettings {
  const NotificationSettings({
    this.masterEnabled = true,
    this.payments = true,
    this.payroll = true,
    this.inventory = true,
    this.workers = true,
    this.attendance = true,
    this.sites = true,
    this.services = true,
    this.dailySummary = false,
    this.weeklySummary = false,
    this.monthlySummary = false,
    this.sound = true,
    this.vibration = true,
    this.priority = NotificationPriority.normal,
    this.quietHoursEnabled = false,
    this.quietHoursStart = const TimeOfDay(hour: 22, minute: 0),
    this.quietHoursEnd = const TimeOfDay(hour: 7, minute: 0),
    this.reminderTimes = const [TimeOfDay(hour: 9, minute: 0)],
    this.dailyBriefingTime = const TimeOfDay(hour: 8, minute: 0),
    this.weeklyReportWeekday = DateTime.monday,
    this.weeklyReportTime = const TimeOfDay(hour: 9, minute: 0),
    this.monthlyReportDay = 1,
    this.monthlyReportTime = const TimeOfDay(hour: 9, minute: 0),
  });

  final bool masterEnabled;
  final bool payments;
  final bool payroll;
  final bool inventory;
  final bool workers;
  final bool attendance;
  final bool sites;
  final bool services;
  final bool dailySummary;
  final bool weeklySummary;
  final bool monthlySummary;
  final bool sound;
  final bool vibration;
  final NotificationPriority priority;
  final bool quietHoursEnabled;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final List<TimeOfDay> reminderTimes;
  final TimeOfDay dailyBriefingTime;
  final int weeklyReportWeekday;
  final TimeOfDay weeklyReportTime;
  final int monthlyReportDay;
  final TimeOfDay monthlyReportTime;

  /// Whether notifications of [type] are allowed by the per-category toggles
  /// (and by the master switch). System/generic types bypass the category
  /// toggle (they are always governed only by [masterEnabled]).
  bool isTypeEnabled(NotificationType type) {
    if (!masterEnabled) return false;
    final key = type.categoryKey;
    if (key == null) return true;
    switch (key) {
      case 'payments':
        return payments;
      case 'payroll':
        return payroll;
      case 'inventory':
        return inventory;
      case 'workers':
        return workers;
      case 'attendance':
        return attendance;
      case 'sites':
        return sites;
      case 'services':
        return services;
      case 'dailySummary':
        return dailySummary;
      case 'weeklySummary':
        return weeklySummary;
      case 'monthlySummary':
        return monthlySummary;
    }
    return true;
  }

  /// Whether a notification with [priority] would be silenced by quiet hours
  /// given the current local [now]. Critical notifications bypass quiet hours.
  bool isSilencedByQuietHours(NotificationPriority priority, DateTime now) {
    if (!quietHoursEnabled) return false;
    if (priority == NotificationPriority.critical) return false;
    final nowMinutes = now.hour * 60 + now.minute;
    final start = quietHoursStart.hour * 60 + quietHoursStart.minute;
    final end = quietHoursEnd.hour * 60 + quietHoursEnd.minute;
    if (start == end) return false;
    if (start < end) {
      return nowMinutes >= start && nowMinutes < end;
    }
    // Quiet window wraps past midnight.
    return nowMinutes >= start || nowMinutes < end;
  }

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? payments,
    bool? payroll,
    bool? inventory,
    bool? workers,
    bool? attendance,
    bool? sites,
    bool? services,
    bool? dailySummary,
    bool? weeklySummary,
    bool? monthlySummary,
    bool? sound,
    bool? vibration,
    NotificationPriority? priority,
    bool? quietHoursEnabled,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    List<TimeOfDay>? reminderTimes,
    TimeOfDay? dailyBriefingTime,
    int? weeklyReportWeekday,
    TimeOfDay? weeklyReportTime,
    int? monthlyReportDay,
    TimeOfDay? monthlyReportTime,
  }) =>
      NotificationSettings(
        masterEnabled: masterEnabled ?? this.masterEnabled,
        payments: payments ?? this.payments,
        payroll: payroll ?? this.payroll,
        inventory: inventory ?? this.inventory,
        workers: workers ?? this.workers,
        attendance: attendance ?? this.attendance,
        sites: sites ?? this.sites,
        services: services ?? this.services,
        dailySummary: dailySummary ?? this.dailySummary,
        weeklySummary: weeklySummary ?? this.weeklySummary,
        monthlySummary: monthlySummary ?? this.monthlySummary,
        sound: sound ?? this.sound,
        vibration: vibration ?? this.vibration,
        priority: priority ?? this.priority,
        quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
        quietHoursStart: quietHoursStart ?? this.quietHoursStart,
        quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
        reminderTimes: reminderTimes ?? this.reminderTimes,
        dailyBriefingTime: dailyBriefingTime ?? this.dailyBriefingTime,
        weeklyReportWeekday: weeklyReportWeekday ?? this.weeklyReportWeekday,
        weeklyReportTime: weeklyReportTime ?? this.weeklyReportTime,
        monthlyReportDay: monthlyReportDay ?? this.monthlyReportDay,
        monthlyReportTime: monthlyReportTime ?? this.monthlyReportTime,
      );

  static const String _timeSep = ':';

  static String _encodeTime(TimeOfDay t) =>
      '${t.hour}$_timeSep${t.minute}';

  static TimeOfDay _decodeTime(String s) {
    final parts = s.split(_timeSep);
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Map<String, dynamic> toJson() => {
        'masterEnabled': masterEnabled,
        'payments': payments,
        'payroll': payroll,
        'inventory': inventory,
        'workers': workers,
        'attendance': attendance,
        'sites': sites,
        'services': services,
        'dailySummary': dailySummary,
        'weeklySummary': weeklySummary,
        'monthlySummary': monthlySummary,
        'sound': sound,
        'vibration': vibration,
        'priority': priority.name,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': _encodeTime(quietHoursStart),
        'quietHoursEnd': _encodeTime(quietHoursEnd),
        'reminderTimes': reminderTimes.map(_encodeTime).toList(),
        'dailyBriefingTime': _encodeTime(dailyBriefingTime),
        'weeklyReportWeekday': weeklyReportWeekday,
        'weeklyReportTime': _encodeTime(weeklyReportTime),
        'monthlyReportDay': monthlyReportDay,
        'monthlyReportTime': _encodeTime(monthlyReportTime),
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        masterEnabled: json['masterEnabled'] as bool? ?? true,
        payments: json['payments'] as bool? ?? true,
        payroll: json['payroll'] as bool? ?? true,
        inventory: json['inventory'] as bool? ?? true,
        workers: json['workers'] as bool? ?? true,
        attendance: json['attendance'] as bool? ?? true,
        sites: json['sites'] as bool? ?? true,
        services: json['services'] as bool? ?? true,
        dailySummary: json['dailySummary'] as bool? ?? false,
        weeklySummary: json['weeklySummary'] as bool? ?? false,
        monthlySummary: json['monthlySummary'] as bool? ?? false,
        sound: json['sound'] as bool? ?? true,
        vibration: json['vibration'] as bool? ?? true,
        priority:
            NotificationPriorityX.fromName(json['priority'] as String?),
        quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
        quietHoursStart: _decodeTime(json['quietHoursStart'] as String? ?? '22:0'),
        quietHoursEnd: _decodeTime(json['quietHoursEnd'] as String? ?? '7:0'),
        reminderTimes: (json['reminderTimes'] as List<dynamic>? ?? ['9:0'])
            .map((e) => _decodeTime(e as String))
            .toList(),
        dailyBriefingTime:
            _decodeTime(json['dailyBriefingTime'] as String? ?? '8:0'),
        weeklyReportWeekday: json['weeklyReportWeekday'] as int? ?? 1,
        weeklyReportTime:
            _decodeTime(json['weeklyReportTime'] as String? ?? '9:0'),
        monthlyReportDay: json['monthlyReportDay'] as int? ?? 1,
        monthlyReportTime:
            _decodeTime(json['monthlyReportTime'] as String? ?? '9:0'),
      );
}
