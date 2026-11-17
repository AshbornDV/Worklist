import '../../models/notification_model.dart';
import '../../models/notification_settings.dart';
import '../../../repositories/inventory_repository.dart';
import 'package:material_ui/material_ui.dart' show TimeOfDay;
import '../../../repositories/payroll_repository.dart';
import '../../../repositories/site_repository.dart';
import '../../../repositories/worker_repository.dart';
import '../notification_rule.dart';

/// Smart notification: a time-gated digest (Morning Briefing / Weekly Summary /
/// Monthly Summary). Unlike the per-entity reminder rules, these aggregate
/// several data slices into ONE summary notification so the user gets an
/// at-a-glance overview instead of N individual alerts.
///
/// Delivery is gated by both the relevant settings toggle (daily/weekly/monthly
/// summary) and a time window derived from [briefingTime]. The engine's dedupe
/// (id includes the period key, e.g. `briefing_daily:2026-07-13`) guarantees at
/// most one briefing per period, so even if the background scheduler runs every
/// 15 minutes the user sees exactly one morning briefing.
class BriefingRule extends NotificationRule {
  BriefingRule({
    required this.mode,
    required this.siteRepository,
    required this.payrollRepository,
    required this.workerRepository,
    required this.inventoryRepository,
    required this.briefingTime,
    this.weeklyWeekday = DateTime.monday,
    this.monthlyDay = 1,
    this.now = _systemNow,
  }) : super(
          id: 'briefing_${mode.name}',
          type: _typeFor(mode),
        );

  static NotificationType _typeFor(BriefingMode m) => switch (m) {
        BriefingMode.daily => NotificationType.dailySummary,
        BriefingMode.weekly => NotificationType.weeklySummary,
        BriefingMode.monthly => NotificationType.monthlySummary,
      };

  final BriefingMode mode;
  final SiteRepository siteRepository;
  final PayrollRepository payrollRepository;
  final WorkerRepository workerRepository;
  final InventoryRepository inventoryRepository;
  final TimeOfDay briefingTime;
  final int weeklyWeekday;
  final int monthlyDay;
  final DateTime Function() now;

  static DateTime _systemNow() => DateTime.now();

  /// Stable dedupe id: one briefing per period.
  String get _periodKey {
    final n = now();
    switch (mode) {
      case BriefingMode.daily:
        return '${n.year}-${n.month}-${n.day}';
      case BriefingMode.weekly:
        return '${n.year}-W${_weekNumber(n)}';
      case BriefingMode.monthly:
        return '${n.year}-${n.month}';
    }
  }

  int _weekNumber(DateTime d) {
    final startOfYear = DateTime(d.year, 1, 1);
    final dayOfYear = d.difference(startOfYear).inDays;
    return ((dayOfYear - d.weekday + 10) / 7).floor();
  }

  /// Whether [now] has reached [briefingTime] for the current period.
  bool get _timeReached {
    final n = now();
    final minutesNow = n.hour * 60 + n.minute;
    final minutesSet = briefingTime.hour * 60 + briefingTime.minute;
    return minutesNow >= minutesSet;
  }

  /// Whether today matches the configured cadence (weekday for weekly, day for
  /// monthly). Always true for daily mode.
  bool get _cadenceMatches {
    final n = now();
    switch (mode) {
      case BriefingMode.daily:
        return true;
      case BriefingMode.weekly:
        return n.weekday == weeklyWeekday;
      case BriefingMode.monthly:
        return n.day == monthlyDay;
    }
  }

  @override
  bool isEnabled(NotificationSettings settings) {
    final base = switch (mode) {
      BriefingMode.daily => settings.dailySummary,
      BriefingMode.weekly => settings.weeklySummary,
      BriefingMode.monthly => settings.monthlySummary,
    };
    return settings.masterEnabled && base;
  }

  @override
  Future<List<AppNotification>> evaluate() async {
    if (!_timeReached || !_cadenceMatches) return const [];

    final n = now();
    final today = DateTime(n.year, n.month, n.day);

    // ── Financial ──
    final sites = await siteRepository.getAllSites();
    final paymentsDue = sites.where((s) => (s.balance) > 0).length;
    final draftPayroll = await payrollRepository.getPayrollForMonth(n);
    final payrollPending = draftPayroll.where((p) => p.status == 'draft').length;

    // ── Sites ──
    final nearingCompletion = sites
        .where((s) =>
            s.completionPercentage >= 90 && s.completionPercentage < 100)
        .length;
    final overdueSites = sites
        .where((s) =>
            s.endDate != null &&
            s.endDate!.isBefore(today) &&
            (s.status != 'archived'))
        .length;

    // ── Workers / Productivity ──
    var workersAbsent = 0;
    final activeSites = sites.where((s) => s.status != 'archived').toList();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    for (final site in activeSites) {
      final assigned = await siteRepository.getWorkersBySite(site.id!);
      for (final w in assigned) {
        final att = await workerRepository.getAttendance(w.id!, dateStr);
        if (att == null || att.isAbsent) workersAbsent++;
      }
    }

    // ── Inventory ──
    final lowStock = (await inventoryRepository.getStockAlertProducts()).length;

    final sections = <String>[
      'Financial: $paymentsDue payment(s) due, $payrollPending payroll pending',
      'Sites: $nearingCompletion nearing completion'
          '${overdueSites > 0 ? ', $overdueSites overdue' : ''}',
      'Productivity: $workersAbsent worker(s) absent today',
      'Inventory: $lowStock item(s) low on stock',
    ];

    final (title, type) = switch (mode) {
      BriefingMode.daily => ("Today's Briefing", NotificationType.dailySummary),
      BriefingMode.weekly => ('Weekly Summary', NotificationType.weeklySummary),
      BriefingMode.monthly =>
        ('Monthly Summary', NotificationType.monthlySummary),
    };

    return [
      AppNotification(
        id: '${id}_$_periodKey',
        title: title,
        body: sections.join('\n'),
        type: type,
        priority: NotificationPriority.normal,
        createdAt: n,
        entityType: 'briefing',
        payload: {
          'rule': id,
          'mode': mode.name,
          'period': _periodKey,
        },
      ),
    ];
  }
}

/// Cadence for a [BriefingRule].
enum BriefingMode { daily, weekly, monthly }
