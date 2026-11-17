import 'dart:async';
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'app.dart';
import 'core/database/database_helper.dart';
import 'core/firebase/firebase_bootstrap.dart';
import 'core/firebase/firebase_cloud_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/site_provider.dart';
import 'core/providers/store_product_provider.dart';
import 'core/providers/user_service_provider.dart';
import 'core/providers/worker_provider.dart';
import 'core/sync/sync_service.dart';
import 'features/documents/services/document_permissions.dart';
import 'core/notifications/background/background_notification_callback.dart';
import 'core/notifications/background/windows_background_scheduler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeFirebase();
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

  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Phase 7 — background notification scheduling. Android schedules a periodic
  // WorkManager task (resilient to app-close / reboot); Windows starts an
  // in-process timer (covers minimized/foreground, degrades gracefully for
  // app-closed since no OS background API exists). Both are idempotent.
  if (Platform.isAndroid) {
    unawaited(initializeBackgroundScheduling());
  } else if (Platform.isWindows) {
    WindowsBackgroundScheduler().start();
  }

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
