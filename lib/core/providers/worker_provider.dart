import 'package:flutter/foundation.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/advance_payment_model.dart';
import '../models/attendance_model.dart';
import '../models/payroll_model.dart';
import '../models/site_model.dart';
import '../models/worker_document_model.dart';
import '../models/worker_model.dart';
import '../models/worker_performance_model.dart';
import '../repositories/worker_repository.dart';
import '../repositories/payroll_repository.dart';

class WorkerPaycheck {
  final int workerId;
  final int year;
  final int month;
  final int fullDays;
  final int halfDays;
  final double dailyRate;
  final double grossEarnings;
  final double totalAdvances;
  final double netPayable;

  const WorkerPaycheck({
    required this.workerId,
    required this.year,
    required this.month,
    required this.fullDays,
    required this.halfDays,
    required this.dailyRate,
    required this.grossEarnings,
    required this.totalAdvances,
    required this.netPayable,
  });

  int get totalDaysWorked => fullDays + halfDays;
  bool get hasDebt => netPayable < 0;
}

class WorkerProvider extends ChangeNotifier {
  final _repo = WorkerRepository();
  final _payroll = PayrollRepository();
  final _cloud = FirebaseCloudService.instance;

  List<WorkerModel> _workers = [];
  List<AttendanceModel> _attendanceRecords = [];
  List<AdvancePaymentModel> _advances = [];
  List<AdvancePaymentModel> _pendingAdvances = [];
  bool _workersLoading = false;
  String? _error;

  /// Incremented by [clear] to invalidate all in-flight async loads,
  /// preventing stale previous-user data from being written back after logout.
  int _generation = 0;

  List<WorkerModel> get workers => List.unmodifiable(_workers);
  List<AttendanceModel> get attendanceRecords =>
      List.unmodifiable(_attendanceRecords);
  List<AdvancePaymentModel> get advances => List.unmodifiable(_advances);
  List<AdvancePaymentModel> get pendingAdvances =>
      List.unmodifiable(_pendingAdvances);

  /// True while the workers list is loading (used by WorkersListScreen).
  bool get isLoading => _workersLoading;

  String? get error => _error;

  int get activeWorkerCount =>
      _workers.where((w) => w.status == 'active').length;

  /// Clears all cached data and invalidates any in-flight loads.
  /// Call this on logout so stale previous-user data never appears.
  void clear() {
    _generation++;
    _workers = [];
    _attendanceRecords = [];
    _advances = [];
    _pendingAdvances = [];
    _workersLoading = false;
    _error = null;
    notifyListeners();
  }

  // ─────────────── WORKERS ───────────────

  Future<void> loadWorkers() async {
    final gen = _generation;
    _workersLoading = true;
    notifyListeners();
    try {
      final result = await _repo.getAllWorkers();
      if (_generation != gen) return;
      _workers = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        _workersLoading = false;
        notifyListeners();
      }
    }
  }

  Future<WorkerModel?> getWorker(int id) => _repo.getWorkerById(id);

  Future<bool> addWorker(WorkerModel worker) async {
    try {
      final id = await _repo.insertWorker(worker);
      _workers.add(worker.copyWith(id: id));
      _workers.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorker(WorkerModel worker) async {
    try {
      await _repo.updateWorker(worker);
      final idx = _workers.indexWhere((w) => w.id == worker.id);
      if (idx != -1) _workers[idx] = worker;
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorker(int id) async {
    try {
      await _repo.deleteWorker(id);
      await _repo.deleteWorkerDocumentsByWorker(id);
      await _repo.deleteWorkerPerformanceByWorker(id);
      _workers.removeWhere((w) => w.id == id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<WorkerModel>> searchWorkers(String query) async {
    if (query.isEmpty) return _workers;
    final lowerQuery = query.toLowerCase();
    return _workers
        .where((w) =>
            w.name.toLowerCase().contains(lowerQuery) ||
            w.phone.contains(query) ||
            w.trade.toLowerCase().contains(lowerQuery))
        .toList();
  }

  // ─────────────── WORKER DOCUMENTS ───────────────

  Future<List<WorkerDocument>> getWorkerDocuments(int workerId) async {
    return _repo.getWorkerDocuments(workerId);
  }

  Future<WorkerDocument?> getWorkerDocumentByType(
    int workerId,
    String documentType,
  ) async {
    return _repo.getWorkerDocumentByType(workerId, documentType);
  }

  Future<bool> addWorkerDocument(WorkerDocument document) async {
    try {
      await _repo.insertWorkerDocument(document);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkerDocument(int id) async {
    try {
      await _repo.deleteWorkerDocument(id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── WORKER PERFORMANCE ───────────────

  Future<List<WorkerPerformance>> getWorkerPerformance(int workerId) async {
    return _repo.getWorkerPerformance(workerId);
  }

  Future<WorkerPerformance?> getWorkerPerformanceForMonth(
    int workerId,
    DateTime month,
  ) async {
    return _repo.getWorkerPerformanceForMonth(workerId, month);
  }

  Future<bool> addWorkerPerformance(WorkerPerformance performance) async {
    try {
      await _repo.insertWorkerPerformance(performance);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateWorkerPerformance(WorkerPerformance performance) async {
    try {
      await _repo.updateWorkerPerformance(performance);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteWorkerPerformance(int id) async {
    try {
      await _repo.deleteWorkerPerformance(id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── PAYROLL ───────────────

  Future<List<PayrollModel>> getPayrollForMonth(DateTime month) async {
    return _payroll.getPayrollForMonth(month);  }

  Future<PayrollModel?> getPayroll(int workerId, DateTime month) async {
    return _payroll.getPayroll(workerId, month);
  }

  /// Auto-fills attendance & advance data, then returns a PayrollModel with
  /// editable fields defaulted to zero.
  Future<PayrollModel> generatePayroll(
    WorkerModel worker,
    int year,
    int month,
  ) async {
    final summary =
        await _repo.getMonthlyAttendanceSummary(worker.id!, year, month);
    final fullDays = summary['full'] ?? 0;
    final halfDays = summary['half'] ?? 0;
    final advances = await _repo.getApprovedAdvancesTotal(
      worker.id!,
      year: year,
      month: month,
    );

    final baseWage =
        (fullDays * worker.dailyRate) + (halfDays * worker.halfDayRate);
    final netSalary = baseWage - advances;

    return PayrollModel(
      workerId: worker.id!,
      month: DateTime(year, month, 1),
      fullDays: fullDays,
      halfDays: halfDays,
      dailyRate: worker.dailyRate,
      overtimeHours: 0.0,
      overtimeRate: worker.overtimeRate,
      advanceAmount: advances,
      bonus: 0.0,
      deductions: 0.0,
      netSalary: netSalary < 0 ? 0.0 : netSalary,
      status: 'draft',
      notes: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Inserts or updates a payroll record and triggers cloud sync.
  Future<bool> savePayroll(PayrollModel payroll) async {
    try {
      if (payroll.id != null) {
        await _payroll.updatePayroll(payroll);
      } else {
        await _payroll.insertPayroll(payroll);
      }
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePayroll(int id) async {
    try {
      await _payroll.deletePayroll(id);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markPayrollPaid(int id) async {
    try {
      await _payroll.setPayrollStatus(id, 'paid');
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── ATTENDANCE ───────────────

  Future<void> loadAttendance(int workerId, {int? year, int? month}) async {
    final gen = _generation;
    notifyListeners();
    try {
      final result = await _repo.getAttendanceByWorker(
        workerId,
        year: year,
        month: month,
      );
      if (_generation != gen) return;
      _attendanceRecords = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        notifyListeners();
      }
    }
  }

  Future<List<Map<String, dynamic>>> getSiteAttendanceForDate(
    int siteId,
    String date,
  ) async {
    return _repo.getSiteAttendanceForDate(siteId, date);
  }

  Future<bool> recordAttendance(AttendanceModel attendance) async {
    try {
      await _repo.upsertAttendance(attendance);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── ADVANCES ───────────────

  Future<void> loadAdvances(int workerId) async {
    final gen = _generation;
    notifyListeners();
    try {
      final result = await _repo.getAdvancesByWorker(workerId);
      if (_generation != gen) return;
      _advances = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        notifyListeners();
      }
    }
  }

  Future<void> loadPendingAdvances() async {
    final gen = _generation;
    notifyListeners();
    try {
      final result = await _repo.getAllPendingAdvances();
      if (_generation != gen) return;
      _pendingAdvances = result;
    } catch (e) {
      if (_generation != gen) return;
      _error = e.toString();
    } finally {
      if (_generation == gen) {
        notifyListeners();
      }
    }
  }

  Future<bool> requestAdvance(AdvancePaymentModel advance) async {
    try {
      final id = await _repo.insertAdvance(advance);
      _advances.insert(0, advance.copyWith(id: id));
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveAdvance(int advanceId) async {
    try {
      await _repo.approveAdvance(advanceId);
      final idx = _advances.indexWhere((a) => a.id == advanceId);
      if (idx != -1) {
        _advances[idx] = _advances[idx].copyWith(
          status: 'approved',
          approvedDate: DateTime.now(),
        );
      }
      _pendingAdvances.removeWhere((a) => a.id == advanceId);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectAdvance(int advanceId) async {
    try {
      await _repo.rejectAdvance(advanceId);
      final idx = _advances.indexWhere((a) => a.id == advanceId);
      if (idx != -1) {
        _advances[idx] = _advances[idx].copyWith(status: 'rejected');
      }
      _pendingAdvances.removeWhere((a) => a.id == advanceId);
      notifyListeners();
      _syncCloud();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─────────────── PAYCHECK ───────────────

  Future<WorkerPaycheck> calculatePaycheck(
    WorkerModel worker,
    int year,
    int month,
  ) async {
    final summary =
        await _repo.getMonthlyAttendanceSummary(worker.id!, year, month);
    final fullDays = summary['full'] ?? 0;
    final halfDays = summary['half'] ?? 0;
    final gross =
        (fullDays * worker.dailyRate) + (halfDays * worker.halfDayRate);
    final advances = await _repo.getApprovedAdvancesTotal(
      worker.id!,
      year: year,
      month: month,
    );
    return WorkerPaycheck(
      workerId: worker.id!,
      year: year,
      month: month,
      fullDays: fullDays,
      halfDays: halfDays,
      dailyRate: worker.dailyRate,
      grossEarnings: gross,
      totalAdvances: advances,
      netPayable: gross - advances,
    );
  }

  Future<List<SiteModel>> getWorkerSites(int workerId) =>
      _repo.getSitesByWorker(workerId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await loadWorkers();
  }

  void _syncCloud() {
    _cloud.uploadActiveUserInBackground(reason: 'worker-data-changed');
  }
}
