import '../database/database_helper.dart';
import '../models/advance_payment_model.dart';
import '../models/attendance_model.dart';
import '../models/site_model.dart';
import '../models/worker_document_model.dart';
import '../models/worker_model.dart';
import '../models/worker_performance_model.dart';

/// Repository layer for worker-centric data: workers, documents, performance,
/// attendance and advance payments.
///
/// Providers access worker data only through this repository.
class WorkerRepository {
  final _db = DatabaseHelper();

  // ─────────────── WORKERS ───────────────

  Future<List<WorkerModel>> getAllWorkers() => _db.getAllWorkers();

  Future<WorkerModel?> getWorkerById(int id) => _db.getWorkerById(id);

  Future<int> insertWorker(WorkerModel worker) => _db.insertWorker(worker);

  Future<int> updateWorker(WorkerModel worker) => _db.updateWorker(worker);

  Future<int> deleteWorker(int id) => _db.deleteWorker(id);

  // ─────────────── WORKER DOCUMENTS ───────────────

  Future<List<WorkerDocument>> getWorkerDocuments(int workerId) =>
      _db.getWorkerDocuments(workerId);

  Future<WorkerDocument?> getWorkerDocumentByType(
          int workerId, String documentType) =>
      _db.getWorkerDocumentByType(workerId, documentType);

  Future<int> insertWorkerDocument(WorkerDocument document) =>
      _db.insertWorkerDocument(document);

  Future<int> deleteWorkerDocument(int id) => _db.deleteWorkerDocument(id);

  Future<int> deleteWorkerDocumentsByWorker(int workerId) =>
      _db.deleteWorkerDocumentsByWorker(workerId);

  // ─────────────── WORKER PERFORMANCE ───────────────

  Future<List<WorkerPerformance>> getWorkerPerformance(int workerId) =>
      _db.getWorkerPerformance(workerId);

  Future<WorkerPerformance?> getWorkerPerformanceForMonth(
          int workerId, DateTime month) =>
      _db.getWorkerPerformanceForMonth(workerId, month);

  Future<int> insertWorkerPerformance(WorkerPerformance performance) =>
      _db.insertWorkerPerformance(performance);

  Future<int> updateWorkerPerformance(WorkerPerformance performance) =>
      _db.updateWorkerPerformance(performance);

  Future<int> deleteWorkerPerformance(int id) =>
      _db.deleteWorkerPerformance(id);

  Future<int> deleteWorkerPerformanceByWorker(int workerId) =>
      _db.deleteWorkerPerformanceByWorker(workerId);

  // ─────────────── ATTENDANCE ───────────────

  Future<List<AttendanceModel>> getAttendanceByWorker(
          int workerId, {int? year, int? month}) =>
      _db.getAttendanceByWorker(workerId, year: year, month: month);

  Future<AttendanceModel?> getAttendance(int workerId, String date) =>
      _db.getAttendance(workerId, date);

  Future<List<Map<String, dynamic>>> getSiteAttendanceForDate(
          int siteId, String date) =>
      _db.getSiteAttendanceForDate(siteId, date);

  Future<int> upsertAttendance(AttendanceModel att) =>
      _db.upsertAttendance(att);

  Future<Map<String, int>> getMonthlyAttendanceSummary(
          int workerId, int year, int month) =>
      _db.getMonthlyAttendanceSummary(workerId, year, month);

  // ─────────────── ADVANCES ───────────────

  Future<List<AdvancePaymentModel>> getAdvancesByWorker(int workerId) =>
      _db.getAdvancesByWorker(workerId);

  Future<List<AdvancePaymentModel>> getAllPendingAdvances() =>
      _db.getAllPendingAdvances();

  Future<int> insertAdvance(AdvancePaymentModel advance) =>
      _db.insertAdvance(advance);

  Future<int> approveAdvance(int advanceId) => _db.approveAdvance(advanceId);

  Future<int> rejectAdvance(int advanceId) => _db.rejectAdvance(advanceId);

  Future<double> getApprovedAdvancesTotal(int workerId,
          {int? year, int? month}) =>
      _db.getApprovedAdvancesTotal(workerId, year: year, month: month);

  Future<List<SiteModel>> getSitesByWorker(int workerId) =>
      _db.getSitesByWorker(workerId);
}
