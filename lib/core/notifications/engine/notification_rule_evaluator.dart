import '../models/notification_model.dart';
import '../models/notification_settings.dart';
import '../rules/notification_rule.dart';
import '../core/notification_logger.dart';

/// Runs a set of [NotificationRule]s and applies user-policy filtering
/// (per-type enable, quiet hours) to their candidates. It does NOT schedule,
/// display, persist, or dedupe — those are the engine's and history's jobs.
///
/// Rules are evaluated concurrently (each rule queries only its own slice of
/// data) and the results are merged. A failing rule is logged and skipped so
/// one bad rule can never block the others.
class NotificationRuleEvaluator {
  NotificationRuleEvaluator({
    required this.settings,
    this.now = _systemNow,
  });

  final NotificationSettings settings;
  final DateTime Function() now;

  static DateTime _systemNow() => DateTime.now();

  /// Evaluates [rules] and returns the candidates that survive policy
  /// filtering. Rules whose type is disabled by [settings] are skipped
  /// entirely (so they don't even query data). Quiet hours silence non-critical
  /// candidates unless the rule explicitly forces delivery (rare).
  Future<List<AppNotification>> evaluateRules(
    List<NotificationRule> rules,
  ) async {
    final enabled = rules.where((r) => r.isEnabled(settings)).toList();
    NotificationLogger.instance.info(
      'Evaluating ${enabled.length}/${rules.length} enabled rules',
    );

    final results = await Future.wait(
      enabled.map(
        (r) async {
          try {
            return await r.evaluate();
          } catch (e, s) {
            NotificationLogger.instance
                .error('Rule ${r.id} evaluation failed', e, s);
            return <AppNotification>[];
          }
        },
      ),
    );

    final candidates = results.expand((e) => e).where((n) {
      if (settings.isSilencedByQuietHours(n.priority, now())) {
        NotificationLogger.instance.verbose(
          'Quiet hours silenced ${n.id} (${n.type.name})',
        );
        return false;
      }
      return true;
    }).toList();

    NotificationLogger.instance.info(
      '${candidates.length} candidate(s) after policy filtering',
    );
    return candidates;
  }
}
