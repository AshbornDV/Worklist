import '../../models/notification_model.dart';
import '../notification_rule.dart';

/// Shared base for Phase 3 inventory rules. Keeps the per-rule
/// [NotificationRule.evaluate] boilerplate minimal and guarantees every
/// inventory notification carries the consistent fields the engine and history
/// rely on (stable id, title, body, priority, entityId, entityType, deep link).
///
/// Rules stay read-only: they only query the repository and return candidates.
/// The [NotificationEngine] owns dedupe (by [NotificationModel.id]),
/// settings filtering (the `inventory` toggle), and delivery.
abstract class InventoryRuleBase extends NotificationRule {
  InventoryRuleBase({
    required super.id,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(type: NotificationType.inventory);

  final DateTime Function() _now;

  DateTime get now => _now();

  /// Builds a fully-populated inventory notification candidate.
  ///
  /// [subKey] makes the [NotificationModel.id] unique per product + condition
  /// (e.g. `low_stock`, `out_of_stock`) so the engine never delivers the same
  /// reminder twice for the same product/condition.
  NotificationModel build({
    required int productId,
    required String productName,
    required String subKey,
    required String title,
    required String body,
    required NotificationPriority priority,
    Map<String, dynamic>? extra,
  }) {
    final payload = <String, dynamic>{
      'rule': id,
      'condition': subKey,
      'productId': productId,
      'productName': productName,
      'deepLink': 'inventory_detail',
      'deepLinkArgs': {'productId': productId},
      if (extra != null) ...extra,
    };
    return NotificationModel(
      id: '$id:$productId:$subKey',
      title: title,
      body: body,
      type: NotificationType.inventory,
      priority: priority,
      status: NotificationStatus.pending,
      createdAt: now,
      entityId: productId.toString(),
      entityType: 'store_product',
      payload: payload,
    );
  }
}
