import 'dart:convert';

import 'notification_action.dart';

/// Priority levels for a notification. Higher priority maps to higher
/// platform importance and (for [NotificationPriority.critical]) bypasses
/// quiet hours.
enum NotificationPriority {
  low,
  normal,
  high,
  critical,
}

extension NotificationPriorityX on NotificationPriority {
  String get name => toString().split('.').last;

  static NotificationPriority fromName(String? value) =>
      NotificationPriority.values.firstWhere(
        (e) => e.name == (value ?? ''),
        orElse: () => NotificationPriority.normal,
      );
}

/// Lifecycle status of a notification record.
enum NotificationStatus {
  pending,
  scheduled,
  delivered,
  read,
  dismissed,
  failed,
}

extension NotificationStatusX on NotificationStatus {
  String get name => toString().split('.').last;

  static NotificationStatus fromName(String? value) =>
      NotificationStatus.values.firstWhere(
        (e) => e.name == (value ?? ''),
        orElse: () => NotificationStatus.pending,
      );
}

/// Category of a notification. Drives user-toggleable settings and the
/// platform notification channel. New categories are added here only.
enum NotificationType {
  payment,
  payroll,
  inventory,
  worker,
  attendance,
  site,
  service,
  dailySummary,
  weeklySummary,
  monthlySummary,
  system,
  generic,
}

extension NotificationTypeX on NotificationType {
  String get name => toString().split('.').last;

  /// Maps a notification type to its user-toggleable settings category key.
  /// System/generic notifications are not user-toggleable and return null.
  String? get categoryKey {
    switch (this) {
      case NotificationType.payment:
        return 'payments';
      case NotificationType.payroll:
        return 'payroll';
      case NotificationType.inventory:
        return 'inventory';
      case NotificationType.worker:
        return 'workers';
      case NotificationType.attendance:
        return 'attendance';
      case NotificationType.site:
        return 'sites';
      case NotificationType.service:
        return 'services';
      case NotificationType.dailySummary:
        return 'dailySummary';
      case NotificationType.weeklySummary:
        return 'weeklySummary';
      case NotificationType.monthlySummary:
        return 'monthlySummary';
      case NotificationType.system:
      case NotificationType.generic:
        return null;
    }
  }

  static NotificationType fromName(String? value) =>
      NotificationType.values.firstWhere(
        (e) => e.name == (value ?? ''),
        orElse: () => NotificationType.generic,
      );
}

/// The core notification record. This is the single data model every future
/// notification (payments, inventory, payroll, …) uses. No reminder-specific
/// fields are hard-coded here — domain meaning lives in [entityType]/[entityId]
/// and [payload].
class NotificationModel {
  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.status = NotificationStatus.pending,
    required this.createdAt,
    this.scheduledFor,
    this.deliveredAt,
    this.readAt,
    this.dismissedAt,
    this.entityId,
    this.entityType,
    this.payload,
    this.actions,
    this.isRead = false,
    this.isDismissed = false,
    this.isRecurring = false,
  });

  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final NotificationStatus status;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final String? entityId;
  final String? entityType;
  final Map<String, dynamic>? payload;
  final List<NotificationAction>? actions;
  final bool isRead;
  final bool isDismissed;
  final bool isRecurring;

  /// Stable, collision-resistant platform id derived from [id].
  int get platformId => id.hashCode.abs();

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    NotificationStatus? status,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? deliveredAt,
    DateTime? readAt,
    DateTime? dismissedAt,
    String? entityId,
    String? entityType,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool? isRead,
    bool? isDismissed,
    bool? isRecurring,
  }) =>
      NotificationModel(
        id: id ?? this.id,
        title: title ?? this.title,
        body: body ?? this.body,
        type: type ?? this.type,
        priority: priority ?? this.priority,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        readAt: readAt ?? this.readAt,
        dismissedAt: dismissedAt ?? this.dismissedAt,
        entityId: entityId ?? this.entityId,
        entityType: entityType ?? this.entityType,
        payload: payload ?? this.payload,
        actions: actions ?? this.actions,
        isRead: isRead ?? this.isRead,
        isDismissed: isDismissed ?? this.isDismissed,
        isRecurring: isRecurring ?? this.isRecurring,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.name,
        'priority': priority.name,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'scheduledFor': scheduledFor?.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'dismissedAt': dismissedAt?.toIso8601String(),
        'entityId': entityId,
        'entityType': entityType,
        'payload': payload == null ? null : jsonEncode(payload),
        'actions': actions == null
            ? null
            : jsonEncode(actions!.map((a) => a.toMap()).toList()),
        'isRead': isRead ? 1 : 0,
        'isDismissed': isDismissed ? 1 : 0,
        'isRecurring': isRecurring ? 1 : 0,
      };

  factory NotificationModel.fromMap(Map<String, dynamic> m) => NotificationModel(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        type: NotificationTypeX.fromName(m['type'] as String?),
        priority: NotificationPriorityX.fromName(m['priority'] as String?),
        status: NotificationStatusX.fromName(m['status'] as String?),
        createdAt: DateTime.parse(m['createdAt'] as String),
        scheduledFor: m['scheduledFor'] == null
            ? null
            : DateTime.parse(m['scheduledFor'] as String),
        deliveredAt: m['deliveredAt'] == null
            ? null
            : DateTime.parse(m['deliveredAt'] as String),
        readAt: m['readAt'] == null ? null : DateTime.parse(m['readAt'] as String),
        dismissedAt: m['dismissedAt'] == null
            ? null
            : DateTime.parse(m['dismissedAt'] as String),
        entityId: m['entityId'] as String?,
        entityType: m['entityType'] as String?,
        payload: m['payload'] == null
            ? null
            : (jsonDecode(m['payload'] as String) as Map<String, dynamic>),
        actions: m['actions'] == null
            ? null
            : (jsonDecode(m['actions'] as String) as List)
                .map((e) => NotificationAction.fromMap(e as Map<String, dynamic>))
                .toList(),
        isRead: (m['isRead'] as int? ?? 0) == 1,
        isDismissed: (m['isDismissed'] as int? ?? 0) == 1,
        isRecurring: (m['isRecurring'] as int? ?? 0) == 1,
      );

  @override
  String toString() =>
      'NotificationModel(id: $id, type: ${type.name}, status: ${status.name}, title: $title)';
}

/// Convenience alias so the model can be referenced as `NotificationModel`
/// (per the requested component name) while the rule API uses `AppNotification`.
typedef AppNotification = NotificationModel;
