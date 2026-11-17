import 'package:flutter_test/flutter_test.dart';
import 'package:worklist/core/models/store_product_model.dart';
import 'harness.dart';

/// Stable product columns for an inventory observation.
///
/// `created_at`/`updated_at` are deliberately omitted: deductStoreStock and
/// restoreStoreStock write `updated_at = DateTime.now()`, so including either
/// timestamp would make the golden drift on every run.
Map<String, Object?> observedProduct(StoreProduct p) => {
      'id': p.id,
      'name': p.name,
      'barcode': p.barcode,
      'rate': p.rate,
      'unit': p.unit,
      'stock': p.stock,
      'lowStockThreshold': p.lowStockThreshold,
      'criticalStockThreshold': p.criticalStockThreshold,
    };

void main() {
  test('inventory mutations, stock alerts and barcode lookup match frozen Flutter output',
      () async {
    final db = await openSeeded();

    final byName = {for (final p in await db.getAllStoreProducts()) p.name: p};
    final cementId = byName['Cement']!.id!;
    final steelId = byName['Steel Rod']!.id!;
    final paintId = byName['Paint']!.id!;

    // Cement: 40 - 38 = 2.0
    await db.deductStoreStock(cementId, 38);

    // Paint stock is 1. deductStoreStock uses `WHERE stock >= ?` and throws
    // when 0 rows are affected - it must NOT clamp to zero (R13).
    String? paintError;
    try {
      await db.deductStoreStock(paintId, 2);
    } catch (e) {
      paintError = e.toString();
    }
    final paintDeductionRejected =
        paintError?.contains('Insufficient stock or product not found.') ??
            false;
    expect(paintDeductionRejected, isTrue,
        reason: 'deductStoreStock must throw R13 message on insufficient stock');

    // Steel Rod: 5 - 1 = 4.0, then 4.0 + 3 = 7.0
    await db.deductStoreStock(steelId, 1);
    await db.restoreStoreStock(steelId, 3);

    final cement = await db.getStoreProductById(cementId);
    final steel = await db.getStoreProductById(steelId);
    final paint = await db.getStoreProductById(paintId);

    // Non-vacuous: Paint was not modified by the rejected deduction.
    expect(paint?.stock, 1.0);

    final barcodeMatch = await db.getStoreProductByBarcode('CEM-001');

    expectGolden('inventory.stock-after-mutations', {
      'cementStock': cement?.stock,
      'steelRodStock': steel?.stock,
      'paintStock': paint?.stock,
      'paintDeductionRejected': paintDeductionRejected,
      'barcodeLookup':
          barcodeMatch == null ? null : observedProduct(barcodeMatch),
    });

    expectGolden('inventory.alerts',
        (await db.getStockAlertProducts()).map(observedProduct).toList());
  });

  test('duplicate store product name is rejected', () async {
    final db = await openSeeded();

    var duplicateProductRejected = false;
    try {
      // insertStoreProduct is a plain insert against UNIQUE(user_id, name) -
      // unlike attendance it does not replace an existing row.
      await db.insertStoreProduct(StoreProduct(
        name: 'Cement',
        barcode: 'CEM-DUP',
        rate: 550,
        unit: 'bag',
        stock: 5,
        createdAt: DateTime(2026, 2, 1, 8),
        updatedAt: DateTime(2026, 2, 1, 8),
      ));
    } catch (_) {
      duplicateProductRejected = true;
    }

    expect(duplicateProductRejected, isTrue,
        reason: 'a second store product named Cement must be rejected');

    expectGolden('inventory.duplicate-product', {
      'duplicateProductRejected': duplicateProductRejected,
    });
  });
}
