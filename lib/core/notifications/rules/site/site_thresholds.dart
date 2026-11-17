/// Configurable global thresholds for Phase 4 site rules.
///
/// Per-site values (deadline, budget, completion) come from the [SiteModel]
/// itself. This holder carries the global thresholds that have no per-site
/// field yet (completion tiers, deadline warning window, inactivity window).
/// All values are overridable so the rules are fully configurable without
/// touching the schema or the framework.
class SiteThresholds {
  const SiteThresholds({
    this.completionNear1 = 90.0,
    this.completionNear2 = 95.0,
    this.deadlineWarningDays = 7,
    this.inactiveDays = 30,
  });

  /// First "nearing completion" tier (default 90%).
  final double completionNear1;
  /// Second "nearing completion" tier (default 95%).
  final double completionNear2;
  /// A site's deadline is "approaching" within this many days.
  final int deadlineWarningDays;
  /// A site is "inactive" when its `updatedAt` is older than this many days.
  final int inactiveDays;
}
