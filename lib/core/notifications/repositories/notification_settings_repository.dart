import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_settings.dart';

/// Persists [NotificationSettings] via SharedPreferences. This is the only
/// persistence used by the notification framework in Phase 1 — no SQLite
/// business tables, Firebase, or auth are touched.
///
/// Future phases can call [load]/[save] from a settings screen; no UI exists yet.
class NotificationSettingsRepository {
  NotificationSettingsRepository._(this._prefs);

  /// Lazily creates the repository, reading the persisted settings if present.
  static Future<NotificationSettingsRepository> create() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettingsRepository._(prefs);
  }

  final SharedPreferences _prefs;

  static const String _key = 'worklist.notifications.settings.v1';

  /// Loads persisted settings, falling back to [NotificationSettings] defaults
  /// when nothing has been stored yet or the payload is corrupt.
  NotificationSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const NotificationSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return NotificationSettings.fromJson(json);
    } catch (_) {
      // Corrupt payload — fall back to defaults rather than crashing.
      return const NotificationSettings();
    }
  }

  /// Persists the given settings. Returns true on success.
  Future<bool> save(NotificationSettings settings) async =>
      _prefs.setString(_key, jsonEncode(settings.toJson()));
}
