import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../firebase/firebase_auth_listener.dart';
import '../firebase/firebase_cloud_service.dart';
import '../firebase/firebase_config.dart';
import '../firebase/google_oauth_service.dart';
import '../firebase/session_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  final _auth = AuthRepository();
  final _dashboard = DashboardRepository();
  final _cloud = FirebaseCloudService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false;
  bool _handlingLocalSignOut = false;
  /// UID that was already synced during [initialize()]. Used to suppress a
  /// duplicate startup pull when the auth-state listener later replays the
  /// same authenticated user.
  String? _startupUid;
  String? _error;
  String? _cloudNotice;
  DateTime? _lastSyncedAt;

  /// Auto-pull machinery: periodically fetch the other device's changes so
  /// both devices converge to the same cloud data without a manual refresh.
  /// Gated on "no pending local changes" so we never clobber edits that
  /// haven't uploaded yet.
  Timer? _autoPullTimer;
  AppLifecycleListener? _lifecycleListener;
  static const Duration _autoPullInterval = Duration(seconds: 30);

  /// Incremented every time a cloud pull successfully imports new data into
  /// SQLite.  Providers and screens that watch [AuthProvider] can compare
  /// against this value to know when to reload their data from the DB.
  int _cloudDataVersion = 0;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;
  String? get cloudNotice => _cloudNotice;
  String? get cloudEmail => _cloud.email;
  bool get cloudSignedIn => _cloud.isSignedIn;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  int get cloudDataVersion => _cloudDataVersion;
  bool get isGoogleSignInConfigured => FirebaseConfig.isGoogleSignInConfigured;
  String get googleSignInStatus => FirebaseConfig.googleSignInStatusLabel();
  bool get isGoogleLinked {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'google.com');
  }

  String? get googleEmail {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final googleProvider = user.providerData.cast<UserInfo?>().firstWhere(
          (p) => p?.providerId == 'google.com',
          orElse: () => null,
        );
    return googleProvider?.email;
  }

  @override
  void dispose() {
    FirebaseAuthListener.instance.stop();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // INITIALISE
  // Firebase is the source of truth.
  // On startup: always attempt to pull from cloud → import → refresh UI.
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> initialize() async {
    await FirebaseConfig.ensureLoaded();

    // Wait for Firebase Auth to finish restoring the persisted credential
    // before any cloud sync. On Windows/desktop the credential is restored
    // asynchronously and FirebaseAuth.currentUser is null at this point;
    // proceeding early makes the startup pull read a null (or Google
    // silent-sign-in fallback) uid. Awaiting the first authenticated user
    // guarantees _firebaseUid is applied before the first pull, and prevents
    // the Google silent-restoration fallback from selecting a wrong session
    // while auth is still pending.
    try {
      await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // No authenticated user yet (brand-new / fresh install). Proceed; the
      // startup pull is skipped and sync happens after an explicit login.
    }

    // Capture the uid we synced at startup so the auth-state listener does
    // not perform a duplicate pull for the very same user.
    _startupUid = FirebaseAuth.instance.currentUser?.uid;

    _startFirebaseAuthListeners();

    final savedUsername = await SessionStorage.loadActiveUsername();

    if (savedUsername != null) {
      final user = await _auth.getUserByUsername(savedUsername);
      if (user != null) {
        _currentUser = user;
        _auth.setActiveUser(user);
      } else {
        await SessionStorage.clearActiveUsername();
      }
    }

    final restoredCloud = await _cloud.restorePersistedSession();
    if (restoredCloud && _currentUser != null) {
      // ── Cloud session + known local user ─────────────────────────────────
      // ALWAYS pull from cloud first so we get the latest data from any
      // device.  Only fall back to uploading local data if the cloud slot
      // is completely empty (brand-new account or cloud was cleared).
      await _pullFromCloudOrFallback(
        _currentUser!.id!,
        reason: 'startup',
      );
    } else if (restoredCloud) {
      // ── Cloud session but no local account yet ────────────────────────────
      await _restoreLocalUserFromCloud(savedUsername);
    }

    if (_cloud.isSignedIn) {
      _cloud.runDiagnostics();
      // Retry any changes that were queued offline in a previous session
      // (belt-and-suspenders: FirebaseCloudService also does this internally
      // when a session is applied, but this covers startup ordering edge
      // cases). No-op if nothing is pending.
      _cloud.retryPendingUploads();
    }

    _initialized = true;
    _startAutoPull();
    notifyListeners();
  }

  // ── Auto-pull (cross-device convergence) ─────────────────────────────────
  void _startAutoPull() {
    _lifecycleListener?.dispose();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => _autoPull(),
    );
    _autoPullTimer?.cancel();
    _autoPullTimer = Timer.periodic(_autoPullInterval, (_) => _autoPull());
  }

  void _stopAutoPull() {
    _autoPullTimer?.cancel();
    _autoPullTimer = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }

  /// Pull the other device's changes from the cloud, but only when this
  /// device has no unsynced local edits — so we never overwrite local work
  /// that hasn't been uploaded yet. Safe no-op when not signed in.
  Future<void> _autoPull() async {
    final userId = _currentUser?.id;
    if (userId == null || !_cloud.isSignedIn) return;
    if (_cloud.hasPendingChanges) return; // don't clobber local edits
    await _pullFromCloudOrFallback(userId, reason: 'auto-pull');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // CORE SYNC HELPERS
  // ════════════════════════════════════════════════════════════════════════════

  /// Pull from cloud → import into SQLite → bump [cloudDataVersion].
  /// If the cloud slot is empty, fall back to pushing local data (so a
  /// brand-new device that already has local work doesn't lose it).
  Future<void> _pullFromCloudOrFallback(
    int userId, {
    required String reason,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    debugPrint('┌─────────────────────────────────────────────────────────');
    debugPrint('│ [Sync] START pull — reason: $reason');
    debugPrint('│   Timestamp : $now');
    debugPrint('│   userId    : $userId');
    debugPrint('└─────────────────────────────────────────────────────────');

    try {
      final result = await _cloud.pullIntoLocalUserResult(userId);
      switch (result) {
        case CloudPullResult.success:
          _lastSyncedAt = DateTime.now();
          _cloudDataVersion++;
          debugPrint(
              '[Sync] Pull succeeded ($reason). cloudDataVersion=$_cloudDataVersion');
          notifyListeners(); // screens watching cloudDataVersion will reload
          break;
        case CloudPullResult.empty:
          // Cloud is GENUINELY empty — push local data if we have any so the
          // cloud is seeded for the next device. This is the ONLY case where a
          // seed upload is safe; a conflict/failure must never seed.
          debugPrint('[Sync] Cloud slot empty ($reason) — checking local data.');
          final hasLocal = await _dashboard.hasUserData(userId);
          if (hasLocal) {
            await _cloud.uploadLocalUser(userId,
                reason: '$reason-seed-cloud-from-local');
            _lastSyncedAt = DateTime.now();
          } else {
            debugPrint('[Sync] Local also empty. Nothing to sync ($reason).');
          }
          break;
        case CloudPullResult.conflictSkipped:
          // Local changes are newer than the cloud. Do NOT seed/overwrite the
          // cloud blindly — upload the local (newer) copy through the normal
          // conflict-checked path so nothing is clobbered.
          debugPrint('[Sync] Pull skipped due to conflict ($reason) — '
              'queueing local changes for upload.');
          _cloud.uploadActiveUserInBackground(
              reason: '$reason-conflict-upload-local');
          break;
        case CloudPullResult.failed:
          // Non-destructive failure (network/permission). Leave local data
          // untouched; queued changes retry automatically.
          debugPrint('[Sync] Pull failed ($reason) — staying offline, '
              'no seed upload.');
          _cloudNotice = 'Could not reach Firebase. Working offline — data '
              'will sync when connection is restored.';
          break;
      }
    } catch (e, s) {
      debugPrint('[Sync] Pull failed ($reason): $e');
      debugPrint('[Sync] Stack: $s');
      // Non-fatal — user can still work offline; uploads will still happen
      // when they make changes.
      _cloudNotice = 'Could not reach Firebase on startup. '
          'Working offline — data will sync when connection is restored.';
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // FIREBASE AUTH LISTENERS
  // ════════════════════════════════════════════════════════════════════════════
  void _startFirebaseAuthListeners() {
    FirebaseAuthListener.instance.start(
      onAuthStateChanged: _onFirebaseAuthStateChanged,
      onIdTokenChanged: _onFirebaseIdTokenChanged,
    );
  }

  Future<void> _onFirebaseAuthStateChanged(User? user) async {
    if (!_initialized) return;

    // The startup pull already synced this exact user in initialize(). Skip a
    // duplicate pull when the auth-state listener replays the same account.
    if (_startupUid != null && user?.uid == _startupUid) return;

    if (user == null) {
      if (_handlingLocalSignOut) return;
      _cloud.clearSession();
      notifyListeners();
      return;
    }

    await _syncCloudSessionFromFirebaseUser(user);
  }

  Future<void> _onFirebaseIdTokenChanged(User? user) async {
    if (!_initialized || user == null) return;
    await _cloud.restorePersistedSession();
  }

  Future<void> _syncCloudSessionFromFirebaseUser(User user) async {
    final restored = await _cloud.restorePersistedSession();
    if (!restored) return;

    final savedUsername = await SessionStorage.loadActiveUsername();
    await _restoreLocalUserFromCloud(savedUsername);
  }

  Future<void> _restoreLocalUserFromCloud(String? savedUsername) async {
    final username = savedUsername ?? _cloud.username;
    if (username == null) return;

    final existing = await _auth.getUserByUsername(username);
    final user = existing ?? await _auth.ensureGoogleLocalAccount(username);
    _currentUser = user;
    _auth.setActiveUser(user);
    await SessionStorage.saveActiveUsername(user.username);

    // Always pull from cloud — cloud is source of truth.
    await _pullFromCloudOrFallback(user.id!, reason: 'restore-local-user');
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOGIN
  // After authentication: pull from cloud → import → refresh UI.
  // If cloud has no data yet, upload what we have locally.
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    final cleanedUsername = username.trim().toLowerCase();
    final localUser = await _auth.authenticate(cleanedUsername, password);

    try {
      await _cloud.signIn(cleanedUsername, password);
      final user = await _auth.ensureLocalAccount(cleanedUsername, password);
      _currentUser = user;
      _auth.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);

      // Pull cloud data first — cloud is the source of truth.
      await _pullFromCloudOrFallback(user.id!, reason: 'login');

      _isLoading = false;
      notifyListeners();
      _cloud.runDiagnostics();
      return true;
    } catch (e) {
      if (localUser != null || _cloud.isRecoverableCloudBlock(e)) {
        final user = localUser ??
            await _auth.ensureLocalAccount(cleanedUsername, password);
        _cloud.clearSession();
        _currentUser = user;
        _auth.setActiveUser(user);
        await SessionStorage.saveActiveUsername(user.username);
        _cloudNotice =
            'Signed in on this device. Your account will open automatically next time.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // REGISTER
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    try {
      final cleanedUsername = username.trim().toLowerCase();
      await _cloud.register(cleanedUsername, password);
      final user = await _auth.ensureLocalAccount(cleanedUsername, password);
      _currentUser = user;
      _auth.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);
      try {
        await _cloud.uploadLocalUser(user.id!, reason: 'register-new-account');
      } catch (e, s) {
        debugPrint('[Sync] Upload after register failed: $e');
        debugPrint('[Sync] Stack: $s');
        _cloudNotice =
            'Account created on this device. Cloud sync will retry when Firebase is available.';
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_cloud.isRecoverableCloudBlock(e)) {
        final cleanedUsername = username.trim().toLowerCase();
        final user = await _auth.ensureLocalAccount(cleanedUsername, password);
        _currentUser = user;
        _auth.setActiveUser(user);
        await SessionStorage.saveActiveUsername(user.username);
        _cloudNotice =
            'Account saved on this device. Cloud sync will retry when Firebase is available.';
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LINK EMAIL
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool> linkEmail(String email) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    try {
      await _cloud.linkEmail(email);
      final userId = _currentUser?.id;
      if (userId != null) {
        await _cloud.uploadLocalUser(userId, reason: 'link-email');
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // MANUAL SYNC
  // ════════════════════════════════════════════════════════════════════════════

  /// Uploads local → cloud (manual trigger from sync/account screen).
  Future<void> syncNow() async {
    final userId = _currentUser?.id;
    if (userId == null || !_cloud.isSignedIn) return;
    await _cloud.uploadLocalUser(userId, reason: 'manual-sync-now');
    _lastSyncedAt = DateTime.now();
  }

  /// Downloads cloud → local (manual trigger from sync/account screen).
  Future<bool> pullFromCloud() async {
    final userId = _currentUser?.id;
    if (userId == null || !_cloud.isSignedIn) {
      throw Exception('Not signed in to Firebase.');
    }
    // Forced restore: bypass the conflict guard so an explicit user action can
    // always recover a device that got stuck believing its local copy is newer.
    final pulled = await _cloud.pullIntoLocalUser(userId, force: true);
    if (pulled) {
      _lastSyncedAt = DateTime.now();
      _cloudDataVersion++;
      notifyListeners();
    }
    return pulled;
  }

  /// Pull-to-refresh entry point for list screens: pull from Firebase FIRST,
  /// import into SQLite, bump [cloudDataVersion] (which makes DashboardScreen
  /// reload every data provider) and refresh the UI — instead of only
  /// re-reading local SQLite. Safe/no-op when not signed in to Firebase.
  Future<void> pullFromCloudForRefresh() async {
    final userId = _currentUser?.id;
    if (userId == null || !_cloud.isSignedIn) return;
    await _pullFromCloudOrFallback(userId, reason: 'manual-refresh');
  }

  // ════════════════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN
  // ════════════════════════════════════════════════════════════════════════════
  Future<bool> signInWithGoogle() async {
    if (!FirebaseConfig.isGoogleSignInConfigured) {
      _error = FirebaseConfig.googleSignInUnavailableMessage();
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    final firebaseUser = FirebaseAuth.instance.currentUser;
    final alreadySignedInToFirebase = firebaseUser != null;

    if (alreadySignedInToFirebase) {
      try {
        final session =
            await GoogleOAuthService.instance.linkToCurrentFirebaseUser();
        _cloud.applySession(session);

        try {
          if (_currentUser?.id != null) {
            await _cloud.uploadLocalUser(_currentUser!.id!,
                reason: 'google-link-to-firebase-user');
          }
        } catch (e, s) {
          debugPrint('[Sync] Upload after Google link failed: $e');
          debugPrint('[Sync] Stack: $s');
          _cloudNotice =
              'Google linked. Cloud sync will retry when App Check allows this app.';
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    if (_currentUser != null) {
      _error =
          'Sign in with your username and password first to connect to Firebase, '
          'then tap "Sign in with Google" to link your Google account.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final session = await GoogleOAuthService.instance.signIn();
      _cloud.applySession(session);

      final fallback = session.firebaseUid == null;

      final username = _cloud.username ?? 'google_user';
      final user = await _auth.ensureGoogleLocalAccount(username);
      _currentUser = user;
      _auth.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);

      if (!fallback) {
        try {
          // Always pull from cloud first on Google sign-in.
          await _pullFromCloudOrFallback(user.id!, reason: 'google-signin');
        } catch (e, s) {
          debugPrint('[Sync] Google sign-in sync failed: $e');
          debugPrint('[Sync] Stack: $s');
          _cloudNotice =
              'Signed in with Google. Cloud sync will retry when App Check allows this app.';
        }
      } else {
        _cloudNotice =
            'Google account saved on this device. Cloud sync will work once '
            'Firebase App Check is set up.';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      await _signOutLocally(clearCloud: true);
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // LOGOUT
  // ════════════════════════════════════════════════════════════════════════════
  Future<void> logout() async {
    _stopAutoPull();
    await _signOutLocally(clearCloud: true);
    notifyListeners();
  }

  Future<void> _signOutLocally({required bool clearCloud}) async {
    _handlingLocalSignOut = true;
    try {
      _currentUser = null;
      if (clearCloud) {
        await _cloud.signOut();
      } else {
        _cloud.clearSession();
      }
      _auth.setActiveUser(null);
      await SessionStorage.clearActiveUsername();
      _error = null;
      _cloudNotice = null;
    } finally {
      _handlingLocalSignOut = false;
    }
  }

  void clearError() {
    _error = null;
    _cloudNotice = null;
    notifyListeners();
  }
}
