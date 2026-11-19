import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted light/dark theme preference. Defaults to following the OS
/// (ThemeMode.system); the UI exposes a toggle that switches explicitly
/// between light and dark.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _load();
  }

  ThemeMode _mode = ThemeMode.system;
  static const _key = 'theme_mode';

  ThemeMode get mode => _mode;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_key);
      if (v != null) {
        _mode = ThemeMode.values.firstWhere(
          (m) => m.name == v,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (_) {
      // Persistence unavailable — keep system default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // Ignore persistence failure; in-memory value still applies.
    }
  }

  /// Toggle between light and dark. Any state (including system) flips to its
  /// opposite explicit mode.
  Future<void> toggle() async =>
      setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}
