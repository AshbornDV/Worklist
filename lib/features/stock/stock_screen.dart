import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/models/store_product_model.dart';
import '../../core/providers/store_product_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final Map<int, double> _sentTotals = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final prov = context.read<StoreProductProvider>();
    await prov.loadProducts();
    for (final p in prov.products) {
      if (p.id != null) {
        final sent = await prov.getSentToSiteTotal(p.id!);
        _sentTotals[p.id!] = sent;
      }
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StoreProductProvider>();
    final products = prov.products;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? EmptyState(
                  icon: Icons.inventory_outlined,
                  title: 'No products in stock',
                  subtitle:
                      'Add a product first, then you can record stock in/out here.',
                  action: FilledButton.icon(
                    onPressed: () => context.go('/products'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => syncThenReload(context, _load),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final product = products[i];
                      final sent = _sentTotals[product.id] ?? 0;
                      return _StockCard(
                        product: product,
                        sentToSite: sent,
                        onAddStock: () => _showAddStock(context, product),
                      );
                    },
                  ),
                ),
    );
  }

  Future<void> _showAddStock(BuildContext context, StoreProduct product) async {
    final qtyCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Stock - ${product.name}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: qtyCtrl,
            decoration: InputDecoration(
              labelText: 'Quantity to add (${product.unit})',
              prefixIcon: const Icon(Icons.add_box_outlined),
              hintText: '0',
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter quantity';
              final val = double.tryParse(v.trim());
              if (val == null || val <= 0) return 'Must be greater than 0';
              return null;
            },
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
              await context.read<StoreProductProvider>().addStock(
                    product.id!,
                    double.parse(qtyCtrl.text.trim()),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
              await _load();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    qtyCtrl.dispose();
  }
}

class _StockCard extends StatelessWidget {
  final StoreProduct product;
  final double sentToSite;
  final VoidCallback onAddStock;

  const _StockCard({
    required this.product,
    required this.sentToSite,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final inStock = product.stock;
    final status = product.isOutOfStock
        ? 'Out of Stock'
        : product.isCriticalStock
            ? 'Critical Stock'
            : product.isLowStock
                ? 'Low Stock'
                : 'In Stock';
    final inStockColor = product.isOutOfStock
        ? Colors.red
        : product.isCriticalStock
            ? const Color(0xFFD32F2F)
            : product.isLowStock
                ? const Color(0xFFF57C00)
                : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.inventory_outlined, color: cs.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\u20B9 ${product.rate.toStringAsFixed(0)} / ${product.size} ${product.unit}',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add stock',
                  onPressed: onAddStock,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _StatChip(
                  label: 'In Stock',
                  value: '${inStock.toStringAsFixed(1)} ${product.unit}',
                  color: inStockColor,
                ),
                const SizedBox(width: 12),
                _StatChip(
                  label: 'Sent to Site',
                  value: '${sentToSite.toStringAsFixed(1)} ${product.unit}',
                  color: cs.secondary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: inStockColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: inStockColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
