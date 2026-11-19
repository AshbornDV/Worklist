import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/providers/store_product_provider.dart';
import '../../core/providers/site_provider.dart';

class ProductSelectDialog extends StatefulWidget {
  final int siteId;

  const ProductSelectDialog({super.key, required this.siteId});

  @override
  State<ProductSelectDialog> createState() => _ProductSelectDialogState();
}

class _ProductSelectDialogState extends State<ProductSelectDialog> {
  final Map<int, TextEditingController> _qtyControllers = {};
  final Map<int, double> _selectedQtys = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StoreProductProvider>();
    final products = prov.products.where((p) => p.stock > 0).toList();
    final cs = Theme.of(context).colorScheme;
    final totalCost = products.fold(0.0, (sum, p) {
      final qty = _selectedQtys[p.id!] ?? 0;
      return sum + qty * p.rate;
    });

    return AlertDialog(
      title: const Text('Send Products to Site'),
      content: SizedBox(
        width: double.maxFinite,
        child: prov.loading
            ? const Center(child: CircularProgressIndicator())
            : products.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No products with stock available. Add products first.'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: ListView(
                          children: products.map((p) {
                            _qtyControllers.putIfAbsent(
                              p.id!,
                              () => TextEditingController(),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.name,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '\u20B9${p.rate.toStringAsFixed(0)} / ${p.size} ${p.unit}',
                                              style: TextStyle(
                                                color: cs.primary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              'Stock: ${p.stock.toStringAsFixed(1)} ${p.unit}',
                                              style: TextStyle(
                                                color: cs.onSurface.withValues(alpha: 0.5),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller: _qtyControllers[p.id!],
                                          decoration: const InputDecoration(
                                            hintText: 'Qty',
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 10,
                                            ),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            final qty = double.tryParse(v.trim()) ?? 0;
                                            setState(() {
                                              if (qty > 0) {
                                                _selectedQtys[p.id!] = qty;
                                              } else {
                                                _selectedQtys.remove(p.id!);
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (totalCost > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total cost:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Rs. ${totalCost.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedQtys.isEmpty || _submitting
              ? null
              : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send to Site'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final siteProv = context.read<SiteProvider>();
    final storeProv = context.read<StoreProductProvider>();
    final errors = <String>[];

    for (final entry in _selectedQtys.entries) {
      final productId = entry.key;
      final qty = entry.value;
      final product = storeProv.products.firstWhere((p) => p.id == productId);

      if (qty > product.stock) {
        errors.add('Insufficient stock for ${product.name}. Available: ${product.stock.toStringAsFixed(1)}');
        continue;
      }
      if (qty <= 0) continue;

      final err = await siteProv.sendProductToSite(widget.siteId, productId, qty);
      if (err != null) {
        errors.add('${product.name}: $err');
      }
    }

    if (!mounted) return;

    if (errors.isEmpty) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Products sent to site'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.join('\n')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
