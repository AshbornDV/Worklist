import 'package:flutter_test/flutter_test.dart';
import 'package:worklist/core/providers/worker_provider.dart';
import 'harness.dart';

void main() {
  test('both payroll formulas match the frozen Flutter output', () async {
    final db = await openSeeded();
    final provider = WorkerProvider();
    final workers = await db.getAllWorkers();
    final summary = <String, Object?>{};

    for (final w in workers) {
      final paycheck = await provider.calculatePaycheck(w, 2026, 3);
      final generated = await provider.generatePayroll(w, 2026, 3);
      summary[w.name] = {
        'attendance': await db.getMonthlyAttendanceSummary(w.id!, 2026, 3),
        'advances': await db.getApprovedAdvancesTotal(w.id!, year: 2026, month: 3),
        'halfDayRate': w.halfDayRate,
        'calculatePaycheck': {
          'grossEarnings': paycheck.grossEarnings,
          'netPayable': paycheck.netPayable,
          'hasDebt': paycheck.hasDebt,
        },
        'generatePayroll': {
          'fullDays': generated.fullDays,
          'halfDays': generated.halfDays,
          'advanceAmount': generated.advanceAmount,
          'netSalary': generated.netSalary,
        },
      };
    }

    expectGolden('payroll.summary', summary);
    expectGolden('payroll.march-2026',
        (await db.getPayrollForMonth(DateTime(2026, 3))).map((p) => p.toMap()).toList());
  });
}
