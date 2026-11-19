import '../../models/notification_model.dart';
import '../notification_rule.dart';

/// Shared base for Phase 4 site rules. Guarantees every site notification
/// carries consistent fields (stable id, title, body, priority, entityId,
/// entityType, deep link) that the engine and history rely on.
///
/// Rules stay read-only: they only query repositories and return candidates.
/// The [NotificationEngine] owns dedupe (by [NotificationModel.id]),
/// settings filtering, and delivery.
abstract class SiteRuleBase extends NotificationRule {
  SiteRuleBase({
    required super.id,
    DateTime Function()? now,
  })  : _now = now ?? DateTime.now,
        super(type: NotificationType.site);

  final DateTime Function() _now;

  DateTime get now => _now();

  /// Builds a fully-populated site notification candidate.
  ///
  /// [subKey] makes the [NotificationModel.id] unique per site + condition so
  /// the engine never delivers the same reminder twice for the same site/
  /// condition.
  NotificationModel build({
    required int siteId,
    required String siteName,
    required String subKey,
    required String title,
    required String body,
    required NotificationPriority priority,
    DateTime? scheduledFor,
    Map<String, dynamic>? extra,
  }) {
    final payload = <String, dynamic>{
      'rule': id,
      'condition': subKey,
      'siteId': siteId,
      'siteName': siteName,
      'deepLink': 'site_detail',
      'deepLinkArgs': {'siteId': siteId},
      if (extra != null) ...extra,
    };
    return NotificationModel(
      id: '$id:$siteId:$subKey',
      title: title,
      body: body,
      type: NotificationType.site,
      priority: priority,
      status: NotificationStatus.pending,
      createdAt: now,
      scheduledFor: scheduledFor,
      entityId: siteId.toString(),
      entityType: 'site',
      payload: payload,
    );
  }
}
