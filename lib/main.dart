import 'dart:async';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_links/app_links.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_cloud_service.dart';
import 'core/firebase/firebase_notification_handler.dart';
import 'core/providers/auth_provider.dart' as worklist_auth;
import 'core/providers/theme_provider.dart';
import 'core/providers/site_provider.dart';
import 'core/providers/store_product_provider.dart';
import 'core/providers/user_service_provider.dart';
import 'core/providers/worker_provider.dart';
import 'core/sync/sync_service.dart';
import 'features/documents/services/document_permissions.dart';

/// Top-level FCM background message handler. Must be static/top-level and
/// registered BEFORE Firebase is used, otherwise a data-only message arriving
/// while the app is killed has no handler and is silently dropped.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] background message: ${message.messageId}');
  await FirebaseNotificationHandler.handleBackgroundMessage(message);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeFirebase();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseNotificationHandler.instance.initialize();
  await _requestPermissions();
  // Android 13+ requires a runtime POST_NOTIFICATIONS grant for the WorkManager
  // reminder schedule; the system shows its own prompt (no BuildContext yet).
  if (Platform.isAndroid) {
    await DocumentPermissions.instance.requestNotificationsAtLaunch();
  }

  // Wire the database write hook to the cloud-sync layer so ANY local
  // user-data mutation (from providers OR screens) pushes to Firebase.
  // DatabaseHelper stays Firebase-free; this is the only place the two meet.
  DatabaseHelper.onUserMutate =
      () => FirebaseCloudService.instance.uploadActiveUserInBackground(
            reason: 'local-data-changed',
          );

  final authProvider = worklist_auth.AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SiteProvider()),
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
        ChangeNotifierProvider(create: (_) => StoreProductProvider()),
        ChangeNotifierProvider(create: (_) => UserServiceProvider()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: const SiteWorkerManagerApp(),
    ),
  );

  // Email-link (passwordless) sign-in: complete the flow when the app is
  // opened via the Firebase deep link. Runs after runApp so providers exist.
  _initEmailLinkHandler(authProvider);
}

Future<void> _initEmailLinkHandler(worklist_auth.AuthProvider authProvider) async {
  final appLinks = AppLinks();

  // Handle the link that launched the app (cold start).
  try {
    final initialLink = await appLinks.getInitialLink();
    if (initialLink != null) {
      await _tryCompleteEmailLink(authProvider, initialLink.toString());
    }
  } catch (e) {
    debugPrint('[EmailLink] Initial link error (non-fatal): $e');
  }

  // Handle links received while the app is running.
  appLinks.uriLinkStream.listen(
    (uri) => _tryCompleteEmailLink(authProvider, uri.toString()),
    onError: (e) => debugPrint('[EmailLink] Stream error (non-fatal): $e'),
  );
}

Future<void> _tryCompleteEmailLink(worklist_auth.AuthProvider authProvider, String link) async {
  try {
    final isEmailLink = FirebaseAuth.instance.isSignInWithEmailLink(link);
    if (!isEmailLink) return;
    debugPrint('[EmailLink] Completing email-link sign-in');
    await authProvider.completeEmailLinkSignIn(link);
  } catch (e) {
    debugPrint('[EmailLink] Completion error (non-fatal): $e');
  }
}

Future<void> _requestPermissions() async {
  try {
    final locPerm = await Geolocator.checkPermission();
    if (locPerm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  } catch (e) {
    debugPrint('[App] Location permission request failed (non-fatal): $e');
  }
}