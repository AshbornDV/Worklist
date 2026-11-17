import '../../models/notification_model.dart';
import '../../../repositories/inventory_repository.dart';
import 'inventory_rule_base.dart';
import 'inventory_thresholds.dart';

/// Scans the store inventory and emits reminders for the four stock-state
/// conditions:
///
///  • **Minimum Quantity** — stock has dropped to (or below) the product's
///    configured `lowStockThreshold` (the "Minimum Stock" the user set).
///  • **Low Stock**        — stock is below the minimum but still above the
///    `criticalStockThreshold` (the intermediate "getting low" tier).
///  • **Out Of Stock**     — stock is at/below zero.
///  • **Overstock**        — stock exceeds the configurable overstock ceiling
///    (`lowStockThreshold * overstockMultiplier`).
///
/// All thresholds are configurable: per-product minimums come from the data
/// model; the global overstock ceiling comes from [InventoryThresholds].
/// Read-only rule — the engine deduplicates/delivers.
class StockStateInventoryRule extends InventoryRuleBase {
  StockStateInventoryRule({
    required InventoryRepository inventoryRepository,
    this.thresholds = const InventoryThresholds(),
    super.now,
  })  : _inventoryRepository = inventoryRepository,
        super(id: 'inventory_stock_state');

  final InventoryRepository _inventoryRepository;
  final InventoryThresholds thresholds;

  @override
  Future<List<AppNotification>> evaluate() async {
    final products = await _inventoryRepository.getAllStoreProducts();
    final out = <AppNotification>[];

    for (final p in products) {
      if (p.id == null) continue;
      final name = p.name;
      final id = p.id!;

      // Minimum Quantity: at/below the configured minimum.
      if (p.stock <= p.lowStockThreshold) {
        out.add(
          build(
            productId: id,
            productName: name,
            subKey: 'minimum_quantity',
            title: 'Minimum quantity reached · $name',
            body:
                'Current stock ${_q(p.stock)} is at/below the minimum (${_q(p.lowStockThreshold)} ${p.unit}). Reorder soon.',
            priority: NotificationPriority.high,
          ),
        );
      }

      // Low Stock: between critical and low thresholds (exclusive of the
      // minimum boundary, which the Minimum-Quantity rule already covers).
      if (p.stock > p.criticalStockThreshold && p.stock < p.lowStockThreshold) {
        out.add(
          build(
            productId: id,
            productName: name,
            subKey: 'low_stock',
            title: 'Low stock · $name',
            body:
                'Only ${_q(p.stock)} ${p.unit} left (low threshold ${_q(p.lowStockThreshold)}).',
            priority: NotificationPriority.high,
          ),
        );
      }

      // Out Of Stock: zero or negative.
      if (p.isOutOfStock) {
        out.add(
          build(
            productId: id,
            productName: name,
            subKey: 'out_of_stock',
            title: 'Out of stock · $name',
            body: '$name is out of stock. Restock required.',
            priority: NotificationPriority.critical,
          ),
        );
      }

      // Overstock: above the configurable ceiling.
      final ceiling = p.lowStockThreshold * thresholds.overstockMultiplier;
      if (p.stock > ceiling) {
        out.add(
          build(
            productId: id,
            productName: name,
            subKey: 'overstock',
            title: 'Overstock · $name',
            body:
                'Stock ${_q(p.stock)} ${p.unit} exceeds the overstock ceiling (${_q(ceiling)}). Consider redistributing.',
            priority: NotificationPriority.normal,
          ),
        );
      }
    }
    return out;
  }

  String _q(double v) => v.toStringAsFixed(0);
}
