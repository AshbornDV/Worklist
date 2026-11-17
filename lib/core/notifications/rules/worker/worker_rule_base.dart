import '../../models/notification_model.dart';
import '../notification_rule.dart';

/// Shared base for Phase 5 worker rules. Guarantees every worker notification
/// carries consistent fields (stable id, title, body, priority, entityId,
/// entityType, deep link) that the engine and history rely on.
///
/// Rules stay read-only: they only query repositories and return candidates.
/// The [NotificationEngine] owns dedupe (by [NotificationModel.id]),
/// settings filtering, and delivery.
abstract class WorkerRuleBase extends NotificationRule {
  WorkerRuleBase({
    required super.id,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(type: NotificationType.worker);

  final DateTime Function() _now;

  DateTime get now => _now();

  /// Builds a fully-populated worker notification candidate.
  ///
  /// [subKey] makes the [NotificationModel.id] unique per worker + condition so
  /// the engine never delivers the same reminder twice for the same worker/
  /// condition.
  NotificationModel build({
    required int workerId,
    required String workerName,
    required String subKey,
    required String title,
    required String body,
    required NotificationPriority priority,
    Map<String, dynamic>? extra,
  }) {
    final payload = <String, dynamic>{
      'rule': id,
      'condition': subKey,
      'workerId': workerId,
      'workerName': workerName,
      'deepLink': 'worker_detail',
      'deepLinkArgs': {'workerId': workerId},
      if (extra != null) ...extra,
    };
    return NotificationModel(
      id: '$id:$workerId:$subKey',
      title: title,
      body: body,
      type: NotificationType.worker,
      priority: priority,
      status: NotificationStatus.pending,
      createdAt: now,
      entityId: workerId.toString(),
      entityType: 'worker',
      payload: payload,
    );
  }
}
