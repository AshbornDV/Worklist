import 'dart:math';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/models/store_product_model.dart';
import '../../core/providers/store_product_provider.dart';
import '../../shared/widgets/shared_widgets.dart';

const _unitOptions = [
  'piece',
  'kg',
  'bag',
  'liter',
  'meter',
  'sqft',
  'sqm',
  'box',
  'roll',
  'set',
  'ton',
  'foot',
  'inch',
  'yard',
];

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _query = '';
  String? _filterCategory;
  String? _filterSubcategory;
  String? _filterColorLabel;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProductProvider>().loadProducts();
    });
    _searchCtrl.text = _query;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<StoreProductProvider>();
    final products = prov.products;
    final filtered = _applyFilters(products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scan barcode',
            onPressed: () => _scanBarcodeAndSearch(context, products),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add product',
            onPressed: () => _showAddDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: prov.loading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No products yet',
                  subtitle:
                      'Add your first product to start tracking inventory.',
                )
              : RefreshIndicator(
                  onRefresh: () => syncThenReload(context, prov.loadProducts),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    addAutomaticKeepAlives: false,
                    itemCount: filtered.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _SearchAndFilterBar(
                            controller: _searchCtrl,
                            onQueryChanged: (v) {
                              setState(() => _query = v);
                            },
                            onOpenFilters: () =>
                                _openFiltersDialog(context, products),
                            activeFilters: _activeFiltersLabel(),
                            onClearFilters: _clearFilters,
                          ),
                        );
                      }
                      final product = filtered[i - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ProductCard(
                          product: product,
                          onTap: () => _showEditDialog(context, product),
                          onDelete: () =>
                              _deleteProduct(context, prov, product),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
    );
  }

  String _selectedUnit = 'piece';
  double _lowStockThreshold = 10.0;
  double _criticalStockThreshold = 2.0;

  Future<void> _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final sizeCtrl = TextEditingController(text: '1');
    final categoryCtrl = TextEditingController();
    final subcategoryCtrl = TextEditingController();
    final colorCtrl = TextEditingController();
    final barcodeCtrl = TextEditingController();
    final lowCtrl = TextEditingController(text: '10');
    final criticalCtrl = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();
    _selectedUnit = 'piece';
    _lowStockThreshold = 10.0;
    _criticalStockThreshold = 2.0;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Product name *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a product name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: subcategoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      prefixIcon: Icon(Icons.segment_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: colorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color label',
                      prefixIcon: Icon(Icons.label_outline),
                      hintText: 'e.g. Red / #FF0000',
                    ),
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
                      if (val == null || val <= 0) {
                        return 'Rate must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Size *',
                            prefixIcon: Icon(Icons.straighten),
                            hintText: '1',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter size';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            prefixIcon: SizedBox.shrink(),
                          ),
                          items: _unitOptions
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setDialogState(() => _selectedUnit = v ?? 'piece');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            prefixIcon: Icon(Icons.qr_code_2_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Generate barcode',
                        onPressed: () {
                          final code = _generateBarcode();
                          setDialogState(() {
                            barcodeCtrl.text = code;
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded),
                      ),
                      IconButton(
                        tooltip: 'Scan barcode',
                        onPressed: () => _scanBarcodeIntoField(
                          ctx,
                          setDialogState,
                          barcodeCtrl,
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ],
                  ),
                  if (barcodeCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: barcodeCtrl.text.trim(),
                      height: 70,
                      width: 260,
                      drawText: false,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: lowCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Low stock threshold',
                            prefixIcon: Icon(Icons.trending_down_rounded),
                            hintText: '10',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = double.tryParse(v.trim());
                            if (parsed != null) _lowStockThreshold = parsed;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: criticalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Critical stock threshold',
                            prefixIcon: Icon(Icons.priority_high_rounded),
                            hintText: '2',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = double.tryParse(v.trim());
                            if (parsed != null) {
                              _criticalStockThreshold = parsed;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                final product = StoreProduct(
                  name: nameCtrl.text.trim(),
                  category: _cleanOrNull(categoryCtrl.text),
                  subcategory: _cleanOrNull(subcategoryCtrl.text),
                  colorLabel: _cleanOrNull(colorCtrl.text),
                  barcode: _cleanOrNull(barcodeCtrl.text),
                  rate: double.parse(rateCtrl.text.trim()),
                  size: double.parse(sizeCtrl.text.trim()),
                  unit: _selectedUnit,
                  lowStockThreshold: _lowStockThreshold,
                  criticalStockThreshold: _criticalStockThreshold,
                  createdAt: now,
                  updatedAt: now,
                );
                final ok = await context
                    .read<StoreProductProvider>()
                    .addProduct(product);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            context.read<StoreProductProvider>().error ??
                                'Failed'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, StoreProduct product) {
    final nameCtrl = TextEditingController(text: product.name);
    final rateCtrl = TextEditingController(text: product.rate.toString());
    final sizeCtrl = TextEditingController(text: product.size.toString());
    final categoryCtrl = TextEditingController(text: product.category ?? '');
    final subcategoryCtrl =
        TextEditingController(text: product.subcategory ?? '');
    final colorCtrl = TextEditingController(text: product.colorLabel ?? '');
    final barcodeCtrl = TextEditingController(text: product.barcode ?? '');
    final lowCtrl =
        TextEditingController(text: product.lowStockThreshold.toString());
    final criticalCtrl =
        TextEditingController(text: product.criticalStockThreshold.toString());
    final formKey = GlobalKey<FormState>();

    _selectedUnit = product.unit;
    _lowStockThreshold = product.lowStockThreshold;
    _criticalStockThreshold = product.criticalStockThreshold;

    return showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Product'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Product name *',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a product name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: subcategoryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subcategory',
                      prefixIcon: Icon(Icons.segment_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: colorCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Color label',
                      prefixIcon: Icon(Icons.label_outline),
                      hintText: 'e.g. Red / #FF0000',
                    ),
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
                      if (val == null || val <= 0) {
                        return 'Rate must be greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: sizeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Size *',
                            prefixIcon: Icon(Icons.straighten),
                            hintText: '1',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Enter size';
                            }
                            final val = double.tryParse(v.trim());
                            if (val == null || val <= 0) return 'Must be > 0';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            prefixIcon: SizedBox.shrink(),
                          ),
                          items: _unitOptions
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            setDialogState(() => _selectedUnit = v ?? 'piece');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: barcodeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Barcode',
                            prefixIcon: Icon(Icons.qr_code_2_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        tooltip: 'Generate barcode',
                        onPressed: () {
                          final code = _generateBarcode();
                          setDialogState(() {
                            barcodeCtrl.text = code;
                          });
                        },
                        icon: const Icon(Icons.auto_fix_high_rounded),
                      ),
                      IconButton(
                        tooltip: 'Scan barcode',
                        onPressed: () => _scanBarcodeIntoField(
                          ctx,
                          setDialogState,
                          barcodeCtrl,
                        ),
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                      ),
                    ],
                  ),
                  if (barcodeCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: barcodeCtrl.text.trim(),
                      height: 70,
                      width: 260,
                      drawText: false,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: lowCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Low stock threshold',
                            prefixIcon: Icon(Icons.trending_down_rounded),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = double.tryParse(v.trim());
                            if (parsed != null) _lowStockThreshold = parsed;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: criticalCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Critical stock threshold',
                            prefixIcon: Icon(Icons.priority_high_rounded),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            final parsed = double.tryParse(v.trim());
                            if (parsed != null) {
                              _criticalStockThreshold = parsed;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                final updated = product.copyWith(
                  name: nameCtrl.text.trim(),
                  category: categoryCtrl.text.trim().isEmpty
                      ? null
                      : categoryCtrl.text.trim(),
                  subcategory: subcategoryCtrl.text.trim().isEmpty
                      ? null
                      : subcategoryCtrl.text.trim(),
                  colorLabel: colorCtrl.text.trim().isEmpty
                      ? null
                      : colorCtrl.text.trim(),
                  barcode: barcodeCtrl.text.trim().isEmpty
                      ? null
                      : barcodeCtrl.text.trim(),
                  rate: double.parse(rateCtrl.text.trim()),
                  size: double.parse(sizeCtrl.text.trim()),
                  unit: _selectedUnit,
                  lowStockThreshold: _lowStockThreshold,
                  criticalStockThreshold: _criticalStockThreshold,
                  updatedAt: now,
                );
                final ok = await context
                    .read<StoreProductProvider>()
                    .updateProduct(updated);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(ok ? 'Updated' : 'Update failed'),
                      backgroundColor: ok
                          ? Colors.green
                          : Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<StoreProduct> _applyFilters(List<StoreProduct> products) {
    final q = _query.trim().toLowerCase();
    return products.where((p) {
      if (_filterCategory != null &&
          (_filterCategory!.isNotEmpty) &&
          (p.category ?? '').trim().toLowerCase() !=
              _filterCategory!.trim().toLowerCase()) {
        return false;
      }
      if (_filterSubcategory != null &&
          (_filterSubcategory!.isNotEmpty) &&
          (p.subcategory ?? '').trim().toLowerCase() !=
              _filterSubcategory!.trim().toLowerCase()) {
        return false;
      }
      if (_filterColorLabel != null &&
          (_filterColorLabel!.isNotEmpty) &&
          (p.colorLabel ?? '').trim().toLowerCase() !=
              _filterColorLabel!.trim().toLowerCase()) {
        return false;
      }

      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          (p.category ?? '').toLowerCase().contains(q) ||
          (p.subcategory ?? '').toLowerCase().contains(q) ||
          (p.barcode ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String? _cleanOrNull(String value) {
    final cleaned = value.trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String _activeFiltersLabel() {
    final parts = <String>[];
    if (_filterCategory != null && _filterCategory!.trim().isNotEmpty) {
      parts.add(_filterCategory!.trim());
    }
    if (_filterSubcategory != null && _filterSubcategory!.trim().isNotEmpty) {
      parts.add(_filterSubcategory!.trim());
    }
    if (_filterColorLabel != null && _filterColorLabel!.trim().isNotEmpty) {
      parts.add(_filterColorLabel!.trim());
    }
    return parts.join(' · ');
  }

  void _clearFilters() {
    setState(() {
      _filterCategory = null;
      _filterSubcategory = null;
      _filterColorLabel = null;
    });
  }

  Future<void> _openFiltersDialog(
    BuildContext context,
    List<StoreProduct> products,
  ) async {
    final categories = products
        .map((p) => p.category?.trim())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final subcategories = products
        .map((p) => p.subcategory?.trim())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final colors = products
        .map((p) => p.colorLabel?.trim())
        .whereType<String>()
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    String? nextCategory = _filterCategory;
    String? nextSubcategory = _filterSubcategory;
    String? nextColor = _filterColorLabel;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Filter'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: (nextCategory != null && nextCategory!.isNotEmpty)
                    ? nextCategory
                    : null,
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('All categories')),
                  ...categories.map(
                    (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setDialogState(() => nextCategory = v),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue:
                    (nextSubcategory != null && nextSubcategory!.isNotEmpty)
                        ? nextSubcategory
                        : null,
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('All subcategories')),
                  ...subcategories.map(
                    (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setDialogState(() => nextSubcategory = v),
                decoration: const InputDecoration(labelText: 'Subcategory'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: (nextColor != null && nextColor!.isNotEmpty)
                    ? nextColor
                    : null,
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('All colors')),
                  ...colors.map(
                    (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setDialogState(() => nextColor = v),
                decoration: const InputDecoration(labelText: 'Color label'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  _filterCategory = nextCategory;
                  _filterSubcategory = nextSubcategory;
                  _filterColorLabel = nextColor;
                });
                Navigator.pop(ctx);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  String _generateBarcode() {
    final rng = Random.secure();
    final code = List.generate(12, (_) => rng.nextInt(10)).join();
    return code;
  }

  Future<void> _scanBarcodeAndSearch(
    BuildContext context,
    List<StoreProduct> products,
  ) async {
    final res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Scan Barcode',
        centerTitle: true,
        enableBackButton: true,
      ),
      isShowFlashIcon: true,
      delayMillis: 1200,
    );

    final code = (res ?? '').trim();
    if (!context.mounted || code.isEmpty || code == '-1') return;

    final matched =
        products.where((p) => (p.barcode ?? '').trim() == code).toList();
    if (matched.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No product found for barcode: $code'),
          ),
        );
      }
      return;
    }

    setState(() {
      _query = code;
      _searchCtrl.text = code;
    });
  }

  Future<void> _scanBarcodeIntoField(
    BuildContext context,
    StateSetter setDialogState,
    TextEditingController barcodeCtrl,
  ) async {
    final res = await SimpleBarcodeScanner.scanBarcode(
      context,
      barcodeAppBar: const BarcodeAppBar(
        appBarTitle: 'Scan Barcode',
        centerTitle: true,
        enableBackButton: true,
      ),
      isShowFlashIcon: true,
      delayMillis: 1200,
    );

    final code = (res ?? '').trim();
    if (code.isEmpty || code == '-1') return;
    setDialogState(() {
      barcodeCtrl.text = code;
    });
  }

  Future<void> _deleteProduct(BuildContext context, StoreProductProvider prov,
      StoreProduct product) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Product',
      content: 'Remove "${product.name}" from inventory?',
      confirmText: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    final ok = await prov.deleteProduct(product.id!);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(ok ? '${product.name} deleted' : prov.error ?? 'Failed'),
          backgroundColor: ok ? null : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '\u20B9 ${product.rate.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ ${product.size} ${product.unit}',
                          style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.5),
                              fontSize: 12),
                        ),
                      ],
                    ),
                    if ((product.category ?? '').trim().isNotEmpty ||
                        (product.subcategory ?? '').trim().isNotEmpty ||
                        (product.colorLabel ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if ((product.category ?? '').trim().isNotEmpty)
                            _MetaChip(
                              label: product.category!.trim(),
                              icon: Icons.category_outlined,
                            ),
                          if ((product.subcategory ?? '').trim().isNotEmpty)
                            _MetaChip(
                              label: product.subcategory!.trim(),
                              icon: Icons.segment_outlined,
                            ),
                          if ((product.colorLabel ?? '').trim().isNotEmpty)
                            _MetaChip(
                              label: product.colorLabel!.trim(),
                              icon: Icons.label_outline,
                            ),
                        ],
                      ),
                    ],
                    if ((product.barcode ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Barcode: ${product.barcode}',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: cs.error.withValues(alpha: 0.7)),
                onPressed: onDelete,
                tooltip: 'Delete',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.onSurface.withValues(alpha: 0.6)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: cs.onSurface.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilters;
  final String activeFilters;
  final VoidCallback onClearFilters;

  const _SearchAndFilterBar({
    required this.controller,
    required this.onQueryChanged,
    required this.onOpenFilters,
    required this.activeFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    final search = TextField(
      onChanged: onQueryChanged,
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search by name, category, or barcode',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  controller.clear();
                  onQueryChanged('');
                },
              ),
      ),
    );

    final filtersBtn = OutlinedButton.icon(
      onPressed: onOpenFilters,
      icon: const Icon(Icons.filter_list_rounded, size: 18),
      label: const Text('Filter'),
    );

    final clearBtn = activeFilters.isEmpty
        ? null
        : TextButton(
            onPressed: onClearFilters,
            child: const Text('Clear filters'),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWide)
          Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 10),
              filtersBtn,
            ],
          )
        else ...[
          search,
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: filtersBtn),
              if (clearBtn != null) ...[
                const SizedBox(width: 8),
                clearBtn,
              ],
            ],
          ),
        ],
        if (activeFilters.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.tune_rounded,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activeFilters,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              if (clearBtn != null && isWide) clearBtn,
            ],
          ),
        ],
      ],
    );
  }
}
