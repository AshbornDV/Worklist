import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last signed-in local Worklist username across app restarts.
class SessionStorage {
  SessionStorage._();

  static const _usernameKey = 'worklist_active_username';

  static Future<void> saveActiveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username.trim());
  }

  static Future<String?> loadActiveUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_usernameKey);
    if (username == null || username.trim().isEmpty) return null;
    return username.trim();
  }

  static Future<void> clearActiveUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usernameKey);
  }
}
