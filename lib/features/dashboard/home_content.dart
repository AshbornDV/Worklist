import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/providers/store_product_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../core/services/collection_reminder_service.dart';
import '../../features/dashboard/dashboard_charts.dart';
import '../../shared/widgets/shared_widgets.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _db = DatabaseHelper();
  Map<String, dynamic>? _stats;
  List<dynamic> _stockAlerts = [];
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _attendance = [];
  List<Map<String, dynamic>> _siteProgress = [];
  List<Map<String, dynamic>> _materialUsage = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    CollectionReminderService.instance.requestPermissions();
  }

  Future<void> _load() async {
    final store = context.read<StoreProductProvider>();
    setState(() => _loading = true);
    try {
      final stats = await _db.getDashboardStats();
      final stockAlerts = await store.getStockAlertProducts();
      final activity = await _db.getRecentActivity(limit: 8);
      final attendance = await _db.getAttendanceChartData();
      final siteProgress = await _db.getSiteProgressChartData();
      final materialUsage = await _db.getMaterialUsageChartData();
      if (mounted) {
        setState(() {
          _stats = stats;
          _stockAlerts = stockAlerts;
          _activity = activity;
          _attendance = attendance;
          _siteProgress = siteProgress;
          _materialUsage = materialUsage;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final name = context.read<AuthProvider>().currentUser?.username ?? '';
    final first = name.trim().isEmpty ? '' : name.trim().split(' ').first;
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Good Morning'
        : h < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    return first.isEmpty ? '$part 👋' : '$part, $first 👋';
  }

  // Real notification count derived from actionable items already in the
  // dashboard stats (no separate notifications table exists): low/out-of-stock
  // products + pending worker advances. 0 → no badge.
  int get _unreadCount {
    final s = _stats ?? {};
    final stock = (s['outOfStock'] as int? ?? 0) +
        (s['criticalStock'] as int? ?? 0) +
        (s['lowStock'] as int? ?? 0);
    final advances = (s['pendingAdvances'] as int? ?? 0);
    return stock + advances;
  }

  Widget _bell(BuildContext context) {
    final count = _unreadCount;
    return IconButton(
      icon: count > 0
          ? Badge(
              label: Text('$count'),
              child: const Icon(Icons.notifications_outlined),
            )
          : const Icon(Icons.notifications_outlined),
      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count item(s) need your attention'
              : 'No new notifications'),
        ),
      ),
      tooltip: 'Notifications',
    );
  }

  Widget _themeToggle(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.mode == ThemeMode.dark;
    return IconButton(
      icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: theme.toggle,
      tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 600;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: isWide ? _wideAppBar(context) : _mobileAppBar(context),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening on your projects today.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 24),
                    _StatsGrid(stats: _stats ?? {}),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _StockAlertsCard(
                            stats: _stats ?? {},
                            products: _stockAlerts,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _RecentActivityCard(activity: _activity),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const SectionHeader(
                      title: 'Analytics & Charts',
                      subtitle: 'Visual insights into your projects',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: AttendanceChart(data: _attendance)),
                        const SizedBox(width: 16),
                        Expanded(child: SiteProgressChart(data: _siteProgress)),
                        const SizedBox(width: 16),
                        Expanded(child: MaterialUsageChart(data: _materialUsage)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _mobileAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Dashboard'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => RootScaffoldKey.of(ctx)?.currentState?.openEndDrawer(),
        ),
      ),
      actions: [
        _themeToggle(context),
        _bell(context),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _load,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  PreferredSizeWidget _wideAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      title: Row(
        children: [
          const Text('Dashboard'),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search anything…',
                  hintStyle: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.5)),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixText: 'Ctrl /',
                  suffixStyle: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (q) {
                  final query = q.trim().toLowerCase();
                  if (query.isEmpty) return;
                  const routes = {
                    'dashboard': '/',
                    'site': '/sites',
                    'worker': '/workers',
                    'attendance': '/attendance',
                    'payroll': '/payroll',
                    'product': '/products',
                    'stock': '/stock',
                    'service': '/services',
                    'collection': '/collections',
                    'account': '/account',
                  };
                  final match = routes.entries
                      .where((e) => query.contains(e.key))
                      .map((e) => e.value)
                      .firstOrNull;
                  if (match != null) context.go(match);
                },
              ),
            ),
          ),
        ],
      ),
      backgroundColor: cs.surface,
      actions: [
        _themeToggle(context),
        _bell(context),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 16,
          backgroundColor: cs.primary,
          child: Text(
            (context.read<AuthProvider>().currentUser?.username ?? 'A')
                .trim()
                .isEmpty
                ? 'A'
                : (context.read<AuthProvider>().currentUser?.username ?? 'A')
                    .trim()[0]
                    .toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ─────────────── STATS GRID (8 CARDS) ───────────────

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    // Data-bound trend labels (change as the underlying data changes).
    final activeSites = (stats['activeSites'] as int? ?? 0);
    final completedSites = (stats['completedSites'] as int? ?? 0);
    final activeWorkers = (stats['activeWorkers'] as int? ?? 0);
    final present = (stats['workersPresentToday'] as int? ?? 0);
    final absent = (stats['workersAbsentToday'] as int? ?? 0);
    final totalProducts = (stats['totalProducts'] as int? ?? 0);
    final materialsIssued = (stats['materialsIssuedToday'] as int? ?? 0);
    final pending = (stats['pendingPayments'] as double? ?? 0.0);
    final totalCost = (stats['totalProjectCost'] as double? ?? 0.0);
    final expenses = (stats['todayExpenses'] as double? ?? 0.0);

    final tPresent = activeWorkers > 0
        ? '$present of $activeWorkers present'
        : 'No workers yet';
    final tPending = totalCost > 0
        ? 'Rs. ${CurrencyText.format(pending)} of ${CurrencyText.format(totalCost)}'
        : pending > 0
            ? 'Rs. ${CurrencyText.format(pending)} outstanding'
            : 'All settled';

    final cards = [
      StatCard(
        label: 'Active Sites',
        value: '$activeSites',
        icon: Icons.location_city_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        trend: completedSites > 0 ? '$completedSites completed' : 'No completed yet',
        onTap: () => context.go('/sites'),
      ),
      StatCard(
        label: 'Total Workers',
        value: '$activeWorkers',
        icon: Icons.people_rounded,
        iconColor: const Color(0xFF16A34A),
        bgColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
        trend: tPresent,
        onTap: () => context.go('/workers'),
      ),
      StatCard(
        label: 'Workers Present Today',
        value: '$present',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF0D9488),
        bgColor: const Color(0xFF0D9488).withValues(alpha: 0.15),
        trend: tPresent,
        onTap: () => context.go('/attendance'),
      ),
      StatCard(
        label: 'Workers Absent Today',
        value: '$absent',
        icon: Icons.cancel_rounded,
        iconColor: const Color(0xFFDC2626),
        bgColor: const Color(0xFFDC2626).withValues(alpha: 0.15),
        trend: absent > 0 ? '$absent absent today' : 'Full attendance',
      ),
      StatCard(
        label: 'Total Products',
        value: '$totalProducts',
        icon: Icons.inventory_2_rounded,
        iconColor: const Color(0xFF7C3AED),
        bgColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
        trend: totalProducts > 0 ? '$totalProducts in store' : 'No products yet',
        onTap: () => context.go('/products'),
      ),
      StatCard(
        label: 'Materials Issued Today',
        value: '$materialsIssued',
        icon: Icons.local_shipping_rounded,
        iconColor: const Color(0xFF2563EB),
        bgColor: const Color(0xFF2563EB).withValues(alpha: 0.15),
        trend: materialsIssued > 0 ? '$materialsIssued issued today' : 'None issued today',
      ),
      StatCard(
        label: 'Pending Payments',
        value: CurrencyText.format(pending),
        icon: Icons.account_balance_wallet_rounded,
        iconColor: const Color(0xFFF59E0B),
        bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        trend: tPending,
        onTap: () => context.go('/collections'),
      ),
      StatCard(
        label: "Today's Expenses",
        value: CurrencyText.format(expenses),
        icon: Icons.credit_card_rounded,
        iconColor: const Color(0xFFEC4899),
        bgColor: const Color(0xFFEC4899).withValues(alpha: 0.15),
        trend: expenses > 0 ? 'Spent today' : 'No expenses today',
      ),
    ];

    if (isWide) {
      return GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.6,
        children: cards,
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: cards,
    );
  }
}

// ─────────────── STOCK ALERTS ───────────────

class _StockAlertsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> products;
  const _StockAlertsCard({required this.stats, required this.products});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final out = (stats['outOfStock'] as int? ?? 0);
    final critical = (stats['criticalStock'] as int? ?? 0);
    final low = (stats['lowStock'] as int? ?? 0);
    final total = out + critical + low;

    final alertBlock = total > 0
        ? Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: cs.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$total product(s) need attention',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        'Out of stock: $out • Critical: $critical • Low: $low',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => context.go('/stock'),
                  child: const Text('Open'),
                ),
              ],
            ),
          )
        : Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'All stock healthy',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Stock Alerts',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                              fontWeight: FontWeight.bold, color: cs.primary)),
                ),
                TextButton(
                  onPressed: () => context.go('/stock'),
                  child: const Text('View All'),
                ),
              ],
            ),
            Text('Low inventory items that need attention',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6))),
            const SizedBox(height: 12),
            alertBlock,
            if (products.isNotEmpty) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${products.first.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${products.first.stock} ${products.first.unit}',
                    style: TextStyle(color: cs.error, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────── RECENT ACTIVITY ───────────────

class _RecentActivityCard extends StatelessWidget {
  final List<Map<String, dynamic>> activity;
  const _RecentActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Recent Activity',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (activity.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('No recent activity')),
              )
            else
              ...activity.take(4).map((a) {
                final icon = switch (a['type']) {
                  'worker' => Icons.person_add_rounded,
                  'material' => Icons.local_shipping_rounded,
                  'payment' => Icons.payments_rounded,
                  _ => Icons.receipt_long_rounded,
                };
                final sub = a['subtitle']?.toString() ?? '';
                final detail = sub.isEmpty ? (a['title'] ?? '') : '${a['title']} • $sub';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(icon, size: 16, color: cs.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(detail,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12)),
                            Text(_relative(a['time']?.toString() ?? ''),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                        fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _relative(String iso) {
    if (iso.isEmpty) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
