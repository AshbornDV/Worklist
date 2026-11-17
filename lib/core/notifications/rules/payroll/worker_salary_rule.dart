import '../../models/notification_model.dart';
import '../../../models/payroll_model.dart';
import '../../../repositories/payroll_repository.dart';
import '../notification_rule.dart';

/// Reminds about a worker's unpaid salary. A worker's salary for a month is
/// represented by a [PayrollModel] with status `draft` and a positive net
/// salary. This rule surfaces those per-worker so each worker gets a distinct,
/// deduped reminder. (Complements [PayrollReminderRule], which frames the same
/// data around payroll-month timing.)
///
/// Read-only rule; engine handles dedupe/settings/delivery.
class WorkerSalaryRule extends NotificationRule {
  WorkerSalaryRule({
    required PayrollRepository payrollRepository,
    DateTime Function()? now,
  })  : _payrollRepository = payrollRepository,
        _now = now ?? DateTime.now,
        super(id: 'worker_salary', type: NotificationType.payroll);

  final PayrollRepository _payrollRepository;
  final DateTime Function() _now;

  @override
  Future<List<AppNotification>> evaluate() async {
    final now = _now();
    final month = DateTime(now.year, now.month, 1);
    // Payroll is generated monthly; scan the current and previous month.
    final records = await _payrollRepository.getPayrollForMonth(month);
    records.addAll(await _payrollRepository.getPayrollForMonth(
      DateTime(month.year, month.month - 1, 1),
    ));

    final out = <AppNotification>[];
    for (final p in records) {
      if (p.id == null) continue;
      if (p.isPaid || p.netSalary <= 0) continue;

      out.add(
        NotificationModel(
          id: 'worker_salary:${p.workerId}:${p.monthLabel}',
          title: 'Salary due · ${p.workerName ?? 'Worker #${p.workerId}'}',
          body:
              'Rs. ${p.netSalary.toStringAsFixed(0)} salary for ${p.monthLabel} is pending payment.',
          type: NotificationType.payroll,
          priority: NotificationPriority.high,
          status: NotificationStatus.pending,
          createdAt: now,
          scheduledFor: month,
          entityId: p.workerId.toString(),
          entityType: 'worker',
          payload: {
            'rule': id,
            'payrollId': p.id,
            'workerId': p.workerId,
            'month': p.monthLabel,
            'amount': p.netSalary,
            'deepLink': 'worker_detail',
            'deepLinkArgs': {'workerId': p.workerId},
          },
        ),
      );
    }
    return out;
  }
}
