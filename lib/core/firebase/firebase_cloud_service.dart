import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart';
import '../repositories/dashboard_repository.dart';
import '../notifications/sync/notification_cloud_sync_service.dart';
import 'firebase_config.dart';
import 'firebase_diagnostics.dart';
import 'google_oauth_service.dart';
import 'session_storage.dart';

/// Outcome of a cloud pull, so callers can tell the four cases apart and
/// never mistake a conflict-skip for an empty cloud (which previously caused
/// a stale local upload to overwrite newer cloud data).
enum CloudPullResult {
  /// Cloud data was downloaded and written into local SQLite.
  success,

  /// The cloud slot is genuinely empty (brand-new account / cleared cloud).
  /// Only in this case may the caller seed the cloud from local data.
  empty,

  /// Local changes are newer than the cloud, so the destructive replace was
  /// skipped. The caller must NOT treat this as empty and must NOT seed-upload.
  conflictSkipped,

  /// The pull failed (network / permission / parse error). Non-destructive.
  failed,
}

class FirebaseCloudService {
  FirebaseCloudService._();
  static final FirebaseCloudService instance = FirebaseCloudService._();

  final _sync = DashboardRepository();
  final _auth = AuthRepository();

  String? _idToken;
  String? _refreshToken;
  String? _firebaseUid;
  String? _username;
  String? _email;
  DateTime? _tokenExpiresAt;
  Future<void>? _uploadFuture;

  // ── Offline queue / retry state ──────────────────────────────────────────
  // Local changes are synced by re-exporting the whole SQLite database, so
  // instead of queuing individual operations we persist a single "dirty"
  // flag + timestamp per Firebase account. This survives app restarts, lets
  // us retry uploads that failed while offline, and gives us a timestamp to
  // compare against the cloud's `updatedAt` for conflict detection.
  static const _pendingKeyPrefix = 'cloud_sync_pending_';
  static const _dirtySinceKeyPrefix = 'cloud_sync_dirty_since_';
  static const _knownCloudUpdatedAtKeyPrefix =
      'cloud_sync_known_cloud_updated_at_';
  static const _maxUploadAttempts = 3;
  static const _retryTimerInterval = Duration(minutes: 2);

  // Conflict comparisons rely on each device's own wall clock (the cloud
  // `updatedAt` is written as an ISO-8601 string; introducing Firebase server
  // timestamps would change that stored format and break parsing of existing
  // data). To avoid small cross-device clock skew making a device wrongly
  // believe its local copy is newer, only treat local changes as newer when
  // they lead the cloud by more than this tolerance.
  static const _clockSkewTolerance = Duration(minutes: 2);

  bool _pendingDirty = false;
  Timer? _retryTimer;

  bool get isSignedIn =>
      _firebaseUid != null &&
      (_idToken != null || FirebaseAuth.instance.currentUser != null);
  String? get username => _username;
  String? get email => _email;

  /// True if this device has local changes that have not been confirmed as
  /// uploaded to Firebase yet (either still in flight, or queued after a
  /// failed attempt / being offline).
  bool get hasPendingChanges => _pendingDirty;

  bool isRecoverableCloudBlock(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('app check') ||
        message.contains('internal error') ||
        message.contains('internal-error') ||
        message.contains('network') ||
        message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('timed out');
  }

  // ── Offline queue / retry / conflict-detection helpers ────────────────

  /// Marks the current account as having unsynced local changes. Called
  /// right before a background upload is attempted so the "dirty" state is
  /// durable even if the app is killed before the upload completes.
  Future<void> _markPendingSync(String uid) async {
    _pendingDirty = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_pendingKeyPrefix$uid', true);
    final dirtySinceKey = '$_dirtySinceKeyPrefix$uid';
    if (prefs.getString(dirtySinceKey) == null) {
      // Only set once per divergence window so repeated edits don't keep
      // pushing the baseline forward (that would make conflict detection
      // always favor local changes).
      await prefs.setString(
          dirtySinceKey, DateTime.now().toUtc().toIso8601String());
    }
  }

  /// Clears the pending/dirty state once local changes are confirmed synced.
  Future<void> _clearPendingSync(String uid) async {
    _pendingDirty = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pendingKeyPrefix$uid');
    await prefs.remove('$_dirtySinceKeyPrefix$uid');
  }

  Future<bool> _readPendingSync(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_pendingKeyPrefix$uid') ?? false;
  }

  Future<DateTime?> _getDirtySince(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_dirtySinceKeyPrefix$uid');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  Future<void> _setKnownCloudUpdatedAt(String uid, DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_knownCloudUpdatedAtKeyPrefix$uid',
      value.toUtc().toIso8601String(),
    );
  }

  Future<DateTime?> _getKnownCloudUpdatedAt(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_knownCloudUpdatedAtKeyPrefix$uid');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  /// Hydrates [_pendingDirty] from disk and starts the periodic retry timer.
  /// Safe to call multiple times; fire-and-forget from [applySession] so the
  /// synchronous session-restore flow isn't blocked on SharedPreferences I/O.
  Future<void> _hydratePendingStateAndStartRetryTimer() async {
    final uid = _firebaseUid;
    if (uid == null) return;
    _pendingDirty = await _readPendingSync(uid);
    _startRetryTimer();
    if (_pendingDirty) {
      debugPrint('[CloudSync] Found queued offline changes for $uid from a '
          'previous session — will retry upload.');
      uploadActiveUserInBackground(reason: 'resume-queued-offline-changes');
    }
  }

  void _startRetryTimer() {
    _retryTimer ??= Timer.periodic(_retryTimerInterval, (_) {
      if (_pendingDirty) {
        uploadActiveUserInBackground(reason: 'periodic-retry');
      }
    });
  }

  void _stopRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  Duration _backoffDelay(int attempt) {
    final seconds = 1 << attempt; // 1s, 2s, 4s, ...
    return Duration(seconds: seconds.clamp(1, 30));
  }

  /// Retries [reason]-triggered uploads for the active user, if any local
  /// changes are still queued from a previous session. Safe to call often
  /// (e.g. on app startup/resume) — it is a no-op when nothing is pending.
  Future<void> retryPendingUploads() async {
    final uid = _firebaseUid;
    final userId = _auth.activeUserId;
    if (uid == null || userId == null || !isSignedIn) return;
    final pending = await _readPendingSync(uid);
    _pendingDirty = pending;
    if (!pending) return;
    debugPrint('[CloudSync] Retrying queued offline changes for $uid.');
    uploadActiveUserInBackground(reason: 'retry-pending-uploads');
  }

  Future<void> register(String username, String password) async {
    await _authenticate(
      endpoint: 'accounts:signUp',
      username: username,
      password: password,
    );
  }

  Future<void> signIn(String username, String password) async {
    await _authenticate(
      endpoint: 'accounts:signInWithPassword',
      username: username,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    final session = await GoogleOAuthService.instance.signIn();
    applySession(session);
    await SessionStorage.saveActiveUsername(_username ?? 'google_user');
  }

  Future<bool> restorePersistedSession() async {
    await FirebaseConfig.ensureLoaded();

    // PREFER the Google silent-sign-in credential. For this app a Google
    // account is the single source of identity, so resolving the Firebase UID
    // from the Google credential (rather than the possibly-stale/possibly-null
    // FirebaseAuth.currentUser on Windows desktop) guarantees the SAME uid on
    // every launch and the SAME uid across Android/Windows for the same Google
    // account. FirebaseAuth.instance.currentUser is only used as a fallback
    // when Google silent sign-in is unavailable; a null-UID session is never
    // applied (that would make every RTDB request target users/null).
    final silentSession =
        await GoogleOAuthService.instance.tryRestoreSilentSignIn();
    if (silentSession != null && silentSession.firebaseUid != null) {
      applySession(silentSession);
      return true;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        // Force-refresh the ID token. On desktop/Windows the Firebase Auth
        // plugin does NOT transparently refresh a persisted session the way
        // Android does, and a stale token makes every RTDB request fail with
        // "permission denied" → the startup pull throws → the app reports
        // "Could not reach Firebase on startup" and stays offline. A fresh
        // login works because it fetches a new token; restoring must too.
        final idToken = await firebaseUser.getIdToken(true);
        if (idToken == null || idToken.isEmpty) return false;
        applySession(
          FirebaseAuthSession(
            idToken: idToken,
            refreshToken: '',
            firebaseUid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            managedByFirebaseAuth: true,
          ),
        );
        return true;
      } catch (e) {
        debugPrint('[CloudSync] restorePersistedSession failed: $e');
        return false;
      }
    }

    return false;
  }

  void applySession(FirebaseAuthSession session) {
    _idToken = session.idToken;
    _refreshToken = session.refreshToken;
    _firebaseUid = session.firebaseUid;
    _email = session.email;
    _username = _usernameFromEmail(session.email) ??
        _usernameFromEmail(session.displayName) ??
        'google_user';
    _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 55));
    // Fire-and-forget: restore any queued offline changes from a previous
    // session and start the periodic retry timer. Not awaited so callers of
    // applySession (which is synchronous) are not blocked on disk I/O.
    unawaited(_hydratePendingStateAndStartRetryTimer());
    // Phase 12: converge notification *metadata* (read/unread/dismissed/
    // archived/snoozed + reminder history + preferences) across devices. Same
    // Google uid on Android & Windows → same cloud slot. Platform scheduled
    // jobs (WorkManager / Windows timers) are intentionally NOT touched.
    unawaited(
      NotificationCloudSyncService.instance.initForSession(session.firebaseUid ?? ''),
    );
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleOAuthService.instance.signOut();
    await SessionStorage.clearActiveUsername();
    clearSession();
  }

  void clearSession() {
    _idToken = null;
    _refreshToken = null;
    _firebaseUid = null;
    _username = null;
    _email = null;
    _tokenExpiresAt = null;
    _pendingDirty = false;
    _stopRetryTimer();
  }

  Future<void> linkEmail(String email) async {
    final token = await _validIdToken();
    final cleanedEmail = email.trim().toLowerCase();
    final response = await http.post(
      Uri.https(
        'identitytoolkit.googleapis.com',
        '/v1/accounts:update',
        {'key': FirebaseConfig.currentApiKey},
      ),
      headers: await _jsonHeaders(authToken: token),
      body: jsonEncode({
        'idToken': token,
        'email': cleanedEmail,
        'returnSecureToken': true,
      }),
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_authMessage(body));
    }

    _idToken = body['idToken'] as String? ?? _idToken;
    _refreshToken = body['refreshToken'] as String? ?? _refreshToken;
    _firebaseUid = body['localId'] as String? ?? _firebaseUid;
    _email = cleanedEmail;
  }

  /// Pull user data from Firebase Realtime Database via SDK.
  ///
  /// Backward-compatible boolean wrapper: returns true only when cloud data
  /// was actually written into local SQLite. Prefer [pullIntoLocalUserResult]
  /// when the caller needs to distinguish empty vs conflict vs failure.
  Future<bool> pullIntoLocalUser(int localUserId, {bool force = false}) async {
    final result =
        await pullIntoLocalUserResult(localUserId, force: force);
    return result == CloudPullResult.success;
  }

  /// Pull user data from Firebase Realtime Database via SDK, returning a
  /// [CloudPullResult] so callers can distinguish:
  ///   • success          – cloud data written locally
  ///   • empty            – no cloud data yet (safe to seed from local)
  ///   • conflictSkipped  – local changes newer; pull skipped (do NOT seed)
  ///   • failed           – network/permission/parse error (do NOT seed)
  ///
  /// [force] bypasses the conflict guard for explicit user-initiated restores
  /// ("Restore from cloud"), which is how a device that got stuck believing
  /// its local copy is newer can recover.
  Future<CloudPullResult> pullIntoLocalUserResult(
    int localUserId, {
    bool force = false,
  }) async {
    final uid = _firebaseUid;
    if (uid == null) return CloudPullResult.failed;

    try {
      final ref = FirebaseDatabase.instance.ref('users/$uid');
      final snapshot = await ref.get();
      debugPrint('[CloudSync] SDK GET /users/$uid - exists=${snapshot.exists}');

      if (!snapshot.exists) {
        debugPrint('[CloudSync] No cloud data found');
        return CloudPullResult.empty;
      }

      final raw = snapshot.value;
      final data = raw != null ? Map<String, dynamic>.from(raw as Map) : null;
      if (data == null) return CloudPullResult.empty;

      final dataJson = data['data'] as String?;
      if (dataJson == null || dataJson.isEmpty) return CloudPullResult.empty;

      // ── Conflict detection: compare timestamps before overwriting local ───
      // If this device has unsynced local changes that started diverging
      // *after* the cloud's last known update, pulling now would silently
      // discard those local edits. Skip the destructive replace so the
      // caller's existing pull-then-fallback-push logic uploads the local
      // (newer) copy instead. A forced restore bypasses this guard.
      final cloudUpdatedAtStr = data['updatedAt'] as String?;
      final cloudUpdatedAt = cloudUpdatedAtStr != null
          ? DateTime.tryParse(cloudUpdatedAtStr)
          : null;
      final dirtySince = await _getDirtySince(uid);
      final knownCloudUpdatedAt = await _getKnownCloudUpdatedAt(uid);
      // A normal (non-forced) pull must not silently clobber local edits.
      // The conflict guard fires when EITHER signal proves local is newer
      // than the cloud snapshot:
      //   • dirtySince: local edits happened after the cloud was last
      //     updated (the intended "unsynced edit" marker), OR
      //   • knownCloudUpdatedAt: the cloud's snapshot isn't strictly newer
      //     than the last copy local already matched, so replacing local
      //     would discard edits that were never uploaded. In that case we
      //     skip the destructive replace and push the (newer) local copy up.
      // A forced restore (explicit "Restore from cloud") bypasses this guard.
      if (!force &&
          cloudUpdatedAt != null &&
          ((knownCloudUpdatedAt != null &&
                  !cloudUpdatedAt.isAfter(
                      knownCloudUpdatedAt.add(_clockSkewTolerance))) ||
              (dirtySince != null &&
                  dirtySince.isAfter(cloudUpdatedAt.add(_clockSkewTolerance))))) {
        debugPrint('[CloudSync] CONFLICT DETECTED on pull: local data is '
            'at least as new as the cloud snapshot (dirtySince=$dirtySince, '
            'knownCloudUpdatedAt=$knownCloudUpdatedAt, cloud=$cloudUpdatedAt). '
            'Skipping pull — local changes will be uploaded instead.');
        return CloudPullResult.conflictSkipped;
      }

      await _sync.replaceUserData(
        localUserId,
        Map<String, dynamic>.from(jsonDecode(dataJson) as Map),
      );

      // Pulling cloud data means local now matches the cloud snapshot, so any
      // previously queued local changes are moot. Clearing the pending/dirty
      // state here is what prevents a device from getting permanently stuck
      // believing its local copy is newer (dirtySince deadlock).
      if (cloudUpdatedAt != null) {
        await _setKnownCloudUpdatedAt(uid, cloudUpdatedAt);
      }
      await _clearPendingSync(uid);

      debugPrint('[CloudSync] Cloud data restored to local DB'
          '${force ? ' (forced restore)' : ''}');
      return CloudPullResult.success;
    } catch (e, s) {
      debugPrint('[CloudSync] SDK GET failed: $e');
      debugPrint('[CloudSync] Stack trace: $s');
      return CloudPullResult.failed;
    }
  }

  /// Upload user data to Firebase Realtime Database via SDK.
  ///
  /// [reason] describes what triggered this upload (for logging).
  /// [forceEvenIfEmpty] bypasses the empty-database guard (only for explicit
  /// user-initiated resets — never pass true from lifecycle or startup code).
  Future<void> uploadLocalUser(
    int localUserId, {
    String reason = 'unspecified',
    bool forceEvenIfEmpty = false,
  }) async {
    final uid = _firebaseUid;
    if (uid == null) {
      throw Exception('Please sign in again before syncing with Firebase.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final caller = StackTrace.current;

    // ── Count every table before exporting ─────────────────────────────────
    final counts = await _sync.countUserRecords(localUserId);

    final totalRecords = counts.values.fold(0, (a, b) => a + b);
    final isEmpty = totalRecords == 0;

    // ── Diagnostic log ─────────────────────────────────────────────────────
    debugPrint('╔══════════════════════════════════════════════════════════');
    debugPrint('║ [CloudSync] uploadLocalUser called');
    debugPrint('║   Timestamp : $now');
    debugPrint('║   Reason    : $reason');
    debugPrint('║   userId    : $localUserId');
    debugPrint('║   uid       : $uid');
    debugPrint(
        '║   Platform  : ${Platform.isAndroid ? "Android" : Platform.isWindows ? "Windows" : "Other"}');
    debugPrint('║   Records:');
    for (final entry in counts.entries) {
      debugPrint('║     ${entry.key.padRight(30)} ${entry.value}');
    }
    debugPrint('║   TOTAL RECORDS : $totalRecords');
    if (isEmpty) {
      debugPrint('║');
      debugPrint('║  ⚠️  WARNING: UPLOADING EMPTY DATABASE  ⚠️');
      debugPrint('║   This would overwrite Firebase with empty data!');
      debugPrint('║   Caller stack trace:');
      for (final line in caller.toString().split('\n').take(12)) {
        debugPrint('║     $line');
      }
    }
    debugPrint('╚══════════════════════════════════════════════════════════');

    // ── Safety guard: never upload an empty DB unless explicitly forced ─────
    if (isEmpty && !forceEvenIfEmpty) {
      debugPrint('[CloudSync] BLOCKED empty upload (reason: $reason). '
          'Firebase data is preserved.');
      return;
    }

    final ref = FirebaseDatabase.instance.ref('users/$uid');

    // ── Conflict detection: compare timestamps before overwriting cloud ─────
    // If the cloud has moved since the last time we observed/wrote it, and
    // this device also has local changes that started diverging BEFORE that
    // cloud write happened, then someone else's newer write would be lost by
    // blindly overwriting it. In that case we skip this upload (the data
    // stays queued/pending) and let the next pull accept the newer cloud
    // copy instead — consistent with this app's "cloud is the source of
    // truth" startup/login flow.
    DateTime? cloudUpdatedAt;
    try {
      final updatedSnap = await ref.child('updatedAt').get();
      final value = updatedSnap.value;
      if (updatedSnap.exists && value is String) {
        cloudUpdatedAt = DateTime.tryParse(value);
      }
    } catch (e) {
      debugPrint('[CloudSync] Could not read cloud updatedAt for conflict '
          'check (reason: $reason): $e');
    }

    final dirtySince = await _getDirtySince(uid);
    if (cloudUpdatedAt != null &&
        dirtySince != null &&
        cloudUpdatedAt.isAfter(dirtySince.add(_clockSkewTolerance))) {
      debugPrint('[CloudSync] CONFLICT DETECTED (reason: $reason): cloud data '
          'was updated at $cloudUpdatedAt, after this device\'s local changes '
          'started diverging at $dirtySince. Skipping upload to avoid '
          'overwriting newer cloud data; the next pull will adopt it.');
      throw Exception(
          'Cloud data changed on another device after your last edit here. '
          'Pull the latest data before syncing again.');
    }

    final data = await _sync.exportUserData(localUserId);
    debugPrint('[CloudSync] SDK SET /users/$uid ($totalRecords total records)');

    try {
      await ref.set({
        'username': _username ?? '',
        'email': _email ?? '',
        'updatedAt': now,
        'data': jsonEncode(data),
      });
      await _setKnownCloudUpdatedAt(uid, DateTime.parse(now));
      await _clearPendingSync(uid);
      debugPrint(
          '[CloudSync] Upload via SDK succeeded ($totalRecords records, reason: $reason)');
    } catch (e, s) {
      debugPrint('[CloudSync] SDK SET failed: $e');
      debugPrint('[CloudSync] Stack trace: $s');
      rethrow;
    }
  }

  void uploadActiveUserInBackground({String reason = 'background'}) {
    final uid = _firebaseUid;
    final userId = _auth.activeUserId;
    if (!isSignedIn || userId == null || uid == null) return;

    // Persist the "dirty" flag immediately so this change survives even if
    // the app is closed before the upload below finishes.
    unawaited(_markPendingSync(uid));

    _uploadFuture = (_uploadFuture ?? Future.value()).then((_) {
      return _uploadWithRetry(userId, reason: reason);
    });
  }

  /// Uploads with a bounded exponential-backoff retry so transient failures
  /// (flaky network, temporary App Check/auth hiccups) are retried a few
  /// times before giving up. If every attempt fails (including permanent
  /// conflicts or being fully offline), the pending/dirty flag is left set
  /// so [retryPendingUploads] — or the periodic retry timer, or the next
  /// local data change — will try again later.
  Future<void> _uploadWithRetry(
    int userId, {
    required String reason,
    int attempt = 0,
  }) async {
    try {
      await uploadLocalUser(userId, reason: reason);
    } catch (e, s) {
      debugPrint(
          '[CloudSync] Upload attempt ${attempt + 1}/$_maxUploadAttempts '
          'failed (reason: $reason): $e');
      if (attempt + 1 >= _maxUploadAttempts) {
        debugPrint('[CloudSync] Giving up after $_maxUploadAttempts attempts '
            '(reason: $reason). Changes remain queued locally and will be '
            'retried automatically (periodic retry, next app start, or next '
            'local change).');
        debugPrint('[CloudSync] Stack trace: $s');
        return;
      }
      final delay = _backoffDelay(attempt);
      debugPrint('[CloudSync] Retrying upload in ${delay.inSeconds}s '
          '(attempt ${attempt + 2}/$_maxUploadAttempts, reason: $reason)');
      await Future.delayed(delay);
      await _uploadWithRetry(userId, reason: reason, attempt: attempt + 1);
    }
  }

  /// Runs a full connectivity diagnostic and prints the results.
  /// Call this after sign-in or on app startup when a user is active.
  Future<void> runDiagnostics() async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('  Firebase Diagnostics (quick)');
    debugPrint('═══════════════════════════════════════════════');
    debugPrint(
        '  Platform: ${Platform.isAndroid ? "Android" : Platform.isWindows ? "Windows" : "Other"}');
    debugPrint(
        '  Firebase Auth currentUser: ${FirebaseAuth.instance.currentUser != null}');
    debugPrint(
        '  Firebase Auth currentUser UID: ${FirebaseAuth.instance.currentUser?.uid ?? "null"}');
    debugPrint('  isSignedIn: $isSignedIn');
    debugPrint('  firebaseUid: $_firebaseUid');
    debugPrint('  email: $_email');
    debugPrint('  username: $_username');

    try {
      final uid = _firebaseUid;
      if (uid != null) {
        final ref = FirebaseDatabase.instance.ref('users/$uid/_diagnostic');
        debugPrint('  RTDB SDK test: SET /users/$uid/_diagnostic');
        await ref.set({
          'timestamp': DateTime.now().toIso8601String(),
          'platform': Platform.isAndroid ? 'Android' : 'Windows',
        });
        debugPrint('  RTDB SDK write test: OK');
      } else {
        debugPrint('  SKIP RTDB test: no firebaseUid');
      }
    } on FirebaseException catch (e) {
      debugPrint('  RTDB SDK write test FAILED (FirebaseException):');
      debugPrint('    code: ${e.code}');
      debugPrint('    message: ${e.message}');
      debugPrint('    plugin: ${e.plugin}');
    } catch (e, s) {
      debugPrint('  RTDB SDK write test FAILED: $e');
      debugPrint('  Stack trace: $s');
    }

    debugPrint('═══════════════════════════════════════════════');

    // Run comprehensive diagnostics
    FirebaseDiagnostics.instance.runAll();
  }

  Future<void> _authenticate({
    required String endpoint,
    required String username,
    required String password,
  }) async {
    final cleaned = _cleanAccount(username);
    final email = _emailForAccount(cleaned);

    try {
      final UserCredential credential;
      if (endpoint == 'accounts:signUp') {
        credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      final user = credential.user;
      if (user == null) {
        throw Exception('Firebase did not return a user profile.');
      }

      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Firebase did not return an ID token.');
      }

      _idToken = idToken;
      _refreshToken = '';
      _firebaseUid = user.uid;
      _username = _usernameForAccount(cleaned);
      _email = user.email ?? email;
      _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 55));
      debugPrint('[CloudSync] Firebase Auth succeeded for $_username');
      unawaited(_hydratePendingStateAndStartRetryTimer());
    } on FirebaseAuthException catch (error) {
      debugPrint('[CloudSync] Firebase Auth failed: ${error.code}');
      throw Exception(_firebaseAuthErrorMessage(error));
    }
  }

  Future<String> _validIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final forceRefresh =
          _tokenExpiresAt == null || !DateTime.now().isBefore(_tokenExpiresAt!);
      final token = await user.getIdToken(forceRefresh);
      if (token == null || token.isEmpty) {
        throw Exception('Please sign in again before syncing with Firebase.');
      }
      _idToken = token;
      _firebaseUid = user.uid;
      _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 55));
      return token;
    }

    final token = _idToken;
    final refreshToken = _refreshToken;
    if (token == null || refreshToken == null) {
      throw Exception('Please sign in again before syncing with Firebase.');
    }

    if (_tokenExpiresAt == null || DateTime.now().isBefore(_tokenExpiresAt!)) {
      return token;
    }

    final response = await http.post(
      Uri.https(
        'securetoken.googleapis.com',
        '/v1/token',
        {'key': FirebaseConfig.currentApiKey},
      ),
      headers: await _formHeaders(),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_firebaseMessage(response.body, response.statusCode));
    }

    _idToken = body['id_token'] as String?;
    _refreshToken = body['refresh_token'] as String?;
    _firebaseUid = body['user_id'] as String?;
    final expiresIn =
        int.tryParse(body['expires_in']?.toString() ?? '') ?? 3600;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn - 60));
    if (_idToken == null) {
      throw Exception('Token refresh response did not contain an ID token.');
    }
    return _idToken!;
  }

  Future<Map<String, String>> _jsonHeaders({String? authToken}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  Future<Map<String, String>> _formHeaders() async {
    return <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    };
  }

  String _cleanAccount(String account) => account.trim().toLowerCase();

  String _usernameForAccount(String account) {
    if (!account.contains('@')) return account;
    return account.split('@').first.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
  }

  String? _usernameFromEmail(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.contains('@')) {
      return _usernameForAccount(value);
    }
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').toLowerCase();
  }

  String _emailForAccount(String account) {
    if (account.contains('@')) return account;
    final safe = account.replaceAll(RegExp(r'[^a-z0-9._-]'), '_');
    return '$safe@worklist-armoon.local';
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That Worklist account or email already exists.';
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'user-not-found':
      case 'wrong-password':
        return 'The username or password is not correct.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'operation-not-allowed':
        return 'Firebase Email/Password sign-in is not enabled yet.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'internal-error':
        return 'Internal error: Firebase could not verify this device yet. '
            'You can still use your saved local account on this device.';
      default:
        final message = error.message ?? '';
        if (message.toLowerCase().contains('app check')) {
          return 'Firebase App Check rejected this app. Register the debug token '
              'shown in the app logs under Firebase Console → App Check → '
              'Manage debug tokens, then retry.';
        }
        return message.isEmpty ? 'Firebase sign-in failed.' : message;
    }
  }

  String _authMessage(Map<String, dynamic> body) {
    final code = body['error']?['message']?.toString() ?? '';
    switch (code) {
      case 'EMAIL_EXISTS':
        return 'That Worklist account or email already exists.';
      case 'INVALID_LOGIN_CREDENTIALS':
      case 'EMAIL_NOT_FOUND':
      case 'INVALID_PASSWORD':
        return 'The username or password is not correct.';
      case 'INVALID_EMAIL':
        return 'Enter a valid email address.';
      case 'OPERATION_NOT_ALLOWED':
        return 'Firebase Email/Password sign-in is not enabled yet.';
      case 'WEAK_PASSWORD : Password should be at least 6 characters':
        return 'Password should be at least 6 characters.';
      default:
        return code.isEmpty ? 'Firebase sign-in failed.' : code;
    }
  }

  /// Parses error responses from both Firebase Auth REST API
  /// (`{"error": {"message": "..."}}`) and Realtime Database REST API
  /// (`{"error": "string"}` or `{"error": "Permission denied"}`).
  String _firebaseMessage(String responseBody, [int? statusCode]) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[CloudSync] Non-map response body: $responseBody');
        return responseBody.isNotEmpty
            ? responseBody
            : 'Firebase request failed.';
      }

      // RTDB format: {"error": "Permission denied"}
      final errorValue = decoded['error'];
      if (errorValue is String) {
        debugPrint('[CloudSync] RTDB error ($statusCode): $errorValue');
        if (errorValue.toLowerCase().contains('app check')) {
          return 'Firebase App Check rejected this app. Register the debug token shown in the app logs, then retry.';
        }
        if (errorValue.contains('Permission denied')) {
          return 'Firebase Realtime Database access denied. Check security rules.';
        }
        if (errorValue.toLowerCase().contains('token')) {
          return 'Firebase auth token is invalid or expired. Please sign in again.';
        }
        return errorValue;
      }

      // Auth REST API format: {"error": {"message": "..."}}
      if (errorValue is Map<String, dynamic>) {
        final message = errorValue['message']?.toString() ?? '';
        if (message.toLowerCase().contains('app check')) {
          return 'Firebase App Check rejected this app. Register the debug token shown in the app logs, then retry.';
        }
        if (message.isNotEmpty) {
          debugPrint('[CloudSync] Auth error ($statusCode): $message');
          return message;
        }
      }

      debugPrint(
          '[CloudSync] Unknown error format. Status: $statusCode, Body: $responseBody');
      return 'Firebase request failed.';
    } catch (e) {
      debugPrint('[CloudSync] Failed to parse error response: $e');
      debugPrint('[CloudSync] Raw response body: $responseBody');
      return responseBody.isNotEmpty
          ? responseBody
          : 'Firebase request failed.';
    }
  }
}
