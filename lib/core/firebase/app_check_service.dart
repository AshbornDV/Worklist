import 'dart:io';
import 'dart:math';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_config.dart';

/// Manages Firebase App Check activation per platform.
///
/// Platform strategy:
///   Android (debug)    → [AndroidDebugProvider] with persistent UUIDv4 token
///   Android (release)  → [AndroidPlayIntegrityProvider] (requires Play Integrity API)
///   Windows / Linux    → [WindowsDebugProvider] with persistent UUIDv4 token
///   Web                → [ReCaptchaV3Provider] (requires --dart-define=RECAPTCHA_SITE_KEY=)
///
/// Activation never throws. All errors are caught and logged; the app continues
/// without App Check. This keeps Firebase Auth + RTDB usable during development.
///
/// IMPORTANT: On Windows, a [WindowsDebugProvider] must be registered even in
/// debug mode. The Firebase C++ SDK's RTDB WebSocket layer requires an App
/// Check provider to be present — without one, the SDK crashes (null pointer
/// dereference) when any database write operation triggers the WebSocket to
/// open. This is not a Dart exception; the process is killed natively.
class AppCheckService {
  AppCheckService._();
  static final AppCheckService instance = AppCheckService._();

  static const _androidDebugTokenKey = 'worklist_android_app_check_debug_token';

  /// Registered & approved App Check debug token for Windows/desktop builds.
  /// Using this fixed token (instead of generating a new one per run) means
  /// every Windows run authenticates with the token already approved in the
  /// Firebase Console — no re-registration required. Firebase's Debug Provider
  /// accepts the approved token directly via [WindowsDebugProvider.debugToken].
  static const _windowsDebugToken = '68BB3669-9F26-404D-9B34-38FA9930DE29';

  static const debugTokenFromEnvironment = String.fromEnvironment(
    'APP_CHECK_DEBUG_TOKEN',
    defaultValue: '',
  );

  String? _lastLoggedDebugToken;
  bool _activated = false;

  /// Activate App Check for the current platform. Never throws.
  Future<void> activate() async {
    if (_activated) return;

    try {
      if (kIsWeb) {
        await _activateWeb();
      } else if (Platform.isAndroid) {
        if (kDebugMode) {
          await _activateAndroidDebug();
        } else {
          await _activateAndroidRelease();
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop platforms MUST register an App Check provider (DebugProvider).
        // Without it, the Firebase C++ SDK's RTDB WebSocket layer crashes with
        // a null pointer dereference when any database write or read triggers
        // the WebSocket connection. A DebugProvider satisfies the C++ SDK
        // without requiring Firebase Console registration.
        await _activateDesktop();
      } else {
        debugPrint(
          '[AppCheck] Skipped on ${Platform.operatingSystem} '
          '(no production App Check provider available)',
        );
      }

      if (_activated) {
        debugPrint('[AppCheck] Activated successfully');
      }
    } catch (e) {
      debugPrint('[AppCheck] Activation failed (non-fatal): $e');
      _activated = false;
    }
  }

  Future<void> _activateAndroidDebug() async {
    final debugToken = await _resolveDebugToken(_androidDebugTokenKey);
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(debugToken: debugToken),
    );
    _logDebugToken('Android', debugToken, FirebaseConfig.androidAppId);
    _activated = true;
  }

  Future<void> _activateAndroidRelease() async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: const AndroidPlayIntegrityProvider(),
    );
    debugPrint('[AppCheck] Android Play Integrity activated');
    _activated = true;
  }

  Future<void> _activateDesktop() async {
    // Reuse the registered & approved debug token (never generate a new one).
    // Passing the approved token directly to WindowsDebugProvider makes every
    // Windows run authenticate with the token already approved in the Firebase
    // Console, exactly as Firebase's Debug Provider implementation expects.
    const debugToken = _windowsDebugToken;
    await FirebaseAppCheck.instance.activate(
      providerWindows: const WindowsDebugProvider(debugToken: debugToken),
    );
    _logDebugToken(
      Platform.operatingSystem,
      debugToken,
      FirebaseConfig.windowsAppId.isNotEmpty
          ? FirebaseConfig.windowsAppId
          : FirebaseConfig.projectId,
    );
    _activated = true;
  }

  Future<void> _activateWeb() async {
    const siteKey = FirebaseConfig.recaptchaSiteKey;
    if (siteKey.isEmpty) {
      debugPrint('[AppCheck] Web reCAPTCHA site key not configured — skipping');
      return;
    }
    await FirebaseAppCheck.instance.activate(
      providerWeb: ReCaptchaV3Provider(siteKey),
    );
    debugPrint('[AppCheck] Web reCAPTCHA activated');
    _activated = true;
  }

  /// Enable or disable automatic App Check token refresh.
  /// Only meaningful after a successful [activate].
  Future<void> setTokenAutoRefreshEnabled(bool enabled) async {
    if (!_activated) return;
    try {
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(enabled);
    } catch (error) {
      debugPrint('[AppCheck] Auto-refresh setup failed: $error');
    }
  }

  /// Returns the current App Check token, or null if App Check is not active.
  Future<String?> getToken() async {
    if (!_activated) return null;
    try {
      return await FirebaseAppCheck.instance.getToken();
    } catch (error) {
      debugPrint('[AppCheck] getToken failed: $error');
      return null;
    }
  }

  Future<String> _resolveDebugToken(String key) async {
    if (debugTokenFromEnvironment.isNotEmpty) {
      return debugTokenFromEnvironment;
    }

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }

    final generated = _generateUuidV4();
    await prefs.setString(key, generated);
    return generated;
  }

  void _logDebugToken(String platform, String token, String appId) {
    if (_lastLoggedDebugToken == token) return;
    _lastLoggedDebugToken = token;
    debugPrint(
      'Register this $platform App Check debug token for app '
      '$appId in Firebase Console (App Check → Apps → Manage debug tokens): $token',
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
