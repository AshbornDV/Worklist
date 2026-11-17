/// Configurable global thresholds for Phase 3 inventory rules.
///
/// Per-product thresholds come from the [StoreProduct] itself
/// (`lowStockThreshold`, `criticalStockThreshold`) — those are the values the
/// user edits in the inventory screen, e.g. minimum stock 20, current 12.
///
/// This holder carries the *global* thresholds that have no per-product field
/// yet (overstock ceiling, frequent-usage cutoff, staleness, audit cadence).
/// All values are overridable so the rules are fully configurable without
/// touching the schema or the framework.
class InventoryThresholds {
  const InventoryThresholds({
    this.overstockMultiplier = 10.0,
    this.frequentlyUsedSentThreshold = 50.0,
    this.staleAfterDays = 30,
    this.auditIntervalDays = 30,
  });

  /// A product is "overstocked" when its stock exceeds
  /// `lowStockThreshold * overstockMultiplier`.
  final double overstockMultiplier;

  /// A product counts as "frequently used" when total quantity sent to sites
  /// reaches this amount.
  final double frequentlyUsedSentThreshold;

  /// A product is "not updated" (material staleness) when its `updatedAt` is
  /// older than this many days.
  final int staleAfterDays;

  /// Inventory audit reminder cadence, in days.
  final int auditIntervalDays;
}
