import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../analytics/notification_metrics.dart';

/// Tracks delivered/seen notifications so future rules never emit duplicates.
///
/// Backed by SharedPreferences (no SQLite business tables are touched). For
/// every emitted notification we store a [NotificationRecord] keyed by the
/// notification [NotificationModel.id]. Rules ask [wasAlreadyDelivered] with a
/// stable id (e.g. `payment_due:site:42:june-2026`) instead of re-implementing
/// dedup logic themselves.
class NotificationHistoryRepository {
  NotificationHistoryRepository._(this._prefs);

  static Future<NotificationHistoryRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationHistoryRepository._(prefs);
  }

  final SharedPreferences _prefs;

  static const String _listKey = 'worklist.notifications.history.v1';
  static const int _maxRecords = 500;

  /// Returns true if a notification with [id] has already been recorded as
  /// delivered. Rules use this to skip re-emitting the same logical reminder.
  Future<bool> wasAlreadyDelivered(String id) async {
    final record = await _read(id);
    return record?.deliveredAt != null;
  }

  /// Returns true if a notification with [id] has already been recorded
  /// (delivered, read, or dismissed) — used for "do not show again" semantics.
  Future<bool> wasAlreadyDeliveredOrSeen(String id) async =>
      (await _read(id)) != null;

  /// Records (upsert) a notification history entry. Returns the stored record.
  ///
  /// Persists display fields (title/body/priority) from [notification] so the
  /// Notification Center can render content without re-querying. Existing
  /// display fields are preserved when the incoming notification omits them
  /// (e.g. during a mark-read/dismiss call that only sets flags).
  Future<NotificationRecord> record({
    required NotificationModel notification,
    DateTime? deliveredAt,
    bool read = false,
    bool dismissed = false,
  }) async {
    final existing = await _read(notification.id);
    final title = notification.title.isNotEmpty
        ? notification.title
        : existing?.title;
    final body =
        notification.body.isNotEmpty ? notification.body : existing?.body;
    final priority = notification.priority != NotificationPriority.normal ||
            existing?.priority != null
        ? (notification.priority != NotificationPriority.normal
            ? notification.priority
            : existing!.priority)
        : null;
    final record = NotificationRecord(
      id: notification.id,
      type: notification.type,
      entityId: notification.entityId,
      entityType: notification.entityType,
      title: title,
      body: body,
      priority: priority,
      createdAt: existing?.createdAt ?? DateTime.now(),
      deliveredAt: deliveredAt ?? existing?.deliveredAt ?? DateTime.now(),
      readAt: read ? DateTime.now() : existing?.readAt,
      dismissedAt: dismissed ? DateTime.now() : existing?.dismissedAt,
      archivedAt: existing?.archivedAt,
    );
    final all = _readAll();
    all[notification.id] = record;
    await _writeAll(all);
    return record;
  }

  /// Marks a previously-delivered notification as read (idempotent).
  Future<void> markRead(String id) async {
    NotificationMetrics.instance.ensureLoaded();
    NotificationMetrics.instance.record(NotificationEventType.opened);
    final existing = await _read(id);
    if (existing == null) return;
    await record(
      notification: NotificationModel(
        id: id,
        title: '',
        body: '',
        type: existing.type,
        createdAt: existing.createdAt,
      ),
      deliveredAt: null,
      read: true,
    );
  }

  /// Marks a previously-read notification as unread again (idempotent). It
  /// clears the [NotificationRecord.readAt] flag by re-recording the entry
  /// without a read timestamp.
  Future<void> markUnread(String id) async {
    final existing = await _read(id);
    if (existing == null) return;
    final record = existing.copyWith(readAt: null);
    final all = _readAll();
    all[id] = record;
    await _writeAll(all);
  }

  /// Marks a previously-delivered notification as dismissed (idempotent).
  Future<void> markDismissed(String id) async {
    NotificationMetrics.instance.record(NotificationEventType.dismissed);
    final existing = await _read(id);
    if (existing == null) return;
    await record(
      notification: NotificationModel(
        id: id,
        title: '',
        body: '',
        type: existing.type,
        createdAt: existing.createdAt,
      ),
      deliveredAt: null,
      dismissed: true,
    );
  }

  /// All history records, newest first. Used by future "notification center" UI.
  Future<List<NotificationRecord>> getAll({bool? unreadOnly}) async {
    final all = _readAll().values.toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (unreadOnly == true) {
      return all.where((r) => r.readAt == null).toList();
    }
    return all;
  }

  /// Prunes the oldest records beyond [_maxRecords] to bound storage.
  Future<void> prune() async {
    final all = _readAll();
    if (all.length <= _maxRecords) return;
    final sorted = all.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final toRemove = sorted.length - _maxRecords;
    for (var i = 0; i < toRemove; i++) {
      all.remove(sorted[i].id);
    }
    await _writeAll(all);
  }

  Map<String, NotificationRecord> _readAll() {
    final raw = _prefs.getString(_listKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (k, v) => MapEntry(k, NotificationRecord.fromMap(v as Map<String, dynamic>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeAll(Map<String, NotificationRecord> all) async {
    final encoded =
        jsonEncode(all.map((k, v) => MapEntry(k, v.toMap())));
    await _prefs.setString(_listKey, encoded);
  }

  Future<NotificationRecord?> _read(String id) async =>
      _readAll()[id];

  /// Public read access used by the interactive-action response handler to
  /// resolve a notification (and its deep link) when the in-memory shown-map is
  /// empty (e.g. cold-start tap).
  Future<NotificationRecord?> read(String id) => _read(id);

  /// Public read-all used by the cross-device notification sync (Phase 12) so
  /// it can merge the cloud blob with local state without reaching into privates.
  Map<String, NotificationRecord> readAllPublic() => _readAll();

  /// Public write-all used by the cross-device notification sync (Phase 12)
  /// after merging the latest-wins records from the cloud.
  Future<void> writeAllPublic(Map<String, NotificationRecord> all) =>
      _writeAll(all);

  /// Removes a single history entry (used by "Delete").
  Future<void> delete(String id) async {
    final all = _readAll();
    all.remove(id);
    await _writeAll(all);
  }

  /// Removes all history entries (used by "Delete All").
  Future<void> deleteAll() async => _writeAll({});

  /// Marks a record as archived (idempotent). Archived items are kept but
  /// filtered into their own view by the Notification Center.
  Future<void> archive(String id) async {
    NotificationMetrics.instance.record(NotificationEventType.archived);
    final existing = await _read(id);
    if (existing == null) return;
    final updated = existing.copyWith(archivedAt: DateTime.now());
    final all = _readAll();
    all[id] = updated;
    await _writeAll(all);
  }

  /// Marks a record as snoozed (idempotent). Snooze state is part of the
  /// notification *metadata* that is synchronized across devices (Phase 12), so
  /// it is persisted here and uploaded on the next cloud sync. The timed
  /// re-show itself is handled by the platform service (in-process only — it is
  /// intentionally NOT synchronized, per the Phase 12 scope).
  Future<void> markSnoozed(String id, {DateTime? at}) async {
    NotificationMetrics.instance.record(NotificationEventType.snoozed);
    final existing = await _read(id);
    final updated = (existing ??
            NotificationRecord(
              id: id,
              type: NotificationType.generic,
              createdAt: at ?? DateTime.now(),
            ))
        .copyWith(snoozedAt: at ?? DateTime.now());
    final all = _readAll();
    all[id] = updated;
    await _writeAll(all);
  }
}

/// A single history entry. Stores bookkeeping fields plus the display fields
/// (title/body/priority) captured at delivery so the Notification Center can
/// render content without re-querying the source rules.
class NotificationRecord {
  NotificationRecord({
    required this.id,
    required this.type,
    this.entityId,
    this.entityType,
    this.title,
    this.body,
    this.priority,
    required this.createdAt,
    this.deliveredAt,
    this.readAt,
    this.dismissedAt,
    this.archivedAt,
    this.snoozedAt,
  });

  final String id;
  final NotificationType type;
  final String? entityId;
  final String? entityType;
  final String? title;
  final String? body;
  final NotificationPriority? priority;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final DateTime? archivedAt;
  final DateTime? snoozedAt;

  bool get isRead => readAt != null;
  bool get isDismissed => dismissedAt != null;
  bool get isArchived => archivedAt != null;
  bool get isSnoozed => snoozedAt != null;
  bool get isUnread => !isRead && !isDismissed && !isArchived;

  NotificationRecord copyWith({
    DateTime? readAt,
    DateTime? archivedAt,
    DateTime? snoozedAt,
  }) =>
      NotificationRecord(
        id: id,
        type: type,
        entityId: entityId,
        entityType: entityType,
        title: title,
        body: body,
        priority: priority,
        createdAt: createdAt,
        deliveredAt: deliveredAt,
        readAt: readAt ?? this.readAt,
        dismissedAt: dismissedAt,
        archivedAt: archivedAt ?? this.archivedAt,
        snoozedAt: snoozedAt ?? this.snoozedAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.name,
        'entityId': entityId,
        'entityType': entityType,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        if (priority != null) 'priority': priority!.name,
        'createdAt': createdAt.toIso8601String(),
        'deliveredAt': deliveredAt?.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'dismissedAt': dismissedAt?.toIso8601String(),
        'archivedAt': archivedAt?.toIso8601String(),
        'snoozedAt': snoozedAt?.toIso8601String(),
      };

  factory NotificationRecord.fromMap(Map<String, dynamic> m) => NotificationRecord(
        id: m['id'] as String,
        type: NotificationTypeX.fromName(m['type'] as String?),
        entityId: m['entityId'] as String?,
        entityType: m['entityType'] as String?,
        title: m['title'] as String?,
        body: m['body'] as String?,
        priority: NotificationPriorityX.fromName(m['priority'] as String?),
        createdAt: DateTime.parse(m['createdAt'] as String),
        deliveredAt: m['deliveredAt'] == null
            ? null
            : DateTime.parse(m['deliveredAt'] as String),
        readAt: m['readAt'] == null ? null : DateTime.parse(m['readAt'] as String),
        dismissedAt: m['dismissedAt'] == null
            ? null
            : DateTime.parse(m['dismissedAt'] as String),
        archivedAt: m['archivedAt'] == null
            ? null
            : DateTime.parse(m['archivedAt'] as String),
        snoozedAt: m['snoozedAt'] == null
            ? null
            : DateTime.parse(m['snoozedAt'] as String),
      );
}
