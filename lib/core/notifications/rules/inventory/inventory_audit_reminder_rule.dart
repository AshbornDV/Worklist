import '../../../repositories/inventory_repository.dart';
import '../../models/notification_model.dart';
import 'inventory_rule_base.dart';
import 'inventory_thresholds.dart';

/// Periodic inventory audit reminder. There is no audit-date field in the
/// schema, so the cadence is derived: the rule fires once per
/// [InventoryThresholds.auditIntervalDays] window. The [NotificationModel.id]
/// is keyed by the current audit-cycle bucket, so the engine's dedupe prevents
/// the same cycle's reminder from being sent twice — and the next cycle (a
/// different bucket) naturally re-triggers it.
///
/// The reminder also surfaces how many products are stale, to make the audit
/// actionable.
///
/// Read-only rule — the engine deduplicates/delivers.
class InventoryAuditReminderRule extends InventoryRuleBase {
  InventoryAuditReminderRule({
    required InventoryRepository inventoryRepository,
    this.thresholds = const InventoryThresholds(),
    super.now,
  })  : _inventoryRepository = inventoryRepository,
        super(id: 'inventory_audit_reminder');

  final InventoryRepository _inventoryRepository;
  final InventoryThresholds thresholds;

  /// Bucket index for the current audit cycle (epoch days / interval).
  int _cycleBucket(DateTime t) =>
      t.millisecondsSinceEpoch ~/
      (thresholds.auditIntervalDays * Duration.millisecondsPerDay);

  @override
  Future<List<AppNotification>> evaluate() async {
    final bucket = _cycleBucket(now);
    final products = await _inventoryRepository.getAllStoreProducts();
    final cutoff = now.subtract(Duration(days: thresholds.staleAfterDays));
    final staleCount =
        products.where((p) => p.updatedAt.isBefore(cutoff)).length;

    return [
      build(
        productId: bucket,
        productName: 'Store inventory',
        subKey: 'audit_cycle_$bucket',
        title: 'Inventory audit due',
        body: staleCount > 0
            ? 'Scheduled audit: $staleCount item(s) have not been updated recently. Review stock now.'
            : 'Scheduled inventory audit is due. Verify stock levels across the store.',
        priority: NotificationPriority.normal,
        extra: {
          'cycleBucket': bucket,
          'staleCount': staleCount,
          'intervalDays': thresholds.auditIntervalDays,
        },
      ),
    ];
  }
}
