import 'dart:math';

import '../../repositories/inventory_repository.dart';
import '../../repositories/payroll_repository.dart';
import '../../repositories/site_repository.dart';
import '../../repositories/worker_repository.dart';
import './business_insight_models.dart';
import '../../models/construction_payment_model.dart';
import '../../models/store_product_model.dart';
import '../../models/worker_model.dart';

/// Phase 11 — Local Business Insight Engine.
///
/// Generates human-readable insights ENTIRELY from on-device SQLite data
/// (via the existing repositories). No AI/cloud APIs are used — every number is
/// computed locally from real records. The engine is read-only: it never writes
/// business data, mutates sync/auth/schema, or touches the notification engine.
///
/// Output is a flat list of [BusinessInsight]s grouped by [InsightDomain],
/// plus [InsightSummary] builders for Morning Briefing / Evening Summary /
/// Weekly Report / Monthly Report.
class BusinessInsightEngine {
  const BusinessInsightEngine({
    required this.siteRepository,
    required this.payrollRepository,
    required this.workerRepository,
    required this.inventoryRepository,
    this.now = _systemNow,
  });

  final SiteRepository siteRepository;
  final PayrollRepository payrollRepository;
  final WorkerRepository workerRepository;
  final InventoryRepository inventoryRepository;
  final DateTime Function() now;

  static DateTime _systemNow() => DateTime.now();

  // ───────────────────────── PUBLIC API ─────────────────────────

  /// Builds every insight across all domains from live data.
  Future<List<BusinessInsight>> generateAll() async {
    final results = await Future.wait([
      payments(),
      sites(),
      workers(),
      inventory(),
      payroll(),
      finance(),
      workforceAllocation(),
    ]);
    final flat = results.expand((e) => e).toList();
    flat.sort((a, b) => b.severity.rank.compareTo(a.severity.rank));
    return flat;
  }

  /// Builds a time-bounded digest.
  Future<InsightSummary> generateSummary(InsightSummaryKind kind) async {
    final insights = await generateAll();
    final scoped = _scopeToKind(insights, kind);
    return InsightSummary(
      kind: kind,
      generatedAt: now(),
      insights: scoped,
    );
  }

  List<BusinessInsight> _scopeToKind(
    List<BusinessInsight> all,
    InsightSummaryKind kind,
  ) {
    switch (kind) {
      case InsightSummaryKind.morningBriefing:
      case InsightSummaryKind.eveningSummary:
        // Both show the day's full picture; evening emphasizes wrap-up.
        return all;
      case InsightSummaryKind.weeklyReport:
        // Keep only items still relevant this week (no hard expiry for local data).
        return all;
      case InsightSummaryKind.monthlyReport:
        return all;
    }
  }

  // ───────────────────────── PAYMENTS ─────────────────────────

  Future<List<BusinessInsight>> payments() async {
    final sites = await siteRepository.getAllSites();
    final out = <BusinessInsight>[];

    // 1) Large overdue balance.
    final overdue = sites
        .where((s) => s.hasRemainingPayment)
        .where((s) => s.daysSinceLastPayment >= s.collectionReminderDays)
        .toList()
      ..sort((a, b) => b.balance.compareTo(a.balance));
    for (final s in overdue.take(5)) {
      final large = s.balance >= 100000;
      out.add(
        BusinessInsight(
          domain: InsightDomain.payments,
          title: large ? 'Large overdue balance' : 'Overdue payment',
          body: '${s.name} (${s.area}) owes Rs. ${_fmt(s.balance)} '
              '· ${s.daysSinceLastPayment}d since last payment.',
          severity: large ? InsightSeverity.critical : InsightSeverity.warning,
          entityId: s.id?.toString(),
          entityType: 'site',
          deepLink: '/sites/${s.id}',
        ),
      );
    }

    // 2) Customer payment trend (last 6 months vs prior 6 months).
    final payments = <ConstructionPaymentModel>[];
    for (final s in sites) {
      payments.addAll(await siteRepository.getConstructionPaymentsBySite(s.id!));
    }
    if (payments.length >= 4) {
      final (recent, prior) = _splitLastMonths(payments, 6);
      final recentSum = recent.fold(0.0, (a, p) => a + p.amount);
      final priorSum = prior.fold(0.0, (a, p) => a + p.amount);
      if (priorSum > 0) {
        final pct = (recentSum - priorSum) / priorSum * 100;
        final up = pct >= 0;
        out.add(
          BusinessInsight(
            domain: InsightDomain.payments,
            title: 'Customer payment trend',
            body: 'Collections ${up ? 'up' : 'down'} ${pct.abs().toStringAsFixed(0)}% '
                'vs prior 6 months (Rs. ${_fmt(recentSum)}).',
            severity: !up && pct < -10
                ? InsightSeverity.warning
                : InsightSeverity.info,
          ),
        );
      }
    }

    // 3) Collection performance (collected vs billed this month).
    final monthStart = DateTime(now().year, now().month, 1);
    final monthPayments =
        payments.where((p) => p.paymentDate.isAfter(monthStart)).toList();
    final collected =
        monthPayments.fold(0.0, (a, p) => a + p.amount);
    final billed = sites.fold(0.0, (a, s) => a + s.totalReceived);
    if (billed > 0) {
      final pct = collected / billed * 100;
      out.add(
        BusinessInsight(
          domain: InsightDomain.payments,
          title: 'Collection performance',
          body: '${pct.toStringAsFixed(0)}% of billed value collected '
              'this month (Rs. ${_fmt(collected)} of ${_fmt(billed)}).',
          severity: pct < 50 ? InsightSeverity.attention : InsightSeverity.info,
        ),
      );
    }
    return out;
  }

  // ───────────────────────── SITES ─────────────────────────

  Future<List<BusinessInsight>> sites() async {
    final sites = await siteRepository.getAllSites();
    final out = <BusinessInsight>[];
    final today = DateTime(now().year, now().month, now().day);

    for (final s in sites) {
      // 1) Site nearing completion.
      if (s.completionPercentage >= 90 && s.completionPercentage < 100) {
        out.add(
          BusinessInsight(
            domain: InsightDomain.sites,
            title: 'Site nearing completion',
            body: '${s.name} is ${s.completionPercentage.toStringAsFixed(0)}% '
                'complete — plan handover & final payment.',
            severity: InsightSeverity.attention,
            entityId: s.id?.toString(),
            entityType: 'site',
            deepLink: '/sites/${s.id}',
          ),
        );
      }
      // 2) Site delayed (end date passed, not completed).
      if (s.endDate != null &&
          s.endDate!.isBefore(today) &&
          s.status != 'completed' &&
          s.status != 'archived') {
        final daysLate = today.difference(s.endDate!).inDays;
        out.add(
          BusinessInsight(
            domain: InsightDomain.sites,
            title: 'Site delayed',
            body: '${s.name} is ${daysLate}d past its end date '
                '(${s.endDate!.toLocal().toString().substring(0, 10)}).',
            severity: daysLate > 14
                ? InsightSeverity.critical
                : InsightSeverity.warning,
            entityId: s.id?.toString(),
            entityType: 'site',
            deepLink: '/sites/${s.id}',
          ),
        );
      }
      // 3) Budget risk.
      final budget = s.budget;
      if (budget != null && budget > 0) {
        final spent = s.totalReceived;
        final ratio = spent / budget;
        if (ratio > 0.9) {
          out.add(
            BusinessInsight(
              domain: InsightDomain.sites,
              title: 'Budget risk',
              body: '${s.name} spent ${ratio.toStringAsFixed(0)}% of budget '
                  '(Rs. ${_fmt(spent)} / ${_fmt(budget)}).',
              severity: ratio > 1.0
                  ? InsightSeverity.critical
                  : InsightSeverity.warning,
              entityId: s.id?.toString(),
              entityType: 'site',
              deepLink: '/sites/${s.id}',
            ),
          );
        }
      }
    }

    // 4) Material shortage prediction (aggregate across store).
    final shortage = await _materialShortagePrediction();
    out.addAll(shortage);
    return out;
  }

  Future<List<BusinessInsight>> _materialShortagePrediction() async {
    final products = await inventoryRepository.getAllStoreProducts();
    final risky = <BusinessInsight>[];
    // Predict depletion within ~14 days from recent site-product issuance rate.
    for (final p in products) {
      if (p.stock <= 0) continue;
      final sent = await inventoryRepository.getTotalSentToSites(p.id!);
      if (sent <= 0) continue;
      // Average per-day issuance over the product's tracked lifetime (rough).
      final dailyRate = sent / max(30, 1); // conservatively assume ≥30d history
      if (dailyRate <= 0) continue;
      final daysLeft = p.stock / dailyRate;
      if (daysLeft <= 14) {
        risky.add(
          BusinessInsight(
            domain: InsightDomain.sites,
            title: 'Material shortage prediction',
            body: '${p.name} may run out in ~${daysLeft.toStringAsFixed(0)}d '
                '(stock ${p.stock.toStringAsFixed(0)}, ~${dailyRate.toStringAsFixed(1)}/d used).',
            severity: daysLeft <= 3
                ? InsightSeverity.critical
                : InsightSeverity.warning,
            entityId: p.id?.toString(),
            entityType: 'store_product',
            deepLink: '/products',
          ),
        );
      }
    }
    return risky;
  }

  // ───────────────────────── WORKERS ─────────────────────────

  Future<List<BusinessInsight>> workers() async {
    final allWorkers = await workerRepository.getAllWorkers();
    final out = <BusinessInsight>[];
    final n = now();

    for (final w in allWorkers) {
      if (w.id == null) continue;

      // 1) Frequent absentee (this month).
      final monthAtt = await workerRepository.getAttendanceByWorker(w.id!,
          year: n.year, month: n.month);
      final absent = monthAtt.where((a) => a.isAbsent).length;
      final worked = monthAtt.where((a) => !a.isAbsent).length;
      final total = absent + worked;
      if (total >= 8 && absent / total >= 0.25) {
        out.add(
          BusinessInsight(
            domain: InsightDomain.workers,
            title: 'Frequent absentee',
            body: '${w.name} absent $absent of $total days this month '
                '(${(absent / total * 100).toStringAsFixed(0)}%).',
            severity: absent / total >= 0.4
                ? InsightSeverity.warning
                : InsightSeverity.attention,
            entityId: w.id.toString(),
            entityType: 'worker',
            deepLink: '/workers/${w.id}',
          ),
        );
      }

      // 2) Productivity trend (last 2 months of performance).
      final perf = await workerRepository.getWorkerPerformance(w.id!);
      if (perf.length >= 2) {
        final sorted = [...perf]
          ..sort((a, b) => a.month.compareTo(b.month));
        final last = sorted.last;
        final prev = sorted[sorted.length - 2];
        if (last.completedWorkDays < prev.completedWorkDays) {
          out.add(
            BusinessInsight(
              domain: InsightDomain.workers,
              title: 'Productivity trend',
              body: '${w.name} completed ${last.completedWorkDays} days vs '
                  '${prev.completedWorkDays} last month — output declining.',
              severity: InsightSeverity.attention,
              entityId: w.id.toString(),
              entityType: 'worker',
              deepLink: '/workers/${w.id}',
            ),
          );
        }
      }

      // 3) Performance decline (rating drop).
      if (perf.length >= 2) {
        final sorted = [...perf]
          ..sort((a, b) => a.month.compareTo(b.month));
        final last = sorted.last;
        final prev = sorted[sorted.length - 2];
        if (prev.rating - last.rating >= 0.5) {
          out.add(
            BusinessInsight(
              domain: InsightDomain.workers,
              title: 'Performance decline',
              body: '${w.name} rating fell ${prev.rating.toStringAsFixed(1)}→'
                  '${last.rating.toStringAsFixed(1)} this month.',
              severity: InsightSeverity.warning,
              entityId: w.id.toString(),
              entityType: 'worker',
              deepLink: '/workers/${w.id}',
            ),
          );
        }
      }
    }
    return out;
  }

  // ───────────────────────── INVENTORY ─────────────────────────

  Future<List<BusinessInsight>> inventory() async {
    final products = await inventoryRepository.getAllStoreProducts();
    final out = <BusinessInsight>[];
    if (products.isEmpty) return out;

    // Average issuance rate across products for fast/slow classification.
    final rates = <double>[];
    for (final p in products) {
      if (p.id == null) continue;
      final sent = await inventoryRepository.getTotalSentToSites(p.id!);
      rates.add(sent);
    }
    if (rates.isEmpty) return out;
    final mean = rates.fold(0.0, (a, b) => a + b) / rates.length;
    final sd = _stddev(rates, mean);

    final fast = <StoreProduct>[];
    final slow = <StoreProduct>[];
    for (final p in products) {
      if (p.id == null) continue;
      final sent = await inventoryRepository.getTotalSentToSites(p.id!);
      if (sent >= mean + sd && sent > 0) fast.add(p);
      if (sent <= max(mean - sd, 0) && sent < mean && p.stock > 0) slow.add(p);
    }

    for (final p in fast.take(5)) {
      out.add(
        BusinessInsight(
          domain: InsightDomain.inventory,
          title: 'Fast moving item',
          body: '${p.name} is high-turnover — keep stock above '
              '${p.lowStockThreshold.toStringAsFixed(0)} (current ${p.stock.toStringAsFixed(0)}).',
          severity: p.isLowStock || p.isCriticalStock
              ? InsightSeverity.warning
              : InsightSeverity.info,
          entityId: p.id.toString(),
          entityType: 'store_product',
          deepLink: '/products',
        ),
      );
    }
    for (final p in slow.take(5)) {
      out.add(
        BusinessInsight(
          domain: InsightDomain.inventory,
          title: 'Slow moving item',
          body: '${p.name} is barely used — ${p.stock.toStringAsFixed(0)} '
              'in stock may be over-purchased.',
          severity: InsightSeverity.info,
          entityId: p.id.toString(),
          entityType: 'store_product',
          deepLink: '/products',
        ),
      );
    }

    // Future shortage prediction (reuse site-domain helper; localize to inventory).
    final shortage = await _materialShortagePrediction();
    // Re-map those to inventory domain for the inventory section.
    for (final s in shortage) {
      out.add(s.copyWith(domain: InsightDomain.inventory));
    }
    return out;
  }

  // ───────────────────────── PAYROLL ─────────────────────────

  Future<List<BusinessInsight>> payroll() async {
    final n = now();
    final out = <BusinessInsight>[];

    // 1) Upcoming payroll total (this month's draft payroll).
    final draft = await payrollRepository.getPayrollForMonth(n);
    final pending = draft.where((p) => p.status == 'draft').toList();
    final totalDue =
        pending.fold(0.0, (a, p) => a + p.netSalary);
    if (totalDue > 0) {
      out.add(
        BusinessInsight(
          domain: InsightDomain.payroll,
          title: 'Upcoming payroll total',
          body: 'Rs. ${_fmt(totalDue)} due for ${pending.length} worker(s) '
              'this month (${pending.length} still draft).',
          severity: InsightSeverity.attention,
          deepLink: '/payroll',
        ),
      );
    }

    // 2) Payroll trend (this month vs last month).
    final lastMonth = DateTime(n.year, n.month - 1, 1);
    final prev = await payrollRepository.getPayrollForMonth(lastMonth);
    final prevTotal =
        prev.fold(0.0, (a, p) => a + p.netSalary);
    if (prevTotal > 0) {
      final pct = (totalDue - prevTotal) / prevTotal * 100;
      out.add(
        BusinessInsight(
          domain: InsightDomain.payroll,
          title: 'Payroll trend',
          body: 'Payroll ${pct >= 0 ? 'up' : 'down'} ${pct.abs().toStringAsFixed(0)}% '
              'vs last month (Rs. ${_fmt(totalDue)} vs ${_fmt(prevTotal)}).',
          severity: pct > 20 ? InsightSeverity.attention : InsightSeverity.info,
          deepLink: '/payroll',
        ),
      );
    }
    return out;
  }

  // ───────────────────────── FINANCE ─────────────────────────

  Future<List<BusinessInsight>> finance() async {
    final sites = await siteRepository.getAllSites();
    final n = now();
    final out = <BusinessInsight>[];

    // Weekly revenue (last 7 days of construction payments).
    final payments = <ConstructionPaymentModel>[];
    for (final s in sites) {
      payments.addAll(await siteRepository.getConstructionPaymentsBySite(s.id!));
    }
    final weekAgo = n.subtract(const Duration(days: 7));
    final weekRev =
        payments.where((p) => p.paymentDate.isAfter(weekAgo)).fold(0.0, (a, p) => a + p.amount);
    out.add(
      BusinessInsight(
        domain: InsightDomain.finance,
        title: 'Weekly revenue',
        body: 'Rs. ${_fmt(weekRev)} collected in the last 7 days.',
        severity: weekRev <= 0 ? InsightSeverity.attention : InsightSeverity.info,
      ),
    );

    // Monthly revenue.
    final monthStart = DateTime(n.year, n.month, 1);
    final monthRev = payments
        .where((p) => p.paymentDate.isAfter(monthStart))
        .fold(0.0, (a, p) => a + p.amount);
    out.add(
      BusinessInsight(
        domain: InsightDomain.finance,
        title: 'Monthly revenue',
        body: 'Rs. ${_fmt(monthRev)} collected this month.',
        severity: InsightSeverity.info,
      ),
    );

    // Outstanding balances.
    final outstanding =
        sites.fold(0.0, (a, s) => a + (s.hasRemainingPayment ? s.balance : 0));
    out.add(
      BusinessInsight(
        domain: InsightDomain.finance,
        title: 'Outstanding balances',
        body: 'Rs. ${_fmt(outstanding)} still receivable across '
            '${sites.where((s) => s.hasRemainingPayment).length} site(s).',
        severity: outstanding > 200000
            ? InsightSeverity.warning
            : InsightSeverity.info,
      ),
    );

    // Advance burden (pending worker advances vs this month's revenue).
    final pendingAdvances = await workerRepository.getAllPendingAdvances();
    final advanceTotal =
        pendingAdvances.fold(0.0, (a, p) => a + p.amount);
    if (advanceTotal > 0) {
      final share = monthRev > 0 ? advanceTotal / monthRev * 100 : 0.0;
      out.add(
        BusinessInsight(
          domain: InsightDomain.finance,
          title: 'Worker advance burden',
          body: 'Rs. ${_fmt(advanceTotal)} in pending advances '
              '(${pendingAdvances.length} worker(s))'
              '${monthRev > 0 ? ' · ${share.toStringAsFixed(0)}% of this month\'s revenue' : ''}.',
          severity: share > 50
              ? InsightSeverity.warning
              : InsightSeverity.attention,
        ),
      );
    }
    return out;
  }

  // ───────────────────────── WORKFORCE ALLOCATION ─────────────────────────

  /// Surfaces active workers who are not currently assigned to any site.
  /// Reuses the existing repositories; no new schema.
  Future<List<BusinessInsight>> workforceAllocation() async {
    final allWorkers = await workerRepository.getAllWorkers();
    final out = <BusinessInsight>[];
    final idle = <WorkerModel>[];
    for (final w in allWorkers) {
      if (w.id == null || w.status != 'active') continue;
      final sites = await workerRepository.getSitesByWorker(w.id!);
      if (sites.isEmpty) idle.add(w);
    }
    if (idle.isNotEmpty) {
      final names = idle.take(3).map((w) => w.name).join(', ');
      out.add(
        BusinessInsight(
          domain: InsightDomain.workers,
          title: 'Unassigned active workers',
          body: '${idle.length} active worker(s) not assigned to any site'
              '${idle.length <= 3 ? ' ($names)' : ''} — allocate or mark inactive.',
          severity: idle.length > 5
              ? InsightSeverity.warning
              : InsightSeverity.attention,
        ),
      );
    }
    return out;
  }

  // ───────────────────────── HELPERS ─────────────────────────

  (List<ConstructionPaymentModel>, List<ConstructionPaymentModel>)
      _splitLastMonths(List<ConstructionPaymentModel> all, int months) {
    final n = now();
    final cut = DateTime(n.year, n.month - months, n.day);
    final recent = all.where((p) => p.paymentDate.isAfter(cut)).toList();
    final prior =
        all.where((p) => !p.paymentDate.isAfter(cut)).toList();
    return (recent, prior);
  }

  double _stddev(List<double> xs, double mean) {
    if (xs.length < 2) return 0;
    final variance = xs.fold(0.0, (a, x) => a + pow(x - mean, 2).toDouble()) /
        (xs.length - 1);
    return sqrt(variance);
  }

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
}
