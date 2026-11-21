import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/site_model.dart';
import '../../core/repositories/site_repository.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../shared/widgets/shared_widgets.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final _siteRepository = SiteRepository();
  List<SiteModel> _sites = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final sites = await _siteRepository.getAllSites();
      final dueSites = sites.where((s) => s.hasRemainingPayment).toList()
        ..sort((a, b) => b.balance.compareTo(a.balance));
      if (mounted) {
        setState(() {
          _sites = dueSites;
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
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Remaining Amounts'),
        backgroundColor: cs.surface,
        leading: isDesktop
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => RootScaffoldKey.of(ctx)?.currentState?.openEndDrawer(),
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
              child: _sites.isEmpty
                  ? const EmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'All caught up',
                      subtitle: 'No sites have pending remaining amounts.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sites.length,
                      itemBuilder: (context, index) {
                        final site = _sites[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: site.isCollectionDue
                                  ? const Color(0xFFFFF3E0)
                                  : cs.primaryContainer,
                              child: Icon(
                                site.isCollectionDue
                                    ? Icons.warning_amber_rounded
                                    : Icons.location_city_rounded,
                                color: site.isCollectionDue
                                    ? const Color(0xFFF57C00)
                                    : cs.primary,
                              ),
                            ),
                            title: Text(
                              site.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${site.daysSinceLastPayment} days since last payment',
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Remaining',
                                    style: TextStyle(fontSize: 11)),
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
                        );
                      },
                    ),
            ),
    );
  }
}
