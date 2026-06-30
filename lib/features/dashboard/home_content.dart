import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/site_model.dart';
import '../../shared/widgets/shared_widgets.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _db = DatabaseHelper();
  Map<String, dynamic>? _stats;
  List<SiteModel> _paymentReminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final stats = await _db.getDashboardStats();
      final sites = await _db.getAllSites();
      final reminders = sites.where((s) => s.hasRemainingPayment).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));
      if (mounted) {
        setState(() {
          _stats = stats;
          _paymentReminders = reminders;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withOpacity(0.3),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: cs.surface,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
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
                    // ── Greeting ──
                    Text(
                      _greeting(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here\'s what\'s happening on your projects today.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 24),

                    // ── Stats Grid ──
                    _StatsGrid(stats: _stats ?? {}),
                    const SizedBox(height: 28),

                    // ── Financial Summary ──
                    const SectionHeader(
                      title: 'Financial Overview',
                      subtitle: 'All projects combined',
                    ),
                    _FinancialCard(stats: _stats ?? {}),
                    const SizedBox(height: 28),
                    if (_paymentReminders.isNotEmpty) ...[
                      SectionHeader(
                        title: 'Payment Reminders',
                        subtitle:
                            '${_paymentReminders.length} site(s) still have remaining payment',
                      ),
                      _PaymentReminderList(sites: _paymentReminders),
                    ],
                    const SizedBox(height: 28),

                    // ── Quick Actions ──
                    const SectionHeader(title: 'Quick Actions'),
                    _QuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning 👋';
    if (h < 17) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }
}

class _PaymentReminderList extends StatelessWidget {
  final List<SiteModel> sites;

  const _PaymentReminderList({required this.sites});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sites
          .take(5)
          .map(
            (site) => Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFFF57C00),
                  ),
                ),
                title: Text(
                  site.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  site.lastPaidDate == null
                      ? 'Last paid date not recorded'
                      : 'Last paid ${site.lastPaidDate!.day}/${site.lastPaidDate!.month}/${site.lastPaidDate!.year}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Remaining', style: TextStyle(fontSize: 11)),
                    CurrencyText(
                      site.balance,
                      compact: true,
                      style: const TextStyle(
                        color: Color(0xFFF57C00),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                onTap: () => context.go('/sites/${site.id}'),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 600;

    final cards = [
      StatCard(
        label: 'Active Sites',
        value: '${stats['activeSites'] ?? 0}',
        icon: Icons.location_city_rounded,
        iconColor: cs.primary,
        bgColor: cs.primaryContainer,
        onTap: () => context.go('/sites'),
      ),
      StatCard(
        label: 'Active Workers',
        value: '${stats['activeWorkers'] ?? 0}',
        icon: Icons.people_rounded,
        iconColor: const Color(0xFF2E7D32),
        bgColor: const Color(0xFF2E7D32).withOpacity(0.15),
        onTap: () => context.go('/workers'),
      ),
      StatCard(
        label: 'Completed Sites',
        value: '${stats['completedSites'] ?? 0}',
        icon: Icons.check_circle_rounded,
        iconColor: const Color(0xFF00897B),
        bgColor: const Color(0xFF00897B).withOpacity(0.15),
      ),
      StatCard(
        label: 'Pending Advances',
        value: '${stats['pendingAdvances'] ?? 0}',
        icon: Icons.pending_actions_rounded,
        iconColor: const Color(0xFFF57C00),
        bgColor: const Color(0xFFF57C00).withOpacity(0.15),
        onTap: () => context.go('/workers'),
      ),
    ];

    if (isWide) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.8,
        children: cards,
      );
    }

    return Column(
      children: cards
          .map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: c,
              ))
          .toList(),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _FinancialCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = (stats['totalProjectCost'] as double?) ?? 0.0;
    final paid = (stats['totalPaidAmount'] as double?) ?? 0.0;
    final balance = total - paid;
    final pct = total > 0 ? (paid / total).clamp(0.0, 1.0) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _FinStat(
                    label: 'Total Project Value',
                    value: CurrencyText.format(total),
                    color: cs.primary,
                  ),
                ),
                Expanded(
                  child: _FinStat(
                    label: 'Advance Received',
                    value: CurrencyText.format(paid),
                    color: const Color(0xFF2E7D32),
                  ),
                ),
                Expanded(
                  child: _FinStat(
                    label: 'Outstanding Balance',
                    value: CurrencyText.format(balance),
                    color: balance > 0
                        ? const Color(0xFFF57C00)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Overall payment progress',
                        style: Theme.of(context).textTheme.bodySmall),
                    Text('${(pct * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: cs.primary)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(cs.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FinStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FinStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final actions = [
      _QA('Add Site', Icons.add_location_alt_rounded, cs.primary, '/sites/new'),
      const _QA('Add Worker', Icons.person_add_rounded, Color(0xFF2E7D32),
          '/workers/new'),
      const _QA('Mark Attendance', Icons.fact_check_rounded, Color(0xFFF57C00),
          '/attendance'),
    ];

    return Row(
      children: actions
          .map(
            (a) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Card(
                  child: InkWell(
                    onTap: () => context.go(a.route),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: a.color.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(a.icon, color: a.color, size: 26),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QA {
  final String label;
  final IconData icon;
  final Color color;
  final String route;
  const _QA(this.label, this.icon, this.color, this.route);
}

// Helper extension for CurrencyText (static use)
extension CurrencyFormat on CurrencyText {
  static String format(double v) {
    final abs = v.abs();
    final prefix = v < 0 ? '-' : '';
    final str = abs.toStringAsFixed(0);
    final buf = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(str[i]);
      count++;
    }
    return 'Rs. $prefix${buf.toString().split('').reversed.join('')}';
  }
}
