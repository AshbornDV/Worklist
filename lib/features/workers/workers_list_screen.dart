import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/models/worker_model.dart';
import '../../core/providers/worker_provider.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'worker_detail_screen.dart';

// Breakpoint above which the master-detail layout activates.
const _kWideBreakpoint = 1100.0;
// Width of the master (list) panel in master-detail mode.
const _kMasterWidth = 300.0;

class WorkersListScreen extends StatefulWidget {
  const WorkersListScreen({super.key});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
  final _search = TextEditingController();
  String _statusFilter = 'all';
  int? _selectedWorkerId;

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
    final result = workers.where((w) {
      final matchSearch = q.isEmpty ||
          w.name.toLowerCase().contains(q) ||
          w.trade.toLowerCase().contains(q) ||
          w.phone.toLowerCase().contains(q);
      final matchStatus = _statusFilter == 'all' || w.status == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();

    // Clear stale selection when the selected worker is no longer visible.
    if (_selectedWorkerId != null &&
        !result.any((w) => w.id == _selectedWorkerId)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => setState(() => _selectedWorkerId = null));
    }
    return result;
  }

  Widget _buildSearchFilter(ColorScheme cs, List<WorkerModel> allWorkers) {
    return Container(
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ['all', 'active', 'inactive'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f == 'all'
                          ? 'All (${allWorkers.length})'
                          : '${f[0].toUpperCase()}${f.substring(1)} (${allWorkers.where((w) => w.status == f).length})'),
                      selected: _statusFilter == f,
                      onSelected: (_) => setState(() => _statusFilter = f),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final prov = context.watch<WorkerProvider>();
    final workers = _filtered(prov.workers);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 840;
    final isWideDesktop = width >= _kWideBreakpoint;

    final appBar = AppBar(
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
    );

    // ── Wide desktop: master-detail split ──
    if (isWideDesktop) {
      return Scaffold(
        backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        appBar: appBar,
        body: Row(
          children: [
            // ── Master panel ──
            SizedBox(
              width: _kMasterWidth,
              child: Column(
                children: [
                  _buildSearchFilter(cs, prov.workers),
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
                                        onPressed: () =>
                                            context.go('/workers/new'),
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Worker'),
                                      )
                                    : null,
                              )
                            : RefreshIndicator(
                                onRefresh: () =>
                                    context.read<WorkerProvider>().loadWorkers(),
                                child: ListView.separated(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: workers.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (_, i) => _WorkerMasterTile(
                                    worker: workers[i],
                                    isSelected:
                                        workers[i].id == _selectedWorkerId,
                                    onTap: () => setState(() =>
                                        _selectedWorkerId = workers[i].id),
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
            // ── Divider ──
            VerticalDivider(
                width: 1, thickness: 1, color: cs.outlineVariant),
            // ── Detail panel ──
            Expanded(
              child: _selectedWorkerId == null
                  ? const Center(
                      child: EmptyState(
                        icon: Icons.people_outline,
                        title: 'Select a worker',
                        subtitle:
                            'Choose a worker from the list to view their profile',
                      ),
                    )
                  : WorkerSummaryPanel(
                      key: ValueKey(_selectedWorkerId),
                      workerId: _selectedWorkerId!,
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

    // ── Narrow: existing grid/list layout ──
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: appBar,
      body: Column(
        children: [
          _buildSearchFilter(cs, prov.workers),
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

// ─────────────── MASTER TILE (wide desktop only) ───────────────

class _WorkerMasterTile extends StatelessWidget {
  final WorkerModel worker;
  final bool isSelected;
  final VoidCallback onTap;
  const _WorkerMasterTile(
      {required this.worker, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = worker.status == 'active';
    final avatarColor =
        isActive ? cs.primaryContainer : cs.surfaceContainerHighest;
    final avatarTextColor =
        isActive ? cs.primary : cs.onSurface.withValues(alpha: 0.5);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer.withValues(alpha: 0.4) : null,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(
                color: cs.primary.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  radius: 18,
                  child: Text(
                    worker.name[0].toUpperCase(),
                    style: TextStyle(
                        color: avatarTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        worker.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        worker.trade,
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.6)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                CurrencyText(
                  worker.dailyRate,
                  compact: true,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────── DESKTOP GRID (regular desktop) ───────────────

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
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
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
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        worker.phone.isEmpty ? 'No phone' : worker.phone,
                        style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.6)),
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
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.5)),
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
