import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/site_model.dart';
import '../../core/providers/site_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  final _search = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<SiteProvider>().loadSites(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SiteModel> _filtered(List<SiteModel> sites) {
    final q = _search.text.toLowerCase();
    return sites.where((s) {
      final matchSearch = q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.area.toLowerCase().contains(q) ||
          (s.googleMapsUrl ?? '').toLowerCase().contains(q) ||
          (s.latitude?.toString() ?? '').contains(q) ||
          (s.longitude?.toString() ?? '').contains(q) ||
          (s.workType ?? '').toLowerCase().contains(q) ||
          (s.workArea ?? '').toLowerCase().contains(q);
      final matchFilter = _filter == 'all' || s.status == _filter;
      return matchSearch && matchFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<SiteProvider>();
    final sites = _filtered(provider.sites);
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Sites'),
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
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.go('/sites/new'),
            tooltip: 'Add Site',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ──
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search sites by name, area, or map location...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'all',
                      'active',
                      'pending',
                      'on_hold',
                      'completed'
                    ]
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f == 'all'
                                    ? 'All'
                                    : f.replaceAll('_', ' ')),
                                selected: _filter == f,
                                onSelected: (_) => setState(() => _filter = f),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Sites list ──
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sites.isEmpty
                    ? EmptyState(
                        icon: Icons.location_city_outlined,
                        title: 'No sites found',
                        subtitle: _search.text.isNotEmpty || _filter != 'all'
                            ? 'Try a different search or filter'
                            : 'Add your first site to get started',
                        action: _search.text.isEmpty && _filter == 'all'
                            ? FilledButton.icon(
                                onPressed: () => context.go('/sites/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Site'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<SiteProvider>().loadSites(),
                        child: isDesktop
                            ? _DesktopGrid(sites: sites)
                            : _MobileList(sites: sites),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/sites/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add Site'),
      ),
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  final List<SiteModel> sites;
  const _DesktopGrid({required this.sites});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.32,
      ),
      itemCount: sites.length,
      itemBuilder: (_, i) => _SiteCard(site: sites[i]),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<SiteModel> sites;
  const _MobileList({required this.sites});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sites.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _SiteCard(site: sites[i]),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;
  const _SiteCard({required this.site});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = site.completionPercentage / 100;

    return Card(
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.go('/sites/${site.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      site.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(status: site.status),
                ],
              ),
              const SizedBox(height: 6),
              if (site.hasRemainingPayment) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: Color(0xFFF57C00),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Remaining ${CurrencyText.format(site.balance, compact: true)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: const Color(0xFFF57C00),
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Icon(Icons.place_outlined,
                      size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      site.area,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((site.googleMapsUrl != null &&
                          site.googleMapsUrl!.isNotEmpty) ||
                      (site.latitude != null && site.longitude != null)) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.map_outlined,
                        size: 15, color: cs.primary.withValues(alpha: 0.8)),
                  ],
                ],
              ),
              if (site.workType != null && site.workType!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.home_repair_service_outlined,
                        size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        site.workType!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Cost',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5))),
                      CurrencyText(site.estimatedCost,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          compact: true),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        site.isPaid ? 'PAID' : 'Balance',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: site.isPaid
                                  ? const Color(0xFF2E7D32)
                                  : cs.onSurface.withValues(alpha: 0.5),
                              fontWeight: site.isPaid ? FontWeight.bold : null,
                            ),
                      ),
                      if (!site.isPaid)
                        CurrencyText(site.balance,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFF57C00)),
                            compact: true),
                      if (site.lastPaidDate != null)
                        Text(
                          'Last paid ${site.lastPaidDate!.day}/${site.lastPaidDate!.month}/${site.lastPaidDate!.year}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${site.completionPercentage.toStringAsFixed(0)}% paid',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
