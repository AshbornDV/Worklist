import '../core/notification_logger.dart';
import '../analytics/notification_metrics.dart';
import '../models/notification_model.dart';
import '../models/notification_settings.dart';
import '../platform/platform_notification_service_factory.dart';
import '../repositories/notification_history_repository.dart';
import '../repositories/notification_settings_repository.dart';
import '../rules/notification_rule.dart';
import '../scheduler/notification_scheduler.dart';
import 'notification_rule_evaluator.dart';

/// The single orchestrator of the notification framework. Future feature
/// modules (payments, inventory, payroll, …) register their [NotificationRule]s
/// here and never schedule or display notifications themselves.
///
/// A `refresh()` cycle runs the pipeline:
///   1. [NotificationRuleEvaluator] evaluates enabled rules → candidates.
///   2. Each candidate is checked against [NotificationHistoryRepository] for
///      duplicates (`wasAlreadyDelivered`) and skipped if already delivered.
///   3. Survivors are delivered via [NotificationScheduler] (immediate in P1).
///   4. Deliveries are recorded in history so they are not repeated.
///
/// The engine is platform-independent and depends only on injected
/// collaborators, all of which default to the framework's own implementations.
/// It is created lazily and never touches Firebase, SQLite business tables,
/// auth, or the UI.
class NotificationEngine {
  NotificationEngine({
    required NotificationSettingsRepository settingsRepository,
    required NotificationHistoryRepository historyRepository,
    required NotificationRuleEvaluator Function(NotificationSettings) evaluatorFactory,
    NotificationScheduler? scheduler,
    NotificationSettings? initialSettings,
  })  : _settingsRepository = settingsRepository,
        _history = historyRepository,
        _evaluatorFactory = evaluatorFactory,
        _scheduler = scheduler ?? PlatformNotificationServiceFactory.scheduler,
        _settings = initialSettings;

  final NotificationSettingsRepository _settingsRepository;
  final NotificationHistoryRepository _history;
  final NotificationRuleEvaluator Function(NotificationSettings) _evaluatorFactory;
  final NotificationScheduler _scheduler;

  NotificationSettings? _settings;
  final List<NotificationRule> _rules = [];

  /// Lazy singleton accessor. Wires the engine with the framework-default
  /// repositories and evaluator. Safe to call from anywhere; creates the
  /// SharedPreferences-backed repositories on first access.
  static Future<NotificationEngine> create() async {
    final settingsRepo = await NotificationSettingsRepository.create();
    final history = await NotificationHistoryRepository.create();
    return NotificationEngine(
      settingsRepository: settingsRepo,
      historyRepository: history,
      evaluatorFactory: (s) => NotificationRuleEvaluator(settings: s),
      initialSettings: settingsRepo.load(),
    );
  }

  /// Registers a rule. Duplicate ids are replaced so re-registering is safe.
  void registerRule(NotificationRule rule) {
    _rules.removeWhere((r) => r.id == rule.id);
    _rules.add(rule);
    NotificationLogger.instance.info('Registered rule: ${rule.id}');
  }

  /// Registers multiple rules at once (idempotent — duplicate ids replaced).
  void registerRules(List<NotificationRule> rules) {
    for (final r in rules) {
      registerRule(r);
    }
  }

  /// Removes a previously registered rule (e.g. when a feature is disabled).
  void unregisterRule(String id) {
    _rules.removeWhere((r) => r.id == id);
  }

  /// Current settings, loaded from the repository if not yet cached.
  NotificationSettings get settings =>
      _settings ??= _settingsRepository.load();

  /// Updates settings and persists them. Affects subsequent refresh cycles.
  Future<void> updateSettings(NotificationSettings next) async {
    _settings = next;
    await _settingsRepository.save(next);
    NotificationLogger.instance.info('Notification settings updated');
  }

  /// Runs the full evaluation → dedupe → deliver → record pipeline.
  ///
  /// Returns the list of notifications that were actually delivered this cycle.
  /// Future phases can call this on a timer, on app resume, or from a
  /// background task — the engine is platform-agnostic.
  Future<List<NotificationModel>> refresh() async {
    if (_rules.isEmpty) {
      NotificationLogger.instance.verbose('refresh() with no rules registered');
      return const [];
    }

    final stopwatch = Stopwatch()..start();
    final evaluator = _evaluatorFactory(settings);
    final candidates = await evaluator.evaluateRules(_rules);

    // Batch dedupe: load history once instead of one SharedPreferences read per
    // candidate (which was N round-trips every 15-min tick). A single Set
    // membership check per candidate is O(1) and prevents duplicate delivery.
    final deliveredIds =
        _history.readAllPublic().keys.toSet();

    NotificationMetrics.instance.recordCreated(candidates.length);
    NotificationMetrics.instance.ensureLoaded();

    final delivered = <NotificationModel>[];
    for (final candidate in candidates) {
      if (deliveredIds.contains(candidate.id)) {
        NotificationLogger.instance.verbose(
          'Skipping duplicate: ${candidate.id}',
        );
        NotificationMetrics.instance
            .record(NotificationEventType.duplicatePrevented);
        continue;
      }

      final ok = await _scheduler.showNow(candidate);
      if (ok) {
        await _history.record(notification: candidate, deliveredAt: DateTime.now());
        delivered.add(candidate.copyWith(
          status: NotificationStatus.delivered,
          deliveredAt: DateTime.now(),
        ));
        NotificationMetrics.instance.record(NotificationEventType.delivered);
      } else {
        NotificationLogger.instance.warning(
          'Delivery failed for ${candidate.id}',
        );
        NotificationMetrics.instance.record(NotificationEventType.failed);
      }
    }

    stopwatch.stop();
    NotificationMetrics.instance.recordTiming(stopwatch.elapsed);
    NotificationMetrics.instance.recordForegroundExecution(DateTime.now());

    await _history.prune();
    NotificationLogger.instance.info(
      'refresh() delivered ${delivered.length} notification(s)',
    );
    return delivered;
  }
}
