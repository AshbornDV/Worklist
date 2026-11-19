import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_check_service.dart';
import 'firebase_config.dart';

class FirebaseDiagnostics {
  FirebaseDiagnostics._();
  static final FirebaseDiagnostics instance = FirebaseDiagnostics._();

  Future<void> runAll() async {
    debugPrint('══════════════════════════════════════════════════════════');
    debugPrint('  🔍 COMPREHENSIVE FIREBASE DIAGNOSTICS');
    debugPrint('══════════════════════════════════════════════════════════');

    await _checkPlatform();
    await _checkFirebaseInitialization();
    await _checkAppCheck();
    await _checkAuthentication();
    await _checkRealtimeDatabase();
    await _checkConnectivity();
    await _checkConfig();

    debugPrint('══════════════════════════════════════════════════════════');
  }

  Future<void> _checkPlatform() async {
    debugPrint('  --- Platform ---');
    debugPrint('  OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    debugPrint('  Dart VM: ${Platform.version}');
    debugPrint('  Executable: ${Platform.executable}');
  }

  Future<void> _checkFirebaseInitialization() async {
    debugPrint('  --- Firebase Core ---');
    try {
      final app = Firebase.app();
      final options = app.options;
      debugPrint('  Firebase App: ${app.name}');
      debugPrint('  Project ID: ${options.projectId}');
      debugPrint('  Database URL: ${options.databaseURL}');
      debugPrint('  Storage Bucket: ${options.storageBucket}');
      debugPrint('  App ID: ${options.appId}');
      debugPrint('  API Key: ${options.apiKey.substring(0, 8)}...');
      debugPrint('  Firebase initialized: ✓');
    } catch (e) {
      debugPrint('  Firebase initialized: ✗ ($e)');
    }
  }

  Future<void> _checkAppCheck() async {
    debugPrint('  --- App Check ---');
    try {
      final token = await FirebaseAppCheck.instance.getToken();
      if (token != null && token.isNotEmpty) {
        debugPrint('  App Check token: ${token.substring(0, 20)}...${token.substring(token.length - 4)}');
        debugPrint('  App Check token length: ${token.length}');
        debugPrint('  App Check status: ✓');
      } else {
        debugPrint('  App Check token: null');
        debugPrint('  App Check status: ✗ (null token)');
      }
    } catch (e) {
      debugPrint('  App Check getToken failed: $e');
      // Check if it's a 403 (unregistered debug token)
      final msg = e.toString().toLowerCase();
      if (msg.contains('403') || msg.contains('permission_denied') || msg.contains('app attestation failed')) {
        debugPrint('  ↳ CAUSE: Debug token NOT REGISTERED in Firebase Console');
        final tokenFromPrefs = await AppCheckService.instance.getToken();
        if (tokenFromPrefs != null && tokenFromPrefs.isNotEmpty) {
          debugPrint('  ↳ TOKEN: $tokenFromPrefs');
          debugPrint('  ↳ FIX: Register this token in Firebase Console → App Check → Manage debug tokens');
        }
        debugPrint('  ↳ Alternatively, set --dart-define=APP_CHECK_DEBUG_TOKEN=<token>');
      }
    }
  }

  Future<void> _checkAuthentication() async {
    debugPrint('  --- Authentication ---');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('  Auth state: Signed in');
        debugPrint('  UID: ${user.uid}');
        debugPrint('  Email: ${user.email}');
        debugPrint('  Display name: ${user.displayName}');
        debugPrint('  Email verified: ${user.emailVerified}');
        debugPrint('  Providers: ${user.providerData.map((p) => p.providerId).join(', ')}');
        debugPrint('  Anonymous: ${user.isAnonymous}');

        try {
          final token = await user.getIdToken(true);
          if (token != null && token.isNotEmpty) {
            debugPrint('  ID token: ${token.substring(0, 20)}...${token.substring(token.length - 4)}');
            debugPrint('  ID token length: ${token.length}');
            debugPrint('  Auth token: ✓');
          } else {
            debugPrint('  ID token: null');
            debugPrint('  Auth token: ✗');
          }
        } catch (e) {
          debugPrint('  ID token fetch failed: $e');
        }
      } else {
        debugPrint('  Auth state: Not signed in');
      }
    } catch (e) {
      debugPrint('  Auth check failed: $e');
    }
  }

  Future<void> _checkRealtimeDatabase() async {
    debugPrint('  --- Realtime Database ---');
    try {
      final options = Firebase.app().options;
      final databaseUrl = options.databaseURL;
      debugPrint('  Database URL: $databaseUrl');

      if (databaseUrl == null || databaseUrl.isEmpty) {
        debugPrint('  ✗ No database URL configured in FirebaseOptions');
        return;
      }

      // Print App Check token for diagnosis
      try {
        final acToken = await FirebaseAppCheck.instance.getToken();
        debugPrint('  App Check token present: ${acToken != null && acToken.isNotEmpty}');
        if (acToken != null && acToken.isNotEmpty) {
          debugPrint('  App Check token (first 20 chars): ${acToken.substring(0, 20)}...');
        }
      } catch (acErr) {
        debugPrint('  App Check token fetch failed: $acErr');
      }

      // Print current auth user
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('  Auth UID: ${currentUser?.uid ?? "null"}');
      if (currentUser != null) {
        try {
          final idTok = await currentUser.getIdToken(false);
          debugPrint('  Auth ID token present: ${idTok != null && idTok.isNotEmpty}');
        } catch (_) {}
      }

      // Test SDK write
      debugPrint('  SDK test: writing /_diagnostic...');
      final ref = FirebaseDatabase.instance.ref('_diagnostic');
      await ref.set({
        'timestamp': DateTime.now().toUtc().toIso8601String(),
        'platform': Platform.operatingSystem,
        'test': 'diagnostic_write',
      });
      debugPrint('  SDK write: ✓');

      // Test SDK read
      final snapshot = await ref.get();
      if (snapshot.exists) {
        debugPrint('  SDK read: ✓ (value exists)');
        debugPrint('  SDK read value: ${snapshot.value}');
      } else {
        debugPrint('  SDK read: ✓ (no data)');
      }

      // Clean up
      await ref.remove();
      debugPrint('  SDK cleanup: ✓');
    } on FirebaseException catch (e) {
      debugPrint('  SDK FirebaseException:');
      debugPrint('    code: ${e.code}');
      debugPrint('    message: ${e.message}');
      debugPrint('    plugin: ${e.plugin}');
      if (e.message?.toLowerCase().contains('network disconnect') == true) {
        debugPrint('  ↳ CAUSE: WebSocket connection to RTDB failed (likely App Check)');
      } else if (e.message?.toLowerCase().contains('permission denied') == true) {
        debugPrint('  ↳ CAUSE: Security Rules deny the write');
      } else if (e.message?.toLowerCase().contains('app check') == true) {
        debugPrint('  ↳ CAUSE: App Check enforcement blocking the request');
      } else {
        debugPrint('  ↳ Running REST tests to identify exact cause...');
      }
      // Always run REST tests for precise diagnosis
      await _checkRealtimeDatabaseRest();
    } catch (e, s) {
      debugPrint('  ✗ SDK test failed: $e');
      debugPrint('  Stack trace: $s');

      // Fall back: test REST API
      await _checkRealtimeDatabaseRest();
    }
  }

  Future<void> _checkRealtimeDatabaseRest() async {
    debugPrint('  --- Realtime Database (REST fallback) ---');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('  REST test: SKIP (no authenticated user)');
        return;
      }

      final token = await user.getIdToken(true);
      if (token == null || token.isEmpty) {
        debugPrint('  REST test: SKIP (no ID token)');
        return;
      }

      final databaseUrl = Firebase.app().options.databaseURL;
      if (databaseUrl == null || databaseUrl.isEmpty) {
        debugPrint('  REST test: SKIP (no database URL)');
        return;
      }

      // 1) Try with auth parameter (older approach, still works in many cases)
      debugPrint('  --- REST with ?auth=token ---');
      final uri = Uri.parse('$databaseUrl/_diagnostic_rest.json?auth=$token');
      debugPrint('  URL: ${uri.toString().replaceAll(token, '***')}');
      final response = await http.put(
        uri,
        body: '{"timestamp":"${DateTime.now().toUtc().toIso8601String()}"}',
      );
      debugPrint('  Status: ${response.statusCode}');
      debugPrint('  Body: ${response.body}');

      // 2) Try with Authorization header (modern approach, required with App Check)
      debugPrint('  --- REST with Authorization: Bearer ---');
      final uri2 = Uri.parse('$databaseUrl/_diagnostic_rest.json');
      final response2 = await http.put(
        uri2,
        headers: {'Authorization': 'Bearer $token'},
        body: '{"timestamp":"${DateTime.now().toUtc().toIso8601String()}"}',
      );
      debugPrint('  Status: ${response2.statusCode}');
      debugPrint('  Body: ${response2.body}');

      // 3) Try to read security rules (requires owner token, but worth a try)
      debugPrint('  --- REST read rules (may fail if not admin) ---');
      try {
        final rulesUri = Uri.parse('$databaseUrl/.settings/rules.json?auth=$token');
        final rulesResponse = await http.get(rulesUri);
        debugPrint('  Status: ${rulesResponse.statusCode}');
        if (rulesResponse.statusCode == 200) {
          debugPrint('  Rules: ${rulesResponse.body}');
        } else {
          debugPrint('  Body: ${rulesResponse.body}');
        }
      } catch (_) {}

      // Analyze results
      if (response.statusCode == 200 || response2.statusCode == 200) {
        debugPrint('  REST test: ✓ (writes accepted)');
        // Clean up whichever worked
        final okUri = response.statusCode == 200
            ? uri
            : Uri.parse('$databaseUrl/_diagnostic_rest.json');
        await http.delete(okUri, headers: response.statusCode == 200 ? null : {'Authorization': 'Bearer $token'});
      } else {
        final errBody = response.body.isNotEmpty ? response.body : response2.body;
        final errStatus = response.statusCode != 200 ? response.statusCode : response2.statusCode;
        debugPrint('  REST test: ✗ ($errStatus)');
        if (errBody.toLowerCase().contains('permission denied')) {
          debugPrint('  ↳ CAUSE: Security Rules deny the write');
        } else if (errBody.toLowerCase().contains('appcheck')) {
          debugPrint('  ↳ CAUSE: App Check enforcement blocking the request (missing token)');
        } else if (errBody.toLowerCase().contains('app check')) {
          debugPrint('  ↳ CAUSE: App Check enforcement blocking the request');
        } else if (errBody.toLowerCase().contains('token')) {
          debugPrint('  ↳ CAUSE: Auth token issue');
        } else if (errBody.contains('401')) {
          debugPrint('  ↳ CAUSE: Unauthorized (missing App Check or auth)');
        } else {
          debugPrint('  ↳ Body: $errBody');
        }
      }
    } catch (e, s) {
      debugPrint('  REST test failed: $e');
      debugPrint('  Stack trace: $s');
    }
  }

  Future<void> _checkConnectivity() async {
    debugPrint('  --- HTTP Connectivity ---');
    final endpoints = [
      'https://firebase.googleapis.com',
      'https://www.googleapis.com',
      'https://identitytoolkit.googleapis.com',
      'https://securetoken.googleapis.com',
      Firebase.app().options.databaseURL ?? 'https://worklist-armoon-default-rtdb.asia-southeast1.firebasedatabase.app',
    ];

    for (final url in endpoints) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        debugPrint('  $url → ${response.statusCode}');
      } catch (e) {
        debugPrint('  $url → FAILED ($e)');
      }
    }
  }

  Future<void> _checkConfig() async {
    debugPrint('  --- Configuration ---');
    debugPrint('  currentApiKey: ${FirebaseConfig.currentApiKey.substring(0, 8)}...');

    if (Platform.isAndroid) {
      debugPrint('  androidAppId: ${FirebaseConfig.androidAppId}');
      debugPrint('  androidPackageName: ${FirebaseConfig.androidPackageName}');
    } else if (Platform.isWindows) {
      debugPrint('  windowsAppId: ${FirebaseConfig.windowsAppId}');
    }

    debugPrint('  projectId: ${FirebaseConfig.projectId}');
    debugPrint('  projectNumber: ${FirebaseConfig.projectNumber}');
    debugPrint('  isGoogleSignInConfigured: ${FirebaseConfig.isGoogleSignInConfigured}');
    debugPrint('  googleSignInPlatform: ${FirebaseConfig.googleSignInPlatform.name}');
  }
}
