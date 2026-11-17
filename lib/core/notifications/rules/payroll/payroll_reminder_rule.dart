import '../../models/notification_model.dart';
import '../../../models/payroll_model.dart';
import '../../../repositories/payroll_repository.dart';
import '../notification_rule.dart';
import '../payment/reminder_window.dart';

/// Payroll reminder windows:
///  • Upcoming payroll     → scheduled date (last day of payroll month) is in a
///    future window (7/3/1 day before).
///  • Payroll due today    → scheduled date is today.
///  • Payroll overdue      → scheduled date is past and the record is still a
///    draft (not paid).
///  • Salary unpaid        → any draft payroll (status != 'paid') for the
///    current/previous month that has a positive net salary.
///
/// The scheduled date is derived as the last calendar day of the payroll's
/// `month` — no schema change. Read-only rule; engine handles the rest.
class PayrollReminderRule extends NotificationRule {
  PayrollReminderRule({
    required PayrollRepository payrollRepository,
    DateTime Function()? now,
  })  : _payrollRepository = payrollRepository,
        _now = now ?? DateTime.now,
        super(id: 'payroll', type: NotificationType.payroll);

  final PayrollRepository _payrollRepository;
  final DateTime Function() _now;

  /// Last day of the month containing [month].
  static DateTime monthEnd(DateTime month) {
    final firstNext = month.month == 12
        ? DateTime(month.year + 1, 1, 1)
        : DateTime(month.year, month.month + 1, 1);
    return firstNext.subtract(const Duration(days: 1));
  }

  @override
  Future<List<AppNotification>> evaluate() async {
    final now = _now();
    final month = DateTime(now.year, now.month, 1);
    final records = await _payrollRepository.getPayrollForMonth(Optimistic.month(month));
    final out = <AppNotification>[];

    for (final p in records) {
      if (p.id == null) continue;

      // Salary unpaid: draft with a positive net salary → always flagged
      // (deduped per record by the engine's history; window key below).
      if (!p.isPaid && p.netSalary > 0) {
        out.add(_build(
          idSuffix: 'salary_unpaid',
          p: p,
          title: 'Salary unpaid · ${p.workerName ?? 'Worker #${p.workerId}'}',
          body:
              'Rs. ${p.netSalary.toStringAsFixed(0)} salary for ${p.monthLabel} is still unpaid.',
          priority: NotificationPriority.high,
          due: monthEnd(p.month),
          now: now,
          deepLinkArgs: {'workerId': p.workerId},
        ));
        continue;
      }

      // Upcoming / due / overdue payroll based on the month-end due date.
      final due = monthEnd(p.month);
      final window = windowForDueDate(due, now);
      if (window == null) continue;

      final overdue = isOverdueWindow(window);
      final stillOpen = !p.isPaid;
      if (overdue && !stillOpen) continue; // paid → no overdue reminder

      out.add(_build(
        idSuffix: window.name,
        p: p,
        title: 'Payroll ${overdue ? 'overdue' : window.name} · ${p.workerName ?? 'Worker #${p.workerId}'}',
        body:
            'Rs. ${p.netSalary.toStringAsFixed(0)} payroll for ${p.monthLabel} ${overdue ? 'is overdue' : 'is ${windowLabel(window)}'}.',
        priority: priorityForWindow(window),
        due: due,
        now: now,
        deepLinkArgs: {'workerId': p.workerId},
      ));
    }
    return out;
  }

  AppNotification _build({
    required String idSuffix,
    required PayrollModel p,
    required String title,
    required String body,
    required NotificationPriority priority,
    required DateTime due,
    required DateTime now,
    required Map<String, dynamic> deepLinkArgs,
  }) =>
      NotificationModel(
        id: 'payroll:${p.id}:$idSuffix',
        title: title,
        body: body,
        type: NotificationType.payroll,
        priority: priority,
        status: NotificationStatus.pending,
        createdAt: now,
        scheduledFor: due,
        entityId: p.id.toString(),
        entityType: 'payroll',
        payload: {
          'rule': id,
          'payrollId': p.id,
          'workerId': p.workerId,
          'month': p.monthLabel,
          'deepLink': 'worker_detail',
          'deepLinkArgs': deepLinkArgs,
        },
      );
}

/// Helper to obtain the first-of-month [DateTime] without importing intl here.
class Optimistic {
  const Optimistic._();
  static DateTime month(DateTime m) => DateTime(m.year, m.month, 1);
}
