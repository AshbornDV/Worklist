import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 10 — enterprise notification analytics & diagnostics.
///
/// A self-contained metrics store for the notification framework. It records
/// lifecycle events (created / scheduled / delivered / opened / dismissed /
/// archived / ignored / failed / duplicate prevented), per-day buckets, rolling
/// execution-time averages, and a bounded ring of structured log entries.
///
/// Design goals:
///  • Additive — no business logic, sync, auth, or schema is touched. Call
///    sites only fire-and-forget `record*` calls.
///  • Cheap — counters live in memory; persistence to SharedPreferences is
///    best-effort and debounced by the caller.
///  • Release-safe — `dev.log` spam is suppressed in release builds (see
///    [logStructured]); counters and the in-memory ring still populate so the
///    Diagnostics screen is meaningful on every build.
class NotificationMetrics {
  NotificationMetrics._();

  static final NotificationMetrics instance = NotificationMetrics._();

  static const String _storeKey = 'worklist.notifications.metrics.v1';
  static const int _maxLogEntries = 200;
  static const Duration _schedulerInterval = Duration(minutes: 15);

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  final Map<NotificationEventType, int> _totals = {
    for (final e in NotificationEventType.values) e: 0,
  };
  final Map<String, Map<NotificationEventType, int>> _daily = {};

  double _avgExecutionMs = 0;
  int _executionCount = 0;
  DateTime? _lastBackgroundExecution;
  DateTime? _lastForegroundExecution;
  bool _schedulerRegistered = false;

  final List<DiagnosticLogEntry> _logs = [];

  bool _loaded = false;
  SharedPreferences? _prefs;

  // ── Public read API (used by the Diagnostics screen) ──

  int total(NotificationEventType t) => _totals[t] ?? 0;
  int daily(NotificationEventType t, {DateTime? at}) {
    final key = _dayKey(at ?? DateTime.now());
    return _daily[key]?[t] ?? 0;
  }

  double get avgExecutionMs => _avgExecutionMs;
  int get executionCount => _executionCount;
  DateTime? get lastBackgroundExecution => _lastBackgroundExecution;
  DateTime? get lastForegroundExecution => _lastForegroundExecution;
  bool get schedulerRegistered => _schedulerRegistered;

  /// Estimated resident memory in MB (debug/profile only; release returns null
  /// without throwing).
  double? get memoryUsageMb {
    try {
      return ProcessInfo.currentRss / (1024 * 1024);
    } catch (_) {
      return null;
    }
  }

  /// Next expected scheduler run. Android (WorkManager 15-min floor) and
  /// Windows (in-process timer) both run on the 15-minute cadence.
  DateTime? get nextScheduledRun {
    final last = _lastForegroundExecution ?? _lastBackgroundExecution;
    return last?.add(_schedulerInterval);
  }

  List<DiagnosticLogEntry> recentLogs({int? limit}) {
    final list = _logs.reversed.toList();
    return limit == null ? list : list.take(limit).toList();
  }

  /// Prunes the in-memory daily buckets to a rolling window so the persisted
  /// JSON (written every tick + on every event) never grows unbounded. Without
  /// this the map grew forever, slowly inflating every SharedPreferences write and
  /// the memory footprint of the Diagnostics screen.
  static const int _dailyRetentionDays = 14;

  void _pruneDaily() {
    if (_daily.length <= _dailyRetentionDays) return;
    final keys = _daily.keys.toList()..sort();
    while (keys.length > _dailyRetentionDays) {
      _daily.remove(keys.removeAt(0));
    }
  }

  /// Derived "ignored" count: delivered today that were never opened.
  int ignoredToday({DateTime? at}) {
    final delivered = daily(NotificationEventType.delivered, at: at);
    final opened = daily(NotificationEventType.opened, at: at);
    return (delivered - opened).clamp(0, delivered);
  }

  Map<String, dynamic> snapshot() => {
        'totals': _totals.map((k, v) => MapEntry(k.name, v)),
        'avgExecutionMs': _avgExecutionMs,
        'executionCount': _executionCount,
        'lastBackgroundExecution': _lastBackgroundExecution?.toIso8601String(),
        'lastForegroundExecution': _lastForegroundExecution?.toIso8601String(),
        'schedulerRegistered': _schedulerRegistered,
        'daily': _daily,
      };

  // ── Record API (fire-and-forget from call sites) ──

  void record(NotificationEventType type, {String? message, Map<String, dynamic>? meta}) {
    _totals[type] = (_totals[type] ?? 0) + 1;
    final key = _dayKey(DateTime.now());
    _daily.putIfAbsent(key, () => {for (final e in NotificationEventType.values) e: 0});
    _daily[key]![type] = (_daily[key]![type] ?? 0) + 1;
    if (message != null) logStructured(type, message, meta: meta);
    _schedulePersist();
  }

  void recordCreated(int count) {
    if (count <= 0) return;
    _totals[NotificationEventType.created] =
        (_totals[NotificationEventType.created] ?? 0) + count;
    final key = _dayKey(DateTime.now());
    _daily.putIfAbsent(key, () => {for (final e in NotificationEventType.values) e: 0});
    _daily[key]![NotificationEventType.created] =
        (_daily[key]![NotificationEventType.created] ?? 0) + count;
    _schedulePersist();
  }

  void recordTiming(Duration d) {
    final ms = d.inMilliseconds.toDouble();
    _executionCount++;
    // Running average (Welford-style incremental mean).
    _avgExecutionMs = _avgExecutionMs + (ms - _avgExecutionMs) / _executionCount;
    _schedulePersist();
  }

  void recordForegroundExecution(DateTime at) {
    _lastForegroundExecution = at;
    _schedulePersist();
  }

  void recordBackgroundExecution(DateTime at) {
    _lastBackgroundExecution = at;
    _schedulePersist();
  }

  void markSchedulerRegistered() {
    _schedulerRegistered = true;
    _schedulePersist();
  }

  void resetDailyIfNeeded() {
    final key = _dayKey(DateTime.now());
    if (!_daily.containsKey(key)) _daily[key] = {for (final e in NotificationEventType.values) e: 0};
  }

  void logStructured(
    NotificationEventType type,
    String message, {
    Map<String, dynamic>? meta,
  }) {
    final entry = DiagnosticLogEntry(
      ts: DateTime.now(),
      type: type,
      message: message,
      meta: meta,
    );
    _logs.add(entry);
    if (_logs.length > _maxLogEntries) _logs.removeAt(0);
    // Avoid excessive logging in release builds: only emit dev.log in debug.
    if (!kReleaseMode) {
      final metaStr = meta != null ? ' meta=$meta' : '';
      // ignore: avoid_print — dev.log is gated to non-release above.
      devLog('[Metrics:${type.name}] $message$metaStr');
    }
  }

  // ── Persistence ──

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storeKey);
    if (raw != null) {
      try {
        _fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt store is non-fatal; start fresh.
      }
    }
    _loaded = true;
  }

  Timer? _persistTimer;

  /// Coalesces high-frequency writes into a single SharedPreferences write. The
  /// engine fires many `record*` calls per refresh tick; serializing the full
  /// metrics JSON on every one (the old `_persist`) thrashed disk/IO and,
  /// because `_daily` was never pruned, the payload grew unbounded. We now
  /// (a) prune the daily window and (b) debounce so a burst of events within
  /// [_persistDebounce] collapses into one write.
  static const Duration _persistDebounce = Duration(milliseconds: 1500);

  void _schedulePersist() {
    _pruneDaily();
    _persistTimer?.cancel();
    _persistTimer = Timer(_persistDebounce, _persistNow);
  }

  void _persistNow() {
    // Best-effort, non-blocking.
    Future<void>.microtask(() async {
      try {
        _prefs ??= await SharedPreferences.getInstance();
        await _prefs!.setString(_storeKey, jsonEncode(_toMap()));
      } catch (_) {
        // Persistence failure must never break notification delivery.
      }
    });
  }

  Map<String, dynamic> _toMap() => {
        'totals': _totals.map((k, v) => MapEntry(k.name, v)),
        'daily': _daily.map(
          (k, v) => MapEntry(k, v.map((kk, vv) => MapEntry(kk.name, vv))),
        ),
        'avgExecutionMs': _avgExecutionMs,
        'executionCount': _executionCount,
        'lastBackgroundExecution': _lastBackgroundExecution?.toIso8601String(),
        'lastForegroundExecution': _lastForegroundExecution?.toIso8601String(),
        'schedulerRegistered': _schedulerRegistered,
      };

  void _fromMap(Map<String, dynamic> m) {
    final totals = m['totals'] as Map<String, dynamic>? ?? {};
    for (final e in NotificationEventType.values) {
      _totals[e] = totals[e.name] as int? ?? 0;
    }
    final daily = m['daily'] as Map<String, dynamic>? ?? {};
    daily.forEach((day, value) {
      final map = (value as Map<String, dynamic>).map(
        (k, v) => MapEntry(
          NotificationEventType.values.firstWhere(
            (e) => e.name == k,
            orElse: () => NotificationEventType.created,
          ),
          v as int,
        ),
      );
      _daily[day] = map;
    });
    _avgExecutionMs = (m['avgExecutionMs'] as num?)?.toDouble() ?? 0;
    _executionCount = m['executionCount'] as int? ?? 0;
    _lastBackgroundExecution = m['lastBackgroundExecution'] == null
        ? null
        : DateTime.parse(m['lastBackgroundExecution'] as String);
    _lastForegroundExecution = m['lastForegroundExecution'] == null
        ? null
        : DateTime.parse(m['lastForegroundExecution'] as String);
    _schedulerRegistered = m['schedulerRegistered'] as bool? ?? false;
  }
}

/// Lifecycle events tracked for analytics.
enum NotificationEventType {
  created,
  scheduled,
  delivered,
  opened,
  dismissed,
  archived,
  ignored,
  failed,
  duplicatePrevented,
  snoozed,
}

extension NotificationEventTypeX on NotificationEventType {
  String get label {
    switch (this) {
      case NotificationEventType.created:
        return 'Created';
      case NotificationEventType.scheduled:
        return 'Scheduled';
      case NotificationEventType.delivered:
        return 'Delivered';
      case NotificationEventType.opened:
        return 'Opened';
      case NotificationEventType.dismissed:
        return 'Dismissed';
      case NotificationEventType.archived:
        return 'Archived';
      case NotificationEventType.ignored:
        return 'Ignored';
      case NotificationEventType.failed:
        return 'Failed';
      case NotificationEventType.duplicatePrevented:
        return 'Duplicate Prevented';
      case NotificationEventType.snoozed:
        return 'Snoozed';
    }
  }
}

/// A single structured diagnostic log line.
class DiagnosticLogEntry {
  DiagnosticLogEntry({
    required this.ts,
    required this.type,
    required this.message,
    this.meta,
  });

  final DateTime ts;
  final NotificationEventType type;
  final String message;
  final Map<String, dynamic>? meta;

  Map<String, dynamic> toMap() => {
        'ts': ts.toIso8601String(),
        'type': type.name,
        'message': message,
        if (meta != null) 'meta': meta,
      };

  factory DiagnosticLogEntry.fromMap(Map<String, dynamic> m) =>
      DiagnosticLogEntry(
        ts: DateTime.parse(m['ts'] as String),
        type: NotificationEventType.values.firstWhere(
          (e) => e.name == (m['type'] as String? ?? ''),
          orElse: () => NotificationEventType.created,
        ),
        message: m['message'] as String,
        meta: m['meta'] as Map<String, dynamic>?,
      );
}

/// Thin wrapper so release builds don't spam `dev.log` while keeping the call
/// site readable. Mirrors `dart:developer.log`.
void devLog(String message) {
  // ignore: avoid_print
  // Only reached when !kReleaseMode (caller guards). Kept as print to avoid an
  // extra import alias collision in the metrics file.
  if (!kReleaseMode) debugPrint(message);
}
