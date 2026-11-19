import 'package:material_ui/material_ui.dart';

import '../models/notification_model.dart';
import '../repositories/notification_history_repository.dart';

/// Drives the Notification Center UI. It is a read/transform layer over
/// [NotificationHistoryRepository] — it never touches business data, sync, auth,
/// or the notification rules themselves. All mutations (mark read, dismiss,
/// archive, delete) delegate to the repository, and results are re-loaded so
/// the UI always reflects persisted state.
class NotificationCenterProvider extends ChangeNotifier {
  NotificationCenterProvider({required NotificationHistoryRepository repository})
      : _repository = repository;

  final NotificationHistoryRepository _repository;

  List<NotificationRecord> _all = [];
  bool _loading = false;
  String? _error;

  // ── UI state (filter / sort / group / search) ──
  String _query = '';
  NotificationStatusFilter _status = NotificationStatusFilter.all;
  NotificationType? _category;
  NotificationSort _sort = NotificationSort.dateDesc;
  NotificationGroupBy _groupBy = NotificationGroupBy.none;

  List<NotificationRecord> get all => _all;
  bool get isLoading => _loading;
  String? get error => _error;

  String get query => _query;
  NotificationStatusFilter get statusFilter => _status;
  NotificationType? get categoryFilter => _category;
  NotificationSort get sort => _sort;
  NotificationGroupBy get groupBy => _groupBy;

  /// Number of unread (not read/dismissed/archived) items.
  int get unreadCount =>
      _all.where((r) => r.isUnread).length;

  /// Loads/reloads all records from the repository.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
      _all = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── State setters (UI controls) ──
  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setStatusFilter(NotificationStatusFilter s) {
    _status = s;
    notifyListeners();
  }

  void setCategoryFilter(NotificationType? c) {
    _category = c;
    notifyListeners();
  }

  void setSort(NotificationSort s) {
    _sort = s;
    notifyListeners();
  }

  void setGroupBy(NotificationGroupBy g) {
    _groupBy = g;
    notifyListeners();
  }

  // ── Mutations (delegate to repository, then refresh) ──
  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    await load();
  }

  Future<void> markAllRead() async {
    for (final r in _visibleRecords) {
      if (r.isUnread) await _repository.markRead(r.id);
    }
    await load();
  }

  Future<void> dismiss(String id) async {
    await _repository.markDismissed(id);
    await load();
  }

  Future<void> archive(String id) async {
    await _repository.archive(id);
    await load();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await load();
  }

  // ── Derived views ──

  /// Records after applying status + category + search filters.
  List<NotificationRecord> get _visibleRecords {
    var list = _all;
    switch (_status) {
      case NotificationStatusFilter.all:
        break;
      case NotificationStatusFilter.unread:
        list = list.where((r) => r.isUnread).toList();
      case NotificationStatusFilter.read:
        list = list.where((r) => r.isRead && !r.isArchived).toList();
      case NotificationStatusFilter.dismissed:
        list = list.where((r) => r.isDismissed).toList();
      case NotificationStatusFilter.archived:
        list = list.where((r) => r.isArchived).toList();
    }
    if (_category != null) {
      list = list.where((r) => r.type == _category).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((r) {
        final title = (r.title ?? '').toLowerCase();
        final body = (r.body ?? '').toLowerCase();
        return title.contains(q) || body.contains(q);
      }).toList();
    }
    return list;
  }

  /// The filtered + sorted list for rendering (flat, when not grouped).
  List<NotificationRecord> get visibleRecords {
    final list = List<NotificationRecord>.from(_visibleRecords);
    list.sort(_compare);
    return list;
  }

  /// Filtered + sorted records grouped by the active [groupBy] key.
  Map<String, List<NotificationRecord>> get groupedRecords {
    final map = <String, List<NotificationRecord>>{};
    for (final r in visibleRecords) {
      final key = _groupKey(r);
      map.putIfAbsent(key, () => []).add(r);
    }
    return map;
  }

  int _compare(NotificationRecord a, NotificationRecord b) {
    switch (_sort) {
      case NotificationSort.dateDesc:
        return b.createdAt.compareTo(a.createdAt);
      case NotificationSort.dateAsc:
        return a.createdAt.compareTo(b.createdAt);
      case NotificationSort.priorityDesc:
        final pa = a.priority?.index ?? -1;
        final pb = b.priority?.index ?? -1;
        if (pa != pb) return pb.compareTo(pa);
        return b.createdAt.compareTo(a.createdAt);
    }
  }

  String _groupKey(NotificationRecord r) {
    switch (_groupBy) {
      case NotificationGroupBy.none:
        return '';
      case NotificationGroupBy.priority:
        return r.priority?.name ?? 'unknown';
      case NotificationGroupBy.category:
        return r.type.name;
      case NotificationGroupBy.date:
        final d = r.createdAt;
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  /// Resolves the in-app route for a record's deep link, or null if unsupported.
  String? routeFor(NotificationRecord r) {
    final deepLink = r.entityType;
    switch (deepLink) {
      case 'site':
        return r.entityId != null ? '/sites/${r.entityId}' : null;
      case 'worker':
        return r.entityId != null ? '/workers/${r.entityId}' : null;
      case 'store_product':
        return '/products';
      default:
        return null;
    }
  }
}

/// Status tabs for the Notification Center.
enum NotificationStatusFilter { all, unread, read, dismissed, archived }

/// Sort options.
enum NotificationSort { dateDesc, dateAsc, priorityDesc }

/// Group-by options.
enum NotificationGroupBy { none, priority, category, date }
