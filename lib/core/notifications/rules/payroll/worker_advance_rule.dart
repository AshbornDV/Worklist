import '../../models/notification_model.dart';
import '../../../models/advance_payment_model.dart';
import '../../../repositories/worker_repository.dart';
import '../notification_rule.dart';

/// Reminds the user about pending worker advance requests that still need a
/// decision (approve/reject). Each pending [AdvancePaymentModel] produces one
/// stable, deduped reminder (keyed by advance id) so it is never repeated until
/// the request's status changes.
///
/// Read-only rule; engine handles dedupe/settings/delivery.
class WorkerAdvanceRule extends NotificationRule {
  WorkerAdvanceRule({
    required WorkerRepository workerRepository,
    DateTime Function()? now,
  })  : _workerRepository = workerRepository,
        _now = now ?? DateTime.now,
        super(id: 'worker_advance', type: NotificationType.payroll);

  final WorkerRepository _workerRepository;
  final DateTime Function() _now;

  @override
  Future<List<AppNotification>> evaluate() async {
    final now = _now();
    final pending = await _workerRepository.getAllPendingAdvances();
    final out = <AppNotification>[];

    for (final a in pending) {
      if (a.id == null) continue;
      final name = a.workerName ?? 'Worker #${a.workerId}';
      out.add(
        NotificationModel(
          id: 'worker_advance:${a.id}',
          title: 'Advance request pending · $name',
          body:
              'Rs. ${a.amount.toStringAsFixed(0)} advance requested on ${_fmt(a.requestDate)} needs approval.',
          type: NotificationType.payroll,
          priority: NotificationPriority.normal,
          status: NotificationStatus.pending,
          createdAt: now,
          scheduledFor: a.requestDate,
          entityId: a.id.toString(),
          entityType: 'advance_payment',
          payload: {
            'rule': id,
            'advanceId': a.id,
            'workerId': a.workerId,
            'amount': a.amount,
            'deepLink': 'worker_detail',
            'deepLinkArgs': {'workerId': a.workerId},
          },
        ),
      );
    }
    return out;
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
