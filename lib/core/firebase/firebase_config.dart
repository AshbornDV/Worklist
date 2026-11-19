import 'dart:io';

import '../../firebase_options.dart';
import 'google_services_config.dart';

enum GoogleSignInPlatform {
  android,
  desktop,
  unsupported,
}

class FirebaseConfig {
  FirebaseConfig._();

  static const apiKey = 'AIzaSyATBlLwSqsb7OAKhF1e1vkbNYddfZVZC1c';
  static const windowsApiKey = 'AIzaSyC3hv95t2qwpwc4gPPK6aY0B6gAjchcL4g';
  static const projectId = 'worklist-armoon';
  static const projectNumber = '867700541514';
  static const androidAppId = '1:867700541514:android:7762f61d5690ffcb2afeb3';
  static const windowsAppId = '1:867700541514:web:f75f3c3ce0b7d1c52afeb3';
  static const androidPackageName = 'com.example.worklist';

  /// reCAPTCHA v3 site key for the Windows (web) Firebase app in App Check.
  /// Create at https://www.google.com/recaptcha/admin and register it in
  /// Firebase Console → App Check → worklist (windows) → reCAPTCHA.
  static const recaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: '',
  );

  /// Platform API key from [DefaultFirebaseOptions].
  static String get currentApiKey {
    if (Platform.isWindows) return windowsApiKey;
    return DefaultFirebaseOptions.currentPlatform.apiKey;
  }

  /// Loopback redirect used by google_sign_in_dartio on desktop (no trailing slash).
  static const oauthRedirectUri = 'http://127.0.0.1:42841';

  /// Deep-link base for email‑link sign‑in.
  /// Keep this in sync with ActionCodeSettings.url in cloud_service.dart.
  static const deepLinkBase = 'https://$projectId.firebaseapp.com';

  /// Web OAuth client ID used as [GoogleSignIn.serverClientId] on Android and
  /// as the Desktop OAuth client ID on Windows (falls back here if no dedicated
  /// Desktop client is provided). Override via --dart-define=GOOGLE_WEB_CLIENT_ID=...
  static const googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '867700541514-87o3261m8a4h26kf2gmhoep0vrk11uud.apps.googleusercontent.com',
  );

  /// Desktop OAuth client ID for Windows/Linux/macOS via google_sign_in_dartio.
  /// When empty the [webClientId] is used as a fallback; loopback redirect URIs
  /// must be authorised in the Google Cloud Console for the Web client.
  /// Override via --dart-define=GOOGLE_DESKTOP_CLIENT_ID=...
  static const googleDesktopClientId = String.fromEnvironment(
    'GOOGLE_DESKTOP_CLIENT_ID',
    defaultValue: '',
  );

  /// Client ID used for desktop Google Sign-In.
  /// Falls back to the Web client when no Desktop client is supplied; in that
  /// case add [oauthRedirectUri] exactly (no trailing slash) to the Web client's
  /// authorized redirect URIs in Google Cloud Console.
  static String get resolvedDesktopClientId {
    if (googleDesktopClientId.isNotEmpty) return googleDesktopClientId;
    return resolvedWebClientId;
  }

  static bool _loaded = false;

  static GoogleSignInPlatform get googleSignInPlatform {
    if (Platform.isAndroid) return GoogleSignInPlatform.android;
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      return GoogleSignInPlatform.desktop;
    }
    return GoogleSignInPlatform.unsupported;
  }

  static bool get isDesktop => googleSignInPlatform == GoogleSignInPlatform.desktop;

  static bool get isAndroid => googleSignInPlatform == GoogleSignInPlatform.android;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    await GoogleServicesConfig.load();
    _loaded = true;
  }

  /// Web client ID for Android Firebase Auth (dart-define overrides bundled JSON).
  static String get resolvedWebClientId {
    if (googleWebClientId.isNotEmpty) return googleWebClientId;
    return GoogleServicesConfig.webClientId ?? '';
  }

  static bool get isGoogleSignInConfigured {
    switch (googleSignInPlatform) {
      case GoogleSignInPlatform.android:
        return resolvedWebClientId.isNotEmpty;
      case GoogleSignInPlatform.desktop:
        return resolvedDesktopClientId.isNotEmpty;
      case GoogleSignInPlatform.unsupported:
        return false;
    }
  }

  static String googleSignInStatusLabel() {
    if (isGoogleSignInConfigured) {
      return isAndroid
          ? 'Google sign-in is ready on this Android device.'
          : 'Google sign-in is ready on this computer.';
    }

    switch (googleSignInPlatform) {
      case GoogleSignInPlatform.android:
        return 'Google sign-in needs Firebase setup: enable the Google provider, '
            'add SHA-1 and SHA-256 fingerprints, then download a new '
            'google-services.json and rebuild the app.';
      case GoogleSignInPlatform.desktop:
        return 'Google sign-in needs a Desktop OAuth client ID from Google Cloud '
            'Console (APIs & Services → Credentials → Create OAuth client → '
            'Desktop app). Build or run with '
            '--dart-define=GOOGLE_DESKTOP_CLIENT_ID=your-client-id.apps.googleusercontent.com';
      case GoogleSignInPlatform.unsupported:
        return 'Google sign-in is not available on this platform.';
    }
  }

  static String googleSignInUnavailableMessage() {
    switch (googleSignInPlatform) {
      case GoogleSignInPlatform.android:
        return 'Google sign-in is not configured for Android yet. Enable the Google '
            'provider in Firebase Authentication, add your debug and release SHA-1 '
            'and SHA-256 fingerprints, download an updated google-services.json '
            '(it must include a Web OAuth client), place it in android/app/, copy '
            'it to assets/google-services.json, then rebuild.';
      case GoogleSignInPlatform.desktop:
        return 'Google sign-in is not configured for Windows yet. In Google Cloud '
            'Console create a Desktop app OAuth client (loopback redirect URIs are '
            'allowed automatically), enable Google sign-in in Firebase Authentication, '
            'then run the app with '
            '--dart-define=GOOGLE_DESKTOP_CLIENT_ID=your-desktop-client-id.apps.googleusercontent.com';
      case GoogleSignInPlatform.unsupported:
        return 'Google sign-in is not supported on this platform.';
    }
  }
}
