import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../core/repositories/inventory_repository.dart';
import '../../../core/repositories/payroll_repository.dart';
import '../../../core/repositories/site_repository.dart';
import '../../../core/repositories/worker_repository.dart';
import '../../../core/notifications/insights/business_insight_models.dart';
import '../../../core/notifications/insights/business_insight_provider.dart';

/// Phase 11 — Business Insight screen.
///
/// Renders the locally-generated insights grouped by domain plus the four summary
/// cards (Morning Briefing / Evening Summary / Weekly / Monthly). Tapping an
/// insight deep-links to the relevant screen. The provider is self-wired to the
/// existing repositories (no app-shell changes beyond the route).
class BusinessInsightScreen extends StatefulWidget {
  const BusinessInsightScreen({super.key});

  @override
  State<BusinessInsightScreen> createState() => _BusinessInsightScreenState();
}

class _BusinessInsightScreenState extends State<BusinessInsightScreen> {
  late final BusinessInsightProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = BusinessInsightProvider(
      siteRepository: SiteRepository(),
      payrollRepository: PayrollRepository(),
      workerRepository: WorkerRepository(),
      inventoryRepository: InventoryRepository(),
    );
    _provider.load();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _provider,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Business Insights'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () => _provider.load(),
            ),
          ],
        ),
        body: _provider.isLoading && _provider.insights.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _provider.error != null
                ? Center(child: Text('Error: ${_provider.error}'))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    const domains = InsightDomain.values;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummaryRow(provider: _provider),
        const SizedBox(height: 16),
        if (_provider.insights.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No insights yet — add sites, payments, workers or '
                  'inventory and pull to refresh.'),
            ),
          ),
        for (final d in domains) _DomainSection(provider: _provider, domain: d),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.provider});
  final BusinessInsightProvider provider;

  @override
  Widget build(BuildContext context) {
    const kinds = InsightSummaryKind.values;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final k in kinds)
            SizedBox(
              width: 200,
              child: Card(
                margin: const EdgeInsets.only(right: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.title,
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      Text(
                        provider.summaryHeadline(k),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DomainSection extends StatelessWidget {
  const _DomainSection({
    required this.provider,
    required this.domain,
  });
  final BusinessInsightProvider provider;
  final InsightDomain domain;

  @override
  Widget build(BuildContext context) {
    final items = provider.forDomain(domain);
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(domain.label,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final insight in items) _InsightCard(insight: insight),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});
  final BusinessInsight insight;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.severity);
    final card = Card(
      child: ListTile(
        leading: Icon(_domainIcon(insight.domain), color: color),
        title: Text(insight.title),
        subtitle: Text(insight.body),
        trailing: insight.deepLink != null
            ? const Icon(Icons.chevron_right)
            : null,
        onTap: insight.deepLink == null
            ? null
            : () => context.push(insight.deepLink!),
      ),
    );
    if (insight.severity == InsightSeverity.info) return card;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: card,
    );
  }

  Color _severityColor(InsightSeverity s) {
    switch (s) {
      case InsightSeverity.info:
        return Colors.blueGrey;
      case InsightSeverity.attention:
        return Colors.blue;
      case InsightSeverity.warning:
        return Colors.orange;
      case InsightSeverity.critical:
        return Colors.red;
    }
  }

  IconData _domainIcon(InsightDomain d) {
    switch (d) {
      case InsightDomain.payments:
        return Icons.payments;
      case InsightDomain.sites:
        return Icons.location_city;
      case InsightDomain.workers:
        return Icons.people;
      case InsightDomain.inventory:
        return Icons.inventory_2;
      case InsightDomain.payroll:
        return Icons.account_balance_wallet;
      case InsightDomain.finance:
        return Icons.trending_up;
    }
  }
}
