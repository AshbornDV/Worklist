import '../models/notification_model.dart';
import '../models/notification_settings.dart';

/// Abstract base for every notification rule (future reminder types: payments,
/// inventory, payroll, workers, …). A rule is a pure source of candidate
/// notifications — it queries only the data it needs and returns candidates.
/// It must NOT schedule, display, or persist anything itself; the
/// [NotificationEngine] owns those responsibilities.
///
/// Phase 1 defines this contract only. No concrete rules are implemented yet.
abstract class NotificationRule {
  NotificationRule({required this.id, required this.type});

  /// Stable identifier for this rule (e.g. `payments_due`). Used by the engine
  /// for logging and by [NotificationRuleEvaluator] to avoid duplicate runs.
  final String id;

  /// The notification category this rule produces (drives user settings + channel).
  final NotificationType type;

  /// Whether this rule is enabled by the user's settings for its [type].
  /// The engine checks this before evaluating, so rules stay declarative.
  bool isEnabled(NotificationSettings settings) =>
      settings.isTypeEnabled(type);

  /// Produce candidate notifications. Implementations should query the
  /// narrowest slice of data required (never the whole database) and return
  /// plain [NotificationModel] candidates — the engine decides what to show,
  /// dedupe, persist, and schedule.
  ///
  /// Called by [NotificationRuleEvaluator] (which is permitted to invoke it);
  /// implementations must be side-effect free with respect to scheduling and
  /// persistence.
  Future<List<AppNotification>> evaluate();
}
