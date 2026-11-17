import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/product_model.dart';
import '../../core/models/site_model.dart';
import '../../core/models/worker_model.dart';
import '../../core/models/construction_payment_model.dart';
import '../../core/models/site_product_model.dart';
import '../../core/models/site_service_model.dart';
import '../../core/providers/site_provider.dart';
import '../../shared/widgets/shared_widgets.dart';
import 'product_select_dialog.dart';

class SiteDetailScreen extends StatefulWidget {
  final int siteId;
  const SiteDetailScreen({required this.siteId, super.key});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen> {
  SiteModel? _site;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<SiteProvider>();
    final site = await prov.getSite(widget.siteId);
    if (mounted) {
      setState(() {
        _site = site;
        _loading = false;
      });
      if (site != null) {
        prov.loadProducts(site.id!);
        prov.loadSiteWorkers(site.id!);
        prov.loadConstructionPayments(site.id!);
        prov.loadSiteProducts(site.id!);
        prov.loadSiteServices(site.id!);
      }
    }
  }

  Future<void> _deleteSite() async {
    final site = _site;
    if (site == null) return;
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Site',
      content:
          'Delete "${site.name}"? This will remove all associated products and attendance records.',
      confirmText: 'Delete',
      destructive: true,
    );
    if (!ok || !mounted) return;
    await context.read<SiteProvider>().deleteSite(site.id!);
    if (mounted) context.go('/sites');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_site == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Site Not Found')),
        body: const EmptyState(
          icon: Icons.location_off,
          title: 'Site not found',
          subtitle: 'This site may have been deleted',
        ),
      );
    }

    final site = _site!;
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(site.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)])),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, cs.secondary],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: Colors.white),
                onPressed: () => context.go('/sites/${site.id}/edit'),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete_rounded, color: Colors.white),
                onPressed: _deleteSite,
                tooltip: 'Delete',
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Basic Info ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Site Information',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                              ),
                              StatusBadge(status: site.status),
                            ],
                          ),
                          const Divider(height: 20),
                          InfoRow(
                            label: 'Location',
                            value: site.area,
                            icon: Icons.place_outlined,
                          ),
                          if (_hasMapLocation(site)) ...[
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _openMap(site),
                                icon: const Icon(Icons.map_outlined),
                                label: const Text('Open exact location'),
                              ),
                            ),
                          ],
                          if (site.workType != null &&
                              site.workType!.isNotEmpty)
                            InfoRow(
                              label: 'Type of Work',
                              value: site.workType! + (site.workTypeRate != null ? ' (\u20B9${site.workTypeRate!.toStringAsFixed(0)})' : ''),
                              icon: Icons.home_repair_service_outlined,
                            ),
                          if (site.workArea != null &&
                              site.workArea!.isNotEmpty)
                            InfoRow(
                              label: 'Work Area',
                              value: '${site.workArea!}${site.workAreaUnit != null ? ' ${site.workAreaUnit}' : ''}',
                              icon: Icons.square_foot_outlined,
                            ),
                          if (site.rate > 0)
                            InfoRow(
                              label: 'Rate',
                              value: CurrencyText.format(site.rate),
                              icon: Icons.price_change_outlined,
                            ),
                          if (site.notes != null && site.notes!.isNotEmpty)
                            InfoRow(
                              label: 'Notes',
                              value: site.notes!,
                              icon: Icons.notes_rounded,
                            ),
                          InfoRow(
                            label: 'Created',
                            value: _fmtDate(site.createdAt),
                            icon: Icons.calendar_today_outlined,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Financial Card ──
                  _FinancialCard(site: site),
                  const SizedBox(height: 20),

                  // ── Construction Payments ──
                  _ConstructionPaymentsSection(
                    siteId: site.id!,
                    onChanged: _load,
                  ),
                  const SizedBox(height: 20),

                  // ── Services ──
                  _SiteServicesSection(siteId: site.id!),
                  const SizedBox(height: 20),

                  // ── Products from Inventory ──
                  _SiteProductsSection(siteId: site.id!),
                  const SizedBox(height: 20),

                  // ── Site Materials ──
                  _ProductsSection(siteId: site.id!),
                  const SizedBox(height: 20),

                  // ── Workers ──
                  _WorkersSection(siteId: site.id!),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  bool _hasMapLocation(SiteModel site) =>
      (site.googleMapsUrl != null && site.googleMapsUrl!.trim().isNotEmpty) ||
      (site.latitude != null && site.longitude != null);

  Future<void> _openMap(SiteModel site) async {
    final rawUrl = site.googleMapsUrl?.trim();
    final uri = rawUrl != null && rawUrl.isNotEmpty
        ? Uri.parse(rawUrl)
        : Uri.https(
            'www.google.com',
            '/maps/search/',
            {'api': '1', 'query': '${site.latitude},${site.longitude}'},
          );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}

// ─────────────── FINANCIAL CARD ───────────────

class _FinancialCard extends StatelessWidget {
  final SiteModel site;
  const _FinancialCard({required this.site});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pct = site.completionPercentage / 100;
    final balanceColor =
        site.isPaid ? const Color(0xFF2E7D32) : const Color(0xFFF57C00);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Summary',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            if (site.hasRemainingPayment) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFF57C00)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xFFF57C00),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Payment reminder: ${CurrencyText.format(site.balance)} remaining.${site.lastPaidDate == null ? '' : ' Last paid ${_fmt(site.lastPaidDate!)}.'}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            if (site.finalCost != null)
              _FRow('Final Cost', site.finalCost!, cs.primary),
            _FRow(site.finalCost != null ? 'Estimated Cost' : 'Cost', site.estimatedCost, cs.primary.withValues(alpha: site.finalCost != null ? 0.6 : 1)),
            const SizedBox(height: 8),
            _FRow('Total Amount Received', site.advanceReceived,
                const Color(0xFF2E7D32)),
            const SizedBox(height: 8),
            _FRow(
              site.isPaid ? 'Fully Paid' : 'Balance Due',
              site.balance.abs(),
              balanceColor,
              bold: true,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Last Paid Date',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  site.lastPaidDate == null
                      ? 'Not recorded'
                      : _fmt(site.lastPaidDate!),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(
                    site.isPaid ? cs.secondary : cs.primary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${site.completionPercentage.toStringAsFixed(1)}% of project value received',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _FRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final bool bold;

  const _FRow(this.label, this.amount, this.color, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        CurrencyText(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}

// ─────────────── PRODUCTS SECTION ───────────────

class _ProductsSection extends StatelessWidget {
  final int siteId;
  const _ProductsSection({required this.siteId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final products = prov.products;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Products / Materials',
          subtitle: '${products.length} item(s) delivered',
          trailing: TextButton.icon(
            onPressed: () => _showAddProduct(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ),
        if (prov.productsLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ))
        else if (products.isEmpty)
          const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products recorded',
            subtitle: 'Add materials delivered to this site',
          )
        else
          ...products.map((p) => _ProductTile(product: p, siteId: siteId)),
      ],
    );
  }

  Future<void> _showAddProduct(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final nameCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    String unit = AppConstants.productUnits.first;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Add Product'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (double.tryParse(v) == null) return 'Invalid';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: unit,
                        items: AppConstants.productUnits
                            .map((u) =>
                                DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (v) => setS(() => unit = v!),
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await prov.addProduct(ProductModel(
                  siteId: siteId,
                  name: nameCtrl.text.trim(),
                  quantity: double.parse(qtyCtrl.text),
                  unit: unit,
                  deliveryDate: DateTime.now(),
                  createdAt: DateTime.now(),
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    qtyCtrl.dispose();
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final int siteId;
  const _ProductTile({required this.product, required this.siteId});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.secondaryContainer,
          child: Icon(Icons.inventory_2, color: cs.secondary, size: 20),
        ),
        title: Text(product.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: product.deliveryDate != null
            ? Text(
                'Delivered: ${_fmt(product.deliveryDate!)}',
                style: TextStyle(
                    fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6)),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                '${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 1)} ${product.unit}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
              onPressed: () async {
                final ok = await showConfirmDialog(
                  context,
                  title: 'Remove Product',
                  content: 'Remove "${product.name}"?',
                  confirmText: 'Remove',
                  destructive: true,
                );
                if (ok && context.mounted) {
                  context.read<SiteProvider>().deleteProduct(product.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

// ─────────────── WORKERS SECTION ───────────────

class _WorkersSection extends StatelessWidget {
  final int siteId;
  const _WorkersSection({required this.siteId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final workers = prov.siteWorkers;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Assigned Workers',
          subtitle: '${workers.length} worker(s)',
          trailing: TextButton.icon(
            onPressed: () => _showAssignWorker(context),
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('Assign'),
          ),
        ),
        if (workers.isEmpty)
          const EmptyState(
            icon: Icons.people_outline,
            title: 'No workers assigned',
            subtitle: 'Assign workers to this site',
          )
        else
          ...workers.map((w) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(w.name[0].toUpperCase(),
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(w.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(w.trade),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: CurrencyText(w.dailyRate,
                            style: const TextStyle(fontSize: 12),
                            compact: true),
                      ),
                      IconButton(
                        icon: Icon(Icons.link_off, color: cs.error, size: 20),
                        onPressed: () async {
                          final ok = await showConfirmDialog(
                            context,
                            title: 'Remove Worker',
                            content: 'Remove ${w.name} from this site?',
                            confirmText: 'Remove',
                            destructive: true,
                          );
                          if (ok && context.mounted) {
                            prov.removeWorker(w.id!, siteId);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () => context.go('/workers/${w.id}'),
                ),
              )),
      ],
    );
  }

  Future<void> _showAssignWorker(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final available = await prov.getWorkersNotOnSite(siteId);

    if (!context.mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('All active workers are already assigned to this site.')),
      );
      return;
    }

    WorkerModel? selected;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Assign Worker'),
          content: SizedBox(
            width: 300,
            child: DropdownButtonFormField<WorkerModel>(
              hint: const Text('Select worker'),
              initialValue: selected,
              items: available
                  .map((w) => DropdownMenuItem(
                        value: w,
                        child: Text('${w.name} (${w.trade})'),
                      ))
                  .toList(),
              onChanged: (v) => setS(() => selected = v),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: selected == null
                  ? null
                  : () async {
                      await prov.assignWorker(selected!.id!, siteId);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── SITE DETAIL PANEL (embeddable, no Scaffold) ───────────────

/// An embeddable site detail view for use in master-detail layouts on wide
/// desktop screens. Loads and shows the same data as [SiteDetailScreen] but
/// without the full-screen Scaffold/AppBar wrapper.
class SiteDetailPanel extends StatefulWidget {
  final int siteId;
  const SiteDetailPanel({required this.siteId, super.key});

  @override
  State<SiteDetailPanel> createState() => _SiteDetailPanelState();
}

class _SiteDetailPanelState extends State<SiteDetailPanel> {
  SiteModel? _site;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SiteDetailPanel old) {
    super.didUpdateWidget(old);
    if (old.siteId != widget.siteId) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = context.read<SiteProvider>();
    final site = await prov.getSite(widget.siteId);
    if (!mounted) return;
    setState(() {
      _site = site;
      _loading = false;
    });
    if (site != null) {
      prov.loadProducts(site.id!);
      prov.loadSiteWorkers(site.id!);
      prov.loadConstructionPayments(site.id!);
      prov.loadSiteProducts(site.id!);
      prov.loadSiteServices(site.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_site == null) {
      return const EmptyState(
        icon: Icons.location_off,
        title: 'Site not found',
        subtitle: 'This site may have been deleted',
      );
    }

    final site = _site!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Panel header ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        site.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: site.status),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit site',
                      onPressed: () =>
                          context.go('/sites/${site.id}/edit'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded),
                      tooltip: 'Open full screen',
                      onPressed: () => context.go('/sites/${site.id}'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── Site info card ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Site Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Divider(height: 20),
                        InfoRow(
                          label: 'Location',
                          value: site.area,
                          icon: Icons.place_outlined,
                        ),
                        if (site.workType != null &&
                            site.workType!.isNotEmpty)
                          InfoRow(
                            label: 'Type of Work',
                            value: site.workType! + (site.workTypeRate != null ? ' (\u20B9${site.workTypeRate!.toStringAsFixed(0)})' : ''),
                            icon: Icons.home_repair_service_outlined,
                          ),
                        if (site.workArea != null &&
                            site.workArea!.isNotEmpty)
                          InfoRow(
                            label: 'Work Area',
                            value: '${site.workArea!}${site.workAreaUnit != null ? ' ${site.workAreaUnit}' : ''}',
                            icon: Icons.square_foot_outlined,
                          ),
                        if (site.rate > 0)
                          InfoRow(
                            label: 'Rate',
                            value: CurrencyText.format(site.rate),
                            icon: Icons.price_change_outlined,
                          ),
                        if (site.notes != null && site.notes!.isNotEmpty)
                          InfoRow(
                            label: 'Notes',
                            value: site.notes!,
                            icon: Icons.notes_rounded,
                          ),
                        InfoRow(
                          label: 'Created',
                          value:
                              '${site.createdAt.day} ${_months[site.createdAt.month - 1]} ${site.createdAt.year}',
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Financial summary ──
                _FinancialCard(site: site),
                const SizedBox(height: 20),

                // ── Services ──
                _SiteServicesSection(siteId: site.id!),
                const SizedBox(height: 20),

                // ── Products from Inventory ──
                _SiteProductsSection(siteId: site.id!),
                const SizedBox(height: 20),

                // ── Site Materials ──
                _ProductsSection(siteId: site.id!),
                const SizedBox(height: 20),

                // ── Workers ──
                _WorkersSection(siteId: site.id!),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
}

// ─────────────── CONSTRUCTION PAYMENTS SECTION ───────────────

class _ConstructionPaymentsSection extends StatelessWidget {
  final int siteId;
  final VoidCallback onChanged;
  const _ConstructionPaymentsSection({required this.siteId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final payments = prov.constructionPayments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Construction Payments',
          subtitle: '${payments.length} payment(s) received',
          trailing: TextButton.icon(
            onPressed: () => _showAddPayment(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ),
        if (prov.constructionPaymentsLoading)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ))
        else if (payments.isEmpty)
          const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payments recorded',
            subtitle: 'Add construction payments for this site',
          )
        else
          ...payments.map((p) => _PaymentTile(
                payment: p,
                siteId: siteId,
                onChanged: onChanged,
              )),
      ],
    );
  }

  Future<void> _showAddPayment(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await prov.addConstructionPayment(ConstructionPaymentModel(
                siteId: siteId,
                amount: double.parse(amountCtrl.text),
                paymentDate: DateTime.now(),
                notes: notesCtrl.text.trim(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                onChanged();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    amountCtrl.dispose();
    notesCtrl.dispose();
  }
}

class _PaymentTile extends StatelessWidget {
  final ConstructionPaymentModel payment;
  final int siteId;
  final VoidCallback onChanged;

  const _PaymentTile({
    required this.payment,
    required this.siteId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final d = payment.paymentDate;
    final dateStr = '${d.day}/${d.month}/${d.year}';
    final hasNotes = payment.notes != null && payment.notes!.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32).withValues(alpha: 0.1),
          child: const Icon(Icons.attach_money, color: Color(0xFF2E7D32)),
        ),
        title: CurrencyText(
          payment.amount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(hasNotes ? '$dateStr • ${payment.notes}' : dateStr),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context),
              tooltip: 'Edit payment',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _delete(context),
              tooltip: 'Delete payment',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final amountCtrl = TextEditingController(text: payment.amount.toStringAsFixed(0));
    final notesCtrl = TextEditingController(text: payment.notes ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Payment'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount (Rs.)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final newAmount = double.parse(amountCtrl.text);
              await prov.updateConstructionPayment(
                payment.id!,
                payment.amount,
                ConstructionPaymentModel(
                  siteId: siteId,
                  amount: newAmount,
                  paymentDate: payment.paymentDate,
                  notes: notesCtrl.text.trim(),
                  createdAt: payment.createdAt,
                  updatedAt: DateTime.now(),
                ),
              );
              if (ctx.mounted) {
                Navigator.pop(ctx);
                onChanged();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    amountCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Payment',
      content: 'Remove this payment of ${payment.amount}?',
      confirmText: 'Delete',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    final success = await context
        .read<SiteProvider>()
        .deleteConstructionPayment(payment.id!, siteId, payment.amount);
    if (success) {
      onChanged();
    }
  }
}

// ─────────────── SITE SERVICES SECTION ───────────────

class _SiteServicesSection extends StatelessWidget {
  final int siteId;
  const _SiteServicesSection({required this.siteId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final services = prov.siteServices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Services',
          subtitle: '${services.length} service(s)',
          trailing: TextButton.icon(
            onPressed: () => _showAddService(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add'),
          ),
        ),
        if (prov.siteServicesLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (services.isEmpty)
          const EmptyState(
            icon: Icons.miscellaneous_services_outlined,
            title: 'No services added',
            subtitle: 'Add services like plastering, painting, etc.',
          )
        else
          ...services.map((s) => _ServiceTile(siteId: siteId, service: s)),
      ],
    );
  }

  Future<void> _showAddService(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Service'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Service name *',
                  prefixIcon: Icon(Icons.miscellaneous_services_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter service name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: rateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Rate (price) *',
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter a rate';
                  final val = double.tryParse(v.trim());
                  if (val == null || val <= 0) return 'Rate must be greater than 0';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now();
              await prov.addSiteService(SiteService(
                siteId: siteId,
                serviceName: nameCtrl.text.trim(),
                rate: double.parse(rateCtrl.text.trim()),
                createdAt: now,
                updatedAt: now,
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    rateCtrl.dispose();
  }
}

class _ServiceTile extends StatelessWidget {
  final int siteId;
  final SiteService service;
  const _ServiceTile({required this.siteId, required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.tertiaryContainer,
          child: Icon(Icons.miscellaneous_services_outlined,
              color: cs.tertiary, size: 20),
        ),
        title: Text(service.serviceName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          CurrencyText.format(service.rate),
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') _edit(context);
            if (v == 'delete') _delete(context);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context) async {
    final prov = context.read<SiteProvider>();
    final nameCtrl = TextEditingController(text: service.serviceName);
    final rateCtrl =
        TextEditingController(text: service.rate.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Service'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Service name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rateCtrl,
                decoration: const InputDecoration(labelText: 'Rate'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val <= 0) return 'Invalid rate';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await prov.updateSiteService(service.copyWith(
                serviceName: nameCtrl.text.trim(),
                rate: double.parse(rateCtrl.text.trim()),
                updatedAt: DateTime.now(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    rateCtrl.dispose();
  }

  Future<void> _delete(BuildContext context) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete Service',
      content: 'Remove "${service.serviceName}"?',
      confirmText: 'Delete',
      destructive: true,
    );
    if (ok && context.mounted) {
      context.read<SiteProvider>().deleteSiteService(service.id!);
    }
  }
}

// ─────────────── SITE PRODUCTS (FROM INVENTORY) SECTION ───────────────

class _SiteProductsSection extends StatelessWidget {
  final int siteId;
  const _SiteProductsSection({required this.siteId});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SiteProvider>();
    final siteProducts = prov.siteProducts;
    final cs = Theme.of(context).colorScheme;

    final total = prov.getSiteProductTotal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Products from Inventory',
          subtitle: '${siteProducts.length} product(s) sent',
          trailing: TextButton.icon(
            onPressed: () => _showSelectDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Send from Store'),
          ),
        ),
        if (prov.siteProductsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (siteProducts.isEmpty)
          const EmptyState(
            icon: Icons.inventory_outlined,
            title: 'No products sent from store',
            subtitle: 'Send products from your inventory to this site',
          )
        else ...[
          ...siteProducts.map((sp) => _SiteProductTile(siteId: siteId, siteProduct: sp)),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Materials total: ',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    CurrencyText.format(total),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _showSelectDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => ProductSelectDialog(siteId: siteId),
    );
  }
}

class _SiteProductTile extends StatelessWidget {
  final int siteId;
  final SiteProduct siteProduct;
  const _SiteProductTile({required this.siteId, required this.siteProduct});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.inventory_outlined, color: cs.primary, size: 20),
        ),
        title: Text(siteProduct.productName ?? 'Product',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Chip(
              label: Text(
                '${siteProduct.quantity.toStringAsFixed(siteProduct.quantity % 1 == 0 ? 0 : 1)} ${siteProduct.productUnit ?? 'unit'}',
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Text(
              CurrencyText.format(siteProduct.productRate ?? 0),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: cs.error, size: 20),
          onPressed: () async {
            final ok = await showConfirmDialog(
              context,
              title: 'Remove Product',
              content: 'Remove "${siteProduct.productName ?? 'this product'}" from site?',
              confirmText: 'Remove',
              destructive: true,
            );
            if (ok && context.mounted) {
              context.read<SiteProvider>().deleteSiteProduct(siteProduct.id!);
            }
          },
        ),
      ),
    );
  }
}
