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

  // ── Email-link (passwordless) sign-in ────────────────────────────────────
  // When we send a sign-in link we must remember WHICH email it was for, so
  // that when the app reopens via the link we can hand that email back to
  // Firebase. Without this the link alone is not enough to complete sign-in.
  static const _emailLinkKey = 'worklist_email_link_email';

  static Future<void> saveEmailLinkEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailLinkKey, email.trim().toLowerCase());
  }

  static Future<String?> loadEmailLinkEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailLinkKey);
    if (email == null || email.trim().isEmpty) return null;
    return email.trim();
  }

  static Future<void> clearEmailLinkEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailLinkKey);
  }
}
