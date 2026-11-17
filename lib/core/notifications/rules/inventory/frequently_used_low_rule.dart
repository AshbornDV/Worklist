import '../../models/notification_model.dart';
import '../../../repositories/inventory_repository.dart';
import 'inventory_rule_base.dart';
import 'inventory_thresholds.dart';

/// Reminds about a frequently-used item that is running low. A product is
/// "frequently used" when the total quantity [InventoryRepository.getTotalSentToSites]
/// reaches the configurable [InventoryThresholds.frequentlyUsedSentThreshold],
/// and it is "running low" when its stock is at/below its `lowStockThreshold`.
///
/// The two conditions together surface the high-turnover items most likely to
/// cause a stockout — the ones you want to reorder first.
///
/// Read-only rule — the engine deduplicates/delivers.
class FrequentlyUsedLowRule extends InventoryRuleBase {
  FrequentlyUsedLowRule({
    required InventoryRepository inventoryRepository,
    this.thresholds = const InventoryThresholds(),
    super.now,
  })  : _inventoryRepository = inventoryRepository,
        super(id: 'inventory_frequently_used_low');

  final InventoryRepository _inventoryRepository;
  final InventoryThresholds thresholds;

  @override
  Future<List<AppNotification>> evaluate() async {
    final products = await _inventoryRepository.getAllStoreProducts();
    final out = <AppNotification>[];

    for (final p in products) {
      if (p.id == null) continue;
      // Already handled by the dedicated out-of-stock / minimum-quantity rules.
      if (p.stock > p.lowStockThreshold) continue;

      final sent = await _inventoryRepository.getTotalSentToSites(p.id!);
      if (sent < thresholds.frequentlyUsedSentThreshold) continue;

      out.add(
        build(
          productId: p.id!,
          productName: p.name,
          subKey: 'frequently_used_low',
          title: 'Frequently used item running low · ${p.name}',
          body:
              '${p.name} has high usage (${sent.toStringAsFixed(0)} sent to sites) and only ${p.stock.toStringAsFixed(0)} ${p.unit} left. Prioritise reorder.',
          priority: NotificationPriority.high,
          extra: {'totalSentToSites': sent},
        ),
      );
    }
    return out;
  }
}
