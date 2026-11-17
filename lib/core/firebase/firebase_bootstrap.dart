import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';

import '../../firebase_options.dart';
import 'app_check_service.dart';
import 'firebase_config.dart';

Future<void> initializeFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseConfig.ensureLoaded();
  await AppCheckService.instance.activate();
  await configureFirebaseAuth();
  await _initializeGoogleSignIn();
}

/// Configures Firebase Auth persistence and App Check token auto-refresh.
Future<void> configureFirebaseAuth() async {
  try {
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  } catch (e) {
    debugPrint('[Firebase] setPersistence failed (non-fatal): $e');
  }

  try {
    await AppCheckService.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    debugPrint('[Firebase] setTokenAutoRefreshEnabled failed (non-fatal): $e');
  }
}

Future<void> _initializeGoogleSignIn() async {
  if (!FirebaseConfig.isDesktop) return;

  final clientId = FirebaseConfig.resolvedDesktopClientId;
  if (clientId.isEmpty) return;

  await GoogleSignInDart.register(
    clientId: clientId,
    port: Uri.parse(FirebaseConfig.oauthRedirectUri).port,
  );
}
