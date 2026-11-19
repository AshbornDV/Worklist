import '../../../models/store_product_model.dart';
import '../../../repositories/inventory_repository.dart';
import '../../models/notification_model.dart';
import 'inventory_rule_base.dart';
import 'inventory_thresholds.dart';

/// Reminds about inventory records that have not been updated in a while.
/// A product is "stale" when its [StoreProduct.updatedAt] is older than
/// [InventoryThresholds.staleAfterDays]. Stale records risk drift between the
/// real shelf and the system, so a nudge to review/refresh them is useful.
///
/// Read-only rule — the engine deduplicates/delivers.
class MaterialNotUpdatedRule extends InventoryRuleBase {
  MaterialNotUpdatedRule({
    required InventoryRepository inventoryRepository,
    this.thresholds = const InventoryThresholds(),
    super.now,
  })  : _inventoryRepository = inventoryRepository,
        super(id: 'inventory_material_not_updated');

  final InventoryRepository _inventoryRepository;
  final InventoryThresholds thresholds;

  @override
  Future<List<AppNotification>> evaluate() async {
    final products = await _inventoryRepository.getAllStoreProducts();
    final cutoff = now.subtract(Duration(days: thresholds.staleAfterDays));
    final out = <AppNotification>[];

    for (final p in products) {
      if (p.id == null) continue;
      if (!p.updatedAt.isBefore(cutoff)) continue;

      final days = now.difference(p.updatedAt).inDays;
      out.add(
        build(
          productId: p.id!,
          productName: p.name,
          subKey: 'material_not_updated',
          title: 'Material not updated · ${p.name}',
          body:
              '${p.name} has not been updated in $days days. Verify the stock record is still accurate.',
          priority: NotificationPriority.normal,
          extra: {'daysSinceUpdate': days},
        ),
      );
    }
    return out;
  }
}
