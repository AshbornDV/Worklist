import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/advance_payment_model.dart';
import '../models/attendance_model.dart';
import '../models/site_model.dart';
import '../models/worker_model.dart';

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
  final _db = DatabaseHelper();
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
      final result = await _db.getAllWorkers();
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

  Future<WorkerModel?> getWorker(int id) => _db.getWorkerById(id);

  Future<bool> addWorker(WorkerModel worker) async {
    try {
      final id = await _db.insertWorker(worker);
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
      await _db.updateWorker(worker);
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
      await _db.deleteWorker(id);
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

  // ─────────────── ATTENDANCE ───────────────

  Future<void> loadAttendance(int workerId, {int? year, int? month}) async {
    final gen = _generation;
    notifyListeners();
    try {
      final result = await _db.getAttendanceByWorker(
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
    return _db.getSiteAttendanceForDate(siteId, date);
  }

  Future<bool> recordAttendance(AttendanceModel attendance) async {
    try {
      await _db.upsertAttendance(attendance);
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
      final result = await _db.getAdvancesByWorker(workerId);
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
      final result = await _db.getAllPendingAdvances();
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
      final id = await _db.insertAdvance(advance);
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
      await _db.approveAdvance(advanceId);
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
      await _db.rejectAdvance(advanceId);
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
        await _db.getMonthlyAttendanceSummary(worker.id!, year, month);
    final fullDays = summary['full'] ?? 0;
    final halfDays = summary['half'] ?? 0;
    final gross =
        (fullDays * worker.dailyRate) + (halfDays * worker.halfDayRate);
    final advances = await _db.getApprovedAdvancesTotal(
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
      _db.getSitesByWorker(workerId);

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _syncCloud() {
    _cloud.uploadActiveUserInBackground();
  }
}
