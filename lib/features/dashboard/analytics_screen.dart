import 'package:material_ui/material_ui.dart';

import '../../core/repositories/dashboard_repository.dart';
import '../../shared/widgets/shared_widgets.dart';
import '../dashboard/dashboard_charts.dart';
import '../dashboard/dashboard_screen.dart';

/// V2.0 Analytics & Reporting — a consolidated, read-only reporting surface.
/// Every figure is derived live from SQLite via [DatabaseHelper] aggregations;
/// no business logic, schema, or sync is touched. Reuses the existing dashboard
/// chart widgets and adds 12-month revenue/payroll trend reporting.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _dashboardRepository = DashboardRepository();

  bool _loading = true;
  Object? _error;

  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _expenses = [];
  List<Map<String, dynamic>> _materials = [];
  List<Map<String, dynamic>> _siteProgress = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<Map<String, dynamic>> _monthlyPayroll = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _dashboardRepository.getDashboardStats(),
        _dashboardRepository.getAttendanceChartData(),
        _dashboardRepository.getPaymentsChartData(),
        _dashboardRepository.getExpensesChartData(),
        _dashboardRepository.getMaterialUsageChartData(),
        _dashboardRepository.getSiteProgressChartData(),
        _dashboardRepository.getMonthlyRevenueChartData(),
        _dashboardRepository.getMonthlyPayrollChartData(),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _attendance = results[1] as List<Map<String, dynamic>>;
        _payments = results[2] as List<Map<String, dynamic>>;
        _expenses = results[3] as List<Map<String, dynamic>>;
        _materials = results[4] as List<Map<String, dynamic>>;
        _siteProgress = results[5] as List<Map<String, dynamic>>;
        _monthlyRevenue = results[6] as List<Map<String, dynamic>>;
        _monthlyPayroll = results[7] as List<Map<String, dynamic>>;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorState(onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _KpiGrid(stats: _stats),
          const SizedBox(height: 16),
          MonthlyTrendChart(
            title: 'Revenue vs Payroll (Last 12 Months)',
            months: _mergedMonths(),
            primary: _seriesFor(_monthlyRevenue, _mergedMonths()),
            primaryLabel: 'Revenue',
            primaryColor: const Color(0xFF2E7D32),
            secondary: _seriesFor(_monthlyPayroll, _mergedMonths()),
            secondaryLabel: 'Payroll',
            secondaryColor: const Color(0xFFC2185B),
          ),
          const SizedBox(height: 16),
          PaymentsChart(data: _payments),
          const SizedBox(height: 16),
          ExpensesChart(data: _expenses),
          const SizedBox(height: 16),
          AttendanceChart(data: _attendance),
          const SizedBox(height: 16),
          SiteProgressChart(data: _siteProgress),
          const SizedBox(height: 16),
          MaterialUsageChart(data: _materials),
        ],
      ),
    );
  }

  /// Union of month buckets across revenue + payroll, sorted ascending, so both
  /// series align on the same x-axis.
  List<String> _mergedMonths() {
    final set = <String>{
      ..._monthlyRevenue.map((e) => e['month'] as String),
      ..._monthlyPayroll.map((e) => e['month'] as String),
    };
    final list = set.toList()..sort();
    return list;
  }

  List<double> _seriesFor(
      List<Map<String, dynamic>> rows, List<String> months) {
    final byMonth = <String, double>{
      for (final r in rows)
        r['month'] as String: (r['total_amount'] as num?)?.toDouble() ?? 0.0,
    };
    return [for (final m in months) byMonth[m] ?? 0.0];
  }
}

class _KpiGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _KpiGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = width >= 1024
        ? 4
        : width >= 600
            ? 2
            : 1;

    final items = <Widget>[
      StatCard(
        label: 'Total Paid',
        value: CurrencyText.format(
            (stats['totalPaidAmount'] as num?)?.toDouble() ?? 0.0,
            compact: true),
        icon: Icons.payments_rounded,
        iconColor: const Color(0xFF2E7D32),
      ),
      StatCard(
        label: 'Pending Payments',
        value: CurrencyText.format(
            (stats['pendingPayments'] as num?)?.toDouble() ?? 0.0,
            compact: true),
        icon: Icons.hourglass_bottom_rounded,
        iconColor: const Color(0xFFF57C00),
      ),
      StatCard(
        label: 'Active Sites',
        value: '${stats['activeSites'] ?? 0}',
        icon: Icons.location_city_rounded,
        iconColor: const Color(0xFF0288D1),
      ),
      StatCard(
        label: 'Active Workers',
        value: '${stats['activeWorkers'] ?? 0}',
        icon: Icons.people_rounded,
        iconColor: const Color(0xFF6A1B9A),
      ),
    ];

    if (columns == 1) {
      return Column(
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: item,
            ),
        ],
      );
    }

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: items,
    );
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
            Text(
              'Could not load analytics',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Pull to refresh or try again.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              textAlign: TextAlign.center,
            ),
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
