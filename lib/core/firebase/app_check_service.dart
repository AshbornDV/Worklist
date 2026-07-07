import 'dart:io';
import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_config.dart';

/// Supplies Firebase App Check tokens for REST calls and Firebase SDK services.
class AppCheckService {
  AppCheckService._();
  static final AppCheckService instance = AppCheckService._();

  static const _windowsDebugTokenKey = 'worklist_windows_app_check_debug_token';

  static const debugTokenFromEnvironment = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN',
    defaultValue: '',
  );

  String? _lastLoggedWindowsDebugToken;
  bool _activated = false;

  Future<void> activate() async {
    if (_activated) return;

    if (Platform.isAndroid) {
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode
            ? const AndroidDebugProvider()
            : const AndroidPlayIntegrityProvider(),
      );
      if (kDebugMode) {
        await _logAndroidSetupHint();
      }
    } else if (Platform.isWindows) {
      final debugToken = await _resolveWindowsDebugToken();
      await FirebaseAppCheck.instance.activate(
        providerWindows: WindowsDebugProvider(debugToken: debugToken),
      );
      _logWindowsDebugToken(debugToken);
    }

    _activated = true;
  }

  Future<void> setTokenAutoRefreshEnabled(bool enabled) async {
    if (!_activated) return;
    try {
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(enabled);
    } catch (error) {
      debugPrint('App Check auto-refresh setup failed: $error');
    }
  }

  Future<String?> getToken({bool forceRefresh = false}) async {
    if (!Platform.isAndroid && !Platform.isWindows) return null;

    try {
      return await FirebaseAppCheck.instance.getToken(forceRefresh);
    } catch (error) {
      debugPrint('App Check getToken failed: $error');
      return null;
    }
  }

  Future<String> _resolveWindowsDebugToken() async {
    if (debugTokenFromEnvironment.isNotEmpty) {
      return debugTokenFromEnvironment;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_windowsDebugTokenKey);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    final generated = _generateUuidV4();
    await prefs.setString(_windowsDebugTokenKey, generated);
    return generated;
  }

  Future<void> _logAndroidSetupHint() async {
    try {
      await FirebaseAppCheck.instance.getToken();
      debugPrint(
        'App Check is active on Android. If enforcement is enabled, register the '
        'debug token printed in logcat under "Firebase App Check" or '
        'Firebase Console → App Check → Manage debug tokens.',
      );
    } catch (error) {
      debugPrint('App Check Android setup: $error');
    }
  }

  void _logWindowsDebugToken(String debugToken) {
    if (_lastLoggedWindowsDebugToken == debugToken) return;
    _lastLoggedWindowsDebugToken = debugToken;
    debugPrint(
      'Register this Windows App Check debug token for app '
      '${FirebaseConfig.windowsAppId} in Firebase Console (App Check → Apps → '
      'worklist (windows) → Manage debug tokens): $debugToken',
    );
  }

  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    return '${bytes.sublist(0, 4).map(hex).join()}-'
        '${bytes.sublist(4, 6).map(hex).join()}-'
        '${bytes.sublist(6, 8).map(hex).join()}-'
        '${bytes.sublist(8, 10).map(hex).join()}-'
        '${bytes.sublist(10, 16).map(hex).join()}';
  }
}
