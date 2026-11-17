import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/database_helper.dart';
import '../../core/notifications/models/notification_model.dart';
import '../../core/notifications/repositories/notification_history_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../dashboard/dashboard_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// V2.0 — Calendar module.
//
// 100% read-only, derived entirely from existing on-device data. No schema,
// sync, or business-logic changes. Every event carries a deterministic id so
// the same underlying record can never produce a duplicate calendar event.
//
// NOTE: "Service schedules" are intentionally omitted — SiteService/UserService
// carry no date field, so a service event cannot be derived without fabricating
// a date. All other requested categories map to real existing dates.
// ─────────────────────────────────────────────────────────────────────────────

enum CalCategory {
  attendance,
  payroll,
  payment,
  material,
  stock,
  siteStart,
  siteDue,
  reminder,
}

extension CalCategoryX on CalCategory {
  String get label {
    switch (this) {
      case CalCategory.attendance:
        return 'Attendance';
      case CalCategory.payroll:
        return 'Payroll';
      case CalCategory.payment:
        return 'Payments';
      case CalCategory.material:
        return 'Materials';
      case CalCategory.stock:
        return 'Stock';
      case CalCategory.siteStart:
        return 'Site Start';
      case CalCategory.siteDue:
        return 'Site Due';
      case CalCategory.reminder:
        return 'Reminders';
    }
  }

  IconData get icon {
    switch (this) {
      case CalCategory.attendance:
        return Icons.fact_check_outlined;
      case CalCategory.payroll:
        return Icons.account_balance_wallet_outlined;
      case CalCategory.payment:
        return Icons.payments_outlined;
      case CalCategory.material:
        return Icons.local_shipping_outlined;
      case CalCategory.stock:
        return Icons.inventory_2_outlined;
      case CalCategory.siteStart:
        return Icons.flag_outlined;
      case CalCategory.siteDue:
        return Icons.event_repeat_outlined;
      case CalCategory.reminder:
        return Icons.notifications_outlined;
    }
  }

  Color color(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    switch (this) {
      case CalCategory.attendance:
        return cs.primary;
      case CalCategory.payroll:
        return const Color(0xFF6A1B9A);
      case CalCategory.payment:
        return const Color(0xFF2E7D32);
      case CalCategory.material:
        return const Color(0xFF0288D1);
      case CalCategory.stock:
        return const Color(0xFFF57C00);
      case CalCategory.siteStart:
        return const Color(0xFF00796B);
      case CalCategory.siteDue:
        return const Color(0xFFC2185B);
      case CalCategory.reminder:
        return cs.tertiary;
    }
  }
}

enum CalSeverity { normal, attention, critical }

/// A single derived calendar event. [id] is deterministic per source record so
/// duplicates are impossible.
class CalEvent {
  CalEvent({
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.subtitle,
    this.deepLink,
    this.severity = CalSeverity.normal,
  });

  final String id;
  final DateTime date;
  final CalCategory category;
  final String title;
  final String subtitle;
  final String? deepLink;
  final CalSeverity severity;

  DateTime get day => DateTime(date.year, date.month, date.day);
}

enum CalView { month, week, day }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _db = DatabaseHelper();

  bool _loading = true;
  Object? _error;

  List<CalEvent> _events = [];
  final _allCategories = CalCategory.values;

  CalView _view = CalView.month;
  DateTime _focusedDay = _today();

  final Set<CalCategory> _activeFilters = {};
  final _searchCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  List<CalEvent> get _visibleEvents {
    final q = _searchCtl.text.trim().toLowerCase();
    return _events.where((e) {
      if (_activeFilters.isNotEmpty && !_activeFilters.contains(e.category)) {
        return false;
      }
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.subtitle.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<CalEvent> _eventsOnDay(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return _visibleEvents
        .where((e) => e.day == d)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await _buildEvents();
      if (!mounted) return;
      setState(() {
        _events = events;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<List<CalEvent>> _buildEvents() async {
    final out = <String, CalEvent>{};
    final today = _today();
    final monthStart = DateTime(today.year, today.month, 1);
    final monthEnd = DateTime(today.year, today.month + 1, 0);

    // 1) Worker attendance (read-only range query for the focused month).
    final attRows = await _db.getAttendanceInRange(
      _iso(monthStart),
      _iso(monthEnd),
    );
    for (final r in attRows) {
      final date = DateTime.tryParse(r['date'] as String? ?? '');
      if (date == null) continue;
      final workerId = (r['worker_id'] as num?)?.toInt();
      final name = (r['worker_name'] as String?) ?? 'Worker';
      final type = (r['type'] as String?) ?? '';
      final id = 'att:$workerId:${r['date']}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: date,
        category: CalCategory.attendance,
        title: '$name — ${_attendanceLabel(type)}',
        subtitle: _attendanceSubtitle(type),
        deepLink: workerId != null ? '/workers/$workerId' : null,
        severity: type == 'absent' ? CalSeverity.attention : CalSeverity.normal,
      );
    }

    // 2) Payroll due dates (end of each payroll month).
    final payroll = await _db.getPayrollForMonth(today);
    for (final p in payroll) {
      final month = p.month;
      final due = DateTime(month.year, month.month + 1, 0);
      final id = 'payroll:${p.workerId}:${month.year}-${month.month}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: due,
        category: CalCategory.payroll,
        title: 'Payroll due — ${p.workerName}',
        subtitle: p.isPaid
            ? 'Paid · Rs. ${_fmt(p.netSalary)}'
            : 'Net Rs. ${_fmt(p.netSalary)} (${p.status})',
        deepLink: '/payroll',
        severity: p.isPaid ? CalSeverity.normal : CalSeverity.attention,
      );
    }

    // 3) Customer payment due dates (last paid + reminder window).
    final sites = await _db.getAllSites();
    for (final s in sites) {
      if (s.lastPaidDate == null || !s.hasRemainingPayment) continue;
      final due = s.lastPaidDate!.add(Duration(days: s.collectionReminderDays));
      final id = 'paydue:${s.id}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: due,
        category: CalCategory.payment,
        title: 'Payment due — ${s.name}',
        subtitle: 'Rs. ${_fmt(s.balance)} receivable',
        deepLink: s.id != null ? '/sites/${s.id}' : null,
        severity: due.isBefore(today) ? CalSeverity.critical : CalSeverity.attention,
      );
    }

    // 4) Material reminders (product delivery dates).
    final products = await _db.getAllProducts();
    for (final p in products) {
      if (p.deliveryDate == null) continue;
      final id = 'material:${p.id}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: p.deliveryDate!,
        category: CalCategory.material,
        title: 'Material arriving — ${p.name}',
        subtitle: 'Expected delivery',
        deepLink: '/products',
      );
    }

    // 5) Low / critical stock reminders (anchored to today — standing reminder).
    final stock = await _db.getAllStoreProducts();
    for (final p in stock) {
      if (!p.isLowStock && !p.isCriticalStock) continue;
      final id = 'stock:${p.id}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: today,
        category: CalCategory.stock,
        title: '${p.isCriticalStock ? 'Critical' : 'Low'} stock — ${p.name}',
        subtitle: '${p.stock.toStringAsFixed(0)} left '
            '(threshold ${p.lowStockThreshold.toStringAsFixed(0)})',
        deepLink: '/products',
        severity: p.isCriticalStock ? CalSeverity.critical : CalSeverity.attention,
      );
    }

    // 6) Site start dates + 7) completion estimates.
    for (final s in sites) {
      if (s.startDate != null) {
        final id = 'sitestart:${s.id}';
        if (!out.containsKey(id)) {
          out[id] = CalEvent(
            id: id,
            date: s.startDate!,
            category: CalCategory.siteStart,
            title: 'Site started — ${s.name}',
            subtitle: s.area,
            deepLink: s.id != null ? '/sites/${s.id}' : null,
          );
        }
      }
      if (s.endDate != null && s.status != 'completed') {
        final id = 'sitedue:${s.id}';
        if (!out.containsKey(id)) {
          out[id] = CalEvent(
            id: id,
            date: s.endDate!,
            category: CalCategory.siteDue,
            title: 'Site due — ${s.name}',
            subtitle: '${s.completionPercentage.toStringAsFixed(0)}% complete',
            deepLink: s.id != null ? '/sites/${s.id}' : null,
            severity: s.endDate!.isBefore(today)
                ? CalSeverity.critical
                : CalSeverity.attention,
          );
        }
      }
    }

    // 8) Notification reminders (future-snoozed, not dismissed).
    final repo = await NotificationHistoryRepository.create();
    final records = await repo.getAll();
    for (final rec in records) {
      final at = rec.snoozedAt;
      if (at == null || at.isBefore(today) || rec.isDismissed) continue;
      final id = 'reminder:${rec.id}';
      if (out.containsKey(id)) continue;
      out[id] = CalEvent(
        id: id,
        date: at,
        category: CalCategory.reminder,
        title: rec.title ?? 'Reminder',
        subtitle: rec.body ?? '',
        deepLink: '/notifications',
        severity: rec.priority == NotificationPriority.critical
            ? CalSeverity.critical
            : CalSeverity.normal,
      );
    }

    return out.values.toList();
  }

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _attendanceLabel(String type) {
    switch (type) {
      case 'full':
        return 'Full day';
      case 'half':
        return 'Half day';
      case 'absent':
        return 'Absent';
      default:
        return type;
    }
  }

  String _attendanceSubtitle(String type) =>
      type == 'absent' ? 'Marked absent' : 'Present';

  String _fmt(double v) {
    final s = v.toStringAsFixed(0);
    final buffer = StringBuffer();
    var count = 0;
    for (var i = s.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(',');
      buffer.write(s[i]);
      count++;
    }
    return buffer.toString().split('').reversed.join();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Calendar'),
        backgroundColor: cs.surface,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () =>
                      RootScaffoldKey.of(ctx)?.currentState?.openEndDrawer(),
                ),
              ),
        actions: [
          SegmentedButton<CalView>(
            selected: {_view},
            onSelectionChanged: (s) => setState(() => _view = s.first),
            segments: const [
              ButtonSegment(value: CalView.month, label: Text('Month')),
              ButtonSegment(value: CalView.week, label: Text('Week')),
              ButtonSegment(value: CalView.day, label: Text('Day')),
            ],
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(onRetry: _load)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _FilterBar(
          categories: _allCategories,
          active: _activeFilters,
          onToggle: (c) => setState(() {
            if (_activeFilters.contains(c)) {
              _activeFilters.remove(c);
            } else {
              _activeFilters.add(c);
            }
          }),
          searchCtl: _searchCtl,
          onSearch: () => setState(() {}),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _view == CalView.month
                ? _MonthView(
                    key: const ValueKey('month'),
                    focused: _focusedDay,
                    events: _visibleEvents,
                    onPage: (d) => setState(() => _focusedDay = d),
                    onTapDay: (d) => setState(() {
                      _focusedDay = d;
                      _view = CalView.day;
                    }),
                  )
                : _view == CalView.week
                    ? _WeekView(
                        key: const ValueKey('week'),
                        focused: _focusedDay,
                        events: _visibleEvents,
                        onDaySelected: (d) => setState(() => _focusedDay = d),
                      )
                    : _DayView(
                        key: const ValueKey('day'),
                        day: _focusedDay,
                        events: _eventsOnDay(_focusedDay),
                        onPrev: () => setState(
                            () => _focusedDay = _focusedDay.subtract(const Duration(days: 1))),
                        onNext: () => setState(
                            () => _focusedDay = _focusedDay.add(const Duration(days: 1))),
                      ),
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Filter bar ─────────────────────────

class _FilterBar extends StatelessWidget {
  final List<CalCategory> categories;
  final Set<CalCategory> active;
  final ValueChanged<CalCategory> onToggle;
  final TextEditingController searchCtl;
  final VoidCallback onSearch;

  const _FilterBar({
    required this.categories,
    required this.active,
    required this.onToggle,
    required this.searchCtl,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: searchCtl,
            onChanged: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search events…',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: searchCtl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchCtl.clear();
                        onSearch();
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = categories[i];
                final on = active.isEmpty || active.contains(c);
                final color = c.color(context);
                return FilterChip(
                  selected: active.contains(c),
                  showCheckmark: false,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c.icon, size: 16,
                          color: on ? color : color.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(c.label),
                    ],
                  ),
                  selectedColor: color.withValues(alpha: 0.18),
                  side: BorderSide(
                      color: color.withValues(alpha: on ? 0.6 : 0.25)),
                  onSelected: (_) => onToggle(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Month view ─────────────────────────

class _MonthView extends StatelessWidget {
  final DateTime focused;
  final List<CalEvent> events;
  final ValueChanged<DateTime> onPage;
  final ValueChanged<DateTime> onTapDay;

  const _MonthView({
    required this.focused,
    required this.events,
    required this.onPage,
    required this.onTapDay,
    super.key,
  });

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthName(int m) => const [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final first = DateTime(focused.year, focused.month, 1);
    final startWeekday = first.weekday % 7;
    final daysInMonth = DateTime(focused.year, focused.month + 1, 0).day;
    final totalCells = ((startWeekday + daysInMonth) / 7).ceil() * 7;

    final byDay = <String, List<CalEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(_key(e.day), () => []).add(e);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () =>
                    onPage(DateTime(focused.year, focused.month - 1, 1)),
              ),
              Expanded(
                child: Text(
                  '${_monthName(focused.month)} ${focused.year}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () =>
                    onPage(DateTime(focused.year, focused.month + 1, 1)),
              ),
            ],
          ),
        ),
        _WeekdayHeader(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: totalCells,
            itemBuilder: (context, i) {
              final dayOffset = i - startWeekday;
              final day = DateTime(focused.year, focused.month, 1)
                  .add(Duration(days: dayOffset));
              final inMonth = day.month == focused.month;
              final isToday = _isSameDay(day, DateTime.now());
              final dayEvents = byDay[_key(day)] ?? [];

              return InkWell(
                onTap: () => onTapDay(day),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? cs.primaryContainer : null,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.3),
                      width: isToday ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 6),
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: inMonth
                                ? (isToday ? cs.primary : cs.onSurface)
                                : cs.onSurface.withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Wrap(
                            spacing: 2,
                            runSpacing: 2,
                            children: dayEvents.take(4).map((e) {
                              return Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: e.category.color(context),
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: labels
            .map((l) => Expanded(
                  child: Center(
                    child: Text(
                      l,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ───────────────────────── Week view ─────────────────────────

class _WeekView extends StatelessWidget {
  final DateTime focused;
  final List<CalEvent> events;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekView({
    required this.focused,
    required this.events,
    required this.onDaySelected,
    super.key,
  });

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  String _dayLabel(DateTime d) {
    const names = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    return '${names[d.weekday % 7]}, ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final weekStart = focused.subtract(Duration(days: focused.weekday % 7));
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final byDay = <String, List<CalEvent>>{};
    for (final e in events) {
      byDay.putIfAbsent(_key(e.day), () => []).add(e);
    }

    return Column(
      children: [
        _WeekStrip(days: days, focused: focused, onDaySelected: onDaySelected),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final day = days[i];
              final evs = (byDay[_key(day)] ?? [])
                ..sort((a, b) => a.date.compareTo(b.date));
              final isToday = _isSameDay(day, DateTime.now());
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isToday ? cs.primary : cs.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isToday ? cs.onPrimary : cs.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _dayLabel(day),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (evs.isEmpty)
                        Text('No events',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: cs.onSurface.withValues(alpha: 0.5)))
                      else
                        ...evs.map((e) => _EventTile(event: e, compact: true)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  final List<DateTime> days;
  final DateTime focused;
  final ValueChanged<DateTime> onDaySelected;

  const _WeekStrip({
    required this.days,
    required this.focused,
    required this.onDaySelected,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: days
            .map((d) {
              final isToday = d.year == DateTime.now().year &&
                  d.month == DateTime.now().month &&
                  d.day == DateTime.now().day;
              final isSel = _isSameDay(d, focused);
              return Expanded(
                child: InkWell(
                  onTap: () => onDaySelected(d),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? cs.primary : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          const ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
                          style: TextStyle(
                            fontSize: 11,
                            color: isSel ? cs.onPrimary : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? cs.onPrimary
                                : (isToday ? cs.primary : cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            })
            .toList(),
      ),
    );
  }
}

// ───────────────────────── Day view ─────────────────────────

class _DayView extends StatelessWidget {
  final DateTime day;
  final List<CalEvent> events;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _DayView({
    required this.day,
    required this.events,
    required this.onPrev,
    required this.onNext,
    super.key,
  });

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _label(DateTime d) {
    const names = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${names[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _isSameDay(day, DateTime.now());
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
              Expanded(
                child: Text(
                  _label(day),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
            ],
          ),
        ),
        if (isToday)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _AgendaCard(events: events),
          ),
        Expanded(
          child: events.isEmpty
              ? const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Nothing scheduled',
                  subtitle: 'No events derived for this day.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _EventTile(event: events[i]),
                ),
        ),
      ],
    );
  }
}

// ───────────────────────── Shared widgets ─────────────────────────

/// Today's agenda + 7-day timeline.
class _AgendaCard extends StatelessWidget {
  final List<CalEvent> events;
  const _AgendaCard({required this.events});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayEvents = events
        .where((e) =>
            e.day.year == today.year &&
            e.day.month == today.month &&
            e.day.day == today.day)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final byDay = <String, int>{};
    for (final e in events) {
      byDay[_key(e.day)] = (byDay[_key(e.day)] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          color: cs.primaryContainer.withValues(alpha: 0.5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today_outlined, color: cs.primary),
                    const SizedBox(width: 8),
                    Text('Today',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${todayEvents.length} event(s)',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                if (todayEvents.isEmpty)
                  Text('All clear today.',
                      style: Theme.of(context).textTheme.bodySmall)
                else
                  ...todayEvents.take(4).map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: e.category.color(context),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall),
                            ),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final d = weekDays[i];
              final count = byDay[_key(d)] ?? 0;
              final isToday = d.day == today.day &&
                  d.month == today.month &&
                  d.year == today.year;
              return Container(
                width: 64,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isToday ? cs.primary : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      const ['S', 'M', 'T', 'W', 'T', 'F', 'S'][d.weekday % 7],
                      style: TextStyle(
                        fontSize: 11,
                        color: isToday ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                    Text(
                      '${d.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? cs.onPrimary : cs.onSurface,
                      ),
                    ),
                    if (count > 0)
                      Text('$count',
                          style: TextStyle(
                            fontSize: 10,
                            color: isToday ? cs.onPrimary : cs.primary,
                          )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

class _EventTile extends StatelessWidget {
  final CalEvent event;
  final bool compact;
  const _EventTile({required this.event, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event.category.color(context);
    final leading = Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(event.category.icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  event.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!compact) const Icon(Icons.chevron_right, size: 18),
        ],
      ),
    );

    final card = Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [leading, Expanded(child: content)],
      ),
    );

    return event.deepLink != null
        ? InkWell(
            onTap: () => GoRouter.of(context).push(event.deepLink!),
            child: card,
          )
        : card;
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 56, color: cs.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Could not load calendar',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
