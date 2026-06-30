import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/worker_model.dart';
import '../../core/providers/worker_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class WorkersListScreen extends StatefulWidget {
  const WorkersListScreen({super.key});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
  final _search = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<WorkerProvider>().loadWorkers(),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<WorkerModel> _filtered(List<WorkerModel> workers) {
    final q = _search.text.toLowerCase();
    return workers.where((w) {
      final matchSearch = q.isEmpty ||
          w.name.toLowerCase().contains(q) ||
          w.trade.toLowerCase().contains(q) ||
          w.phone.toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'all' || w.status == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prov = context.watch<WorkerProvider>();
    final workers = _filtered(prov.workers);
    final isDesktop = MediaQuery.of(context).size.width >= 840;

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('Workers'),
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
            onPressed: () => context.go('/workers/new'),
            tooltip: 'Add Worker',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter ──
          Container(
            color: cs.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search by name, trade, or phone...',
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
                Row(
                  children: [
                    for (final f in ['all', 'active', 'inactive'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(f == 'all'
                              ? 'All (${prov.workers.length})'
                              : '${f[0].toUpperCase()}${f.substring(1)} (${prov.workers.where((w) => w.status == f).length})'),
                          selected: _statusFilter == f,
                          onSelected: (_) => setState(() => _statusFilter = f),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── Workers ──
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : workers.isEmpty
                    ? EmptyState(
                        icon: Icons.people_outline,
                        title: 'No workers found',
                        subtitle: _search.text.isNotEmpty
                            ? 'Try a different search'
                            : 'Add your first worker to get started',
                        action: _search.text.isEmpty
                            ? FilledButton.icon(
                                onPressed: () => context.go('/workers/new'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Worker'),
                              )
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            context.read<WorkerProvider>().loadWorkers(),
                        child: isDesktop
                            ? _DesktopGrid(workers: workers)
                            : _MobileList(workers: workers),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/workers/new'),
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Worker'),
      ),
    );
  }
}

class _DesktopGrid extends StatelessWidget {
  final List<WorkerModel> workers;
  const _DesktopGrid({required this.workers});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.7,
      ),
      itemCount: workers.length,
      itemBuilder: (_, i) => _WorkerCard(worker: workers[i]),
    );
  }
}

class _MobileList extends StatelessWidget {
  final List<WorkerModel> workers;
  const _MobileList({required this.workers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: workers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _WorkerCard(worker: workers[i]),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = worker.status == 'active';
    final avatarColor =
        isActive ? cs.primaryContainer : cs.surfaceContainerHighest;
    final avatarText = isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.5);

    return Card(
      child: InkWell(
        mouseCursor: SystemMouseCursors.click,
        onTap: () => context.go('/workers/${worker.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: avatarColor,
                    child: Text(
                      worker.name[0].toUpperCase(),
                      style: TextStyle(
                          color: avatarText, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          worker.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          worker.trade,
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: worker.status),
                ],
              ),
              const Spacer(),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.phone_outlined,
                          size: 14, color: cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        worker.phone.isEmpty ? 'No phone' : worker.phone,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.attach_money_rounded,
                          size: 14, color: Color(0xFF2E7D32)),
                      CurrencyText(
                        worker.dailyRate,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32)),
                        compact: true,
                      ),
                      Text(
                        '/day',
                        style: TextStyle(
                            fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
