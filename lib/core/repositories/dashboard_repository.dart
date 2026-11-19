import '../database/database_helper.dart';

/// Repository layer for cross-domain read queries (dashboard aggregates and
/// charts) plus the bulk import/export used by the sync engine.
///
/// Charts aggregate across sites/workers/attendance/payments, so they don't
/// fit a single domain repository — they live here.
class DashboardRepository {
  final _db = DatabaseHelper();

  // ─────────────── DASHBOARD STATS ───────────────

  Future<Map<String, dynamic>> getDashboardStats() => _db.getDashboardStats();

  // ─────────────── CHART DATA ───────────────

  Future<List<Map<String, dynamic>>> getAttendanceChartData() =>
      _db.getAttendanceChartData();

  Future<List<Map<String, dynamic>>> getSiteProgressChartData() =>
      _db.getSiteProgressChartData();

  Future<List<Map<String, dynamic>>> getMaterialUsageChartData() =>
      _db.getMaterialUsageChartData();

  Future<List<Map<String, dynamic>>> getExpensesChartData() =>
      _db.getExpensesChartData();

  Future<List<Map<String, dynamic>>> getPaymentsChartData() =>
      _db.getPaymentsChartData();

  // ─────────────── BULK SYNC (used by cloud + local sync) ───────────────

  Future<bool> hasUserData(int userId) => _db.hasUserData(userId);

  /// Per-table record counts for the cloud sync service's empty-upload guard
  /// and diagnostics. SQLite access lives in [DatabaseHelper].
  Future<Map<String, int>> countUserRecords(int userId) =>
      _db.countUserRecords(userId);

  Future<Map<String, dynamic>> exportUserData(int userId) =>
      _db.exportUserData(userId);

  Future<void> replaceUserData(int userId, Map<String, dynamic> data) =>
      _db.replaceUserData(userId, data);
}
