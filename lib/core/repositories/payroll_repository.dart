import '../database/database_helper.dart';
import '../models/payroll_model.dart';

/// Repository layer for payroll records (one per worker × month).
///
/// Used by the worker provider for monthly salary generation and management.
class PayrollRepository {
  final _db = DatabaseHelper();

  Future<List<PayrollModel>> getPayrollForMonth(DateTime month) =>
      _db.getPayrollForMonth(month);

  Future<PayrollModel?> getPayroll(int workerId, DateTime month) =>
      _db.getPayroll(workerId, month);

  Future<int> insertPayroll(PayrollModel payroll) => _db.insertPayroll(payroll);

  Future<int> updatePayroll(PayrollModel payroll) => _db.updatePayroll(payroll);

  Future<int> deletePayroll(int id) => _db.deletePayroll(id);

  Future<int> setPayrollStatus(int id, String status) =>
      _db.setPayrollStatus(id, status);
}
