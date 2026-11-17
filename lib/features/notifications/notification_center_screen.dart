import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/models/notification_model.dart';
import '../../core/notifications/providers/notification_center_provider.dart';
import '../../core/notifications/repositories/notification_history_repository.dart';

/// In-app Notification Center. Reads from [NotificationCenterProvider] (a
/// transform layer over the notification history store) and exposes search,
/// status/category filters, sort, grouping, and bulk/per-item actions. Tapping
/// an item navigates to the related entity using the record's deep link.
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationCenterProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationCenterProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (provider.unreadCount > 0)
            TextButton.icon(
              onPressed: provider.markAllRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Mark all read'),
            ),
          PopupMenuButton<NotificationSort>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort',
            onSelected: provider.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: NotificationSort.dateDesc,
                child: Text('Newest first'),
              ),
              PopupMenuItem(
                value: NotificationSort.dateAsc,
                child: Text('Oldest first'),
              ),
              PopupMenuItem(
                value: NotificationSort.priorityDesc,
                child: Text('Priority (high → low)'),
              ),
            ],
          ),
          PopupMenuButton<NotificationGroupBy>(
            icon: const Icon(Icons.account_tree_outlined),
            tooltip: 'Group by',
            onSelected: provider.setGroupBy,
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: NotificationGroupBy.none,
                child: Text('No grouping'),
              ),
              PopupMenuItem(
                value: NotificationGroupBy.priority,
                child: Text('Group by priority'),
              ),
              PopupMenuItem(
                value: NotificationGroupBy.category,
                child: Text('Group by category'),
              ),
              PopupMenuItem(
                value: NotificationGroupBy.date,
                child: Text('Group by date'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Delete all',
            onPressed: () async {
              final ok = await _confirm(
                context,
                'Delete all notifications?',
                'This removes every item from the notification center.',
              );
              if (ok) await provider.deleteAll();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/notifications/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.monitor_heart_outlined),
            tooltip: 'Diagnostics',
            onPressed: () => context.push('/notifications/diagnostics'),
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Business Insights',
            onPressed: () => context.push('/notifications/insights'),
          ),
          ],
      ),
      body: Column(
        children: [
          _SearchAndFilters(provider: provider),
          Expanded(
            child: _buildBody(provider, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NotificationCenterProvider provider, ThemeData theme) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Failed to load: ${provider.error}'));
    }
    if (provider.groupBy == NotificationGroupBy.none) {
      final items = provider.visibleRecords;
      if (items.isEmpty) return _emptyState();
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) =>
            _NotificationTile(record: items[i], provider: provider),
      );
    }
    final groups = provider.groupedRecords;
    if (groups.isEmpty) return _emptyState();
    return ListView(
      children: [
        for (final entry in groups.entries) ...[
          _GroupHeader(title: entry.key, count: entry.value.length),
          for (final r in entry.value)
            _NotificationTile(record: r, provider: provider),
          const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'No notifications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
}

class _SearchAndFilters extends StatelessWidget {
  const _SearchAndFilters({required this.provider});
  final NotificationCenterProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search notifications',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: provider.setQuery,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              for (final s in NotificationStatusFilter.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_statusLabel(s)),
                    selected: provider.statusFilter == s,
                    onSelected: (_) => provider.setStatusFilter(s),
                  ),
                ),
              const VerticalDivider(width: 12),
              for (final c in _categories)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(c)),
                    selected: provider.categoryFilter == c,
                    onSelected: (_) => provider.setCategoryFilter(
                      provider.categoryFilter == c ? null : c,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(NotificationStatusFilter s) => switch (s) {
        NotificationStatusFilter.all => 'All',
        NotificationStatusFilter.unread => 'Unread',
        NotificationStatusFilter.read => 'Read',
        NotificationStatusFilter.dismissed => 'Dismissed',
        NotificationStatusFilter.archived => 'Archived',
      };

  static const _categories = [
    NotificationType.payment,
    NotificationType.payroll,
    NotificationType.inventory,
    NotificationType.worker,
    NotificationType.site,
  ];

  String _categoryLabel(NotificationType c) => switch (c) {
        NotificationType.payment => 'Payment',
        NotificationType.payroll => 'Payroll',
        NotificationType.inventory => 'Inventory',
        NotificationType.worker => 'Worker',
        NotificationType.site => 'Site',
        _ => c.name,
      };
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(120),
        child: Text(
          '$title  ·  $count',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.record,
    required this.provider,
  });
  final NotificationRecord record;
  final NotificationCenterProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priority = record.priority;
    final color = _priorityColor(priority, theme);

    return Dismissible(
      key: ValueKey(record.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 16),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          await provider.markRead(record.id);
          return false; // keep item; just mark read
        }
        await provider.delete(record.id);
        return false;
      },
      child: ListTile(
        leading: Container(
          width: 4,
          height: double.infinity,
          color: color,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                record.title ?? '(no title)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight:
                      record.isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (record.isUnread)
              const Icon(Icons.circle, size: 8, color: Colors.blue),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (record.body != null)
              Text(record.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${_categoryLabel(record.type)} · ${_formatDate(record.createdAt)}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (_) => [
            if (!record.isRead)
              const PopupMenuItem(value: 'read', child: Text('Mark read')),
            if (!record.isArchived)
              const PopupMenuItem(value: 'archive', child: Text('Archive')),
            const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (action) async {
            switch (action) {
              case 'read':
                await provider.markRead(record.id);
              case 'archive':
                await provider.archive(record.id);
              case 'dismiss':
                await provider.dismiss(record.id);
              case 'delete':
                await provider.delete(record.id);
            }
          },
        ),
        onTap: () {
          if (record.isUnread) provider.markRead(record.id);
          final route = provider.routeFor(record);
          if (route != null) context.push(route);
        },
      ),
    );
  }

  Color _priorityColor(NotificationPriority? p, ThemeData theme) {
    switch (p) {
      case NotificationPriority.critical:
        return Colors.red;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.normal:
        return theme.colorScheme.primary;
      case NotificationPriority.low:
        return Colors.grey;
      default:
        return Colors.transparent;
    }
  }

  String _categoryLabel(NotificationType c) => switch (c) {
        NotificationType.payment => 'Payment',
        NotificationType.payroll => 'Payroll',
        NotificationType.inventory => 'Inventory',
        NotificationType.worker => 'Worker',
        NotificationType.site => 'Site',
        _ => c.name,
      };

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(d.year, d.month, d.day))
        .inDays;
    if (diff == 0) return 'Today ${_hm(d)}';
    if (diff == 1) return 'Yesterday';
    return '${d.day}/${d.month}/${d.year}';
  }

  String _hm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

Future<bool> _confirm(
  BuildContext context,
  String title,
  String body,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Wires the Notification Center with its provider. Called from the app shell
/// so the screen always has a repository-backed provider available.
class NotificationCenterScreenWithProvider extends StatelessWidget {
  const NotificationCenterScreenWithProvider({super.key});

  @override
  Widget build(BuildContext context) => FutureBuilder<NotificationHistoryRepository>(
    future: NotificationHistoryRepository.create(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return ChangeNotifierProvider(
        create: (_) => NotificationCenterProvider(repository: snapshot.data!),
        child: const NotificationCenterScreen(),
      );
    },
  );
}
