import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../firebase/firebase_auth_listener.dart';
import '../firebase/firebase_cloud_service.dart';
import '../firebase/firebase_config.dart';
import '../firebase/google_oauth_service.dart';
import '../firebase/session_storage.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider();

  final _db = DatabaseHelper();
  final _cloud = FirebaseCloudService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _initialized = false;
  bool _handlingLocalSignOut = false;
  String? _error;
  String? _cloudNotice;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String? get error => _error;
  String? get cloudNotice => _cloudNotice;
  String? get cloudEmail => _cloud.email;
  bool get cloudSignedIn => _cloud.isSignedIn;
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

  Future<void> initialize() async {
    await FirebaseConfig.ensureLoaded();
    _startFirebaseAuthListeners();

    final savedUsername = await SessionStorage.loadActiveUsername();

    // Restore local account first so the device stays signed in after restart.
    if (savedUsername != null) {
      final user = await _db.getUserByUsername(savedUsername);
      if (user != null) {
        _currentUser = user;
        _db.setActiveUser(user);
      } else {
        await SessionStorage.clearActiveUsername();
      }
    }

    // Silently refresh Firebase cloud session when available.
    final restoredCloud = await _cloud.restorePersistedSession();
    if (restoredCloud && _currentUser != null) {
      try {
        await _cloud.pullIntoLocalUser(_currentUser!.id!);
      } catch (_) {
        _cloudNotice =
            'Signed in on this device. Cloud sync will retry when Firebase is available.';
      }
    } else if (restoredCloud) {
      await _restoreLocalUserFromCloud(savedUsername);
    }

    _initialized = true;
    notifyListeners();
  }

  void _startFirebaseAuthListeners() {
    FirebaseAuthListener.instance.start(
      onAuthStateChanged: _onFirebaseAuthStateChanged,
      onIdTokenChanged: _onFirebaseIdTokenChanged,
    );
  }

  Future<void> _onFirebaseAuthStateChanged(User? user) async {
    if (!_initialized) return;

    if (user == null) {
      if (_handlingLocalSignOut) return;
      // Keep the local device session; only explicit logout clears it.
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

    final existing = await _db.getUserByUsername(username);
    final user = existing ?? await _db.ensureGoogleLocalAccount(username);
    _currentUser = user;
    _db.setActiveUser(user);
    await SessionStorage.saveActiveUsername(user.username);

    try {
      await _cloud.pullIntoLocalUser(user.id!);
    } catch (_) {
      _cloudNotice =
          'Restored your Firebase session. Cloud sync will retry when App Check allows this app.';
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    final cleanedUsername = username.trim().toLowerCase();
    final localUser = await _db.authenticate(cleanedUsername, password);

    try {
      await _cloud.signIn(cleanedUsername, password);
      final user = await _db.ensureLocalAccount(cleanedUsername, password);
      _currentUser = user;
      _db.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);

      try {
        final pulled = await _cloud.pullIntoLocalUser(user.id!);
        if (!pulled) {
          await _cloud.uploadLocalUser(user.id!);
        }
      } catch (_) {
        _cloudNotice =
            'Signed in on this device. Cloud sync will retry when Firebase is available.';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (localUser != null || _cloud.isRecoverableCloudBlock(e)) {
        final user = localUser ??
            await _db.ensureLocalAccount(cleanedUsername, password);
        _cloud.clearSession();
        _currentUser = user;
        _db.setActiveUser(user);
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

  Future<bool> register(String username, String password) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    try {
      final cleanedUsername = username.trim().toLowerCase();
      await _cloud.register(cleanedUsername, password);
      final user = await _db.ensureLocalAccount(cleanedUsername, password);
      _currentUser = user;
      _db.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);
      try {
        await _cloud.uploadLocalUser(user.id!);
      } catch (_) {
        _cloudNotice =
            'Account created on this device. Cloud sync will retry when Firebase is available.';
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_cloud.isRecoverableCloudBlock(e)) {
        final cleanedUsername = username.trim().toLowerCase();
        final user = await _db.ensureLocalAccount(cleanedUsername, password);
        _currentUser = user;
        _db.setActiveUser(user);
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

  Future<bool> linkEmail(String email) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    try {
      await _cloud.linkEmail(email);
      final userId = _currentUser?.id;
      if (userId != null) {
        await _cloud.uploadLocalUser(userId);
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

  Future<void> syncNow() async {
    final userId = _currentUser?.id;
    if (userId == null || !_cloud.isSignedIn) return;
    await _cloud.uploadLocalUser(userId);
  }

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
      // Linking case: user is already signed into Firebase Auth (email/password).
      // Link the Google credential to the existing Firebase user.
      try {
        final session =
            await GoogleOAuthService.instance.linkToCurrentFirebaseUser();
        _cloud.applySession(session);

        try {
          if (_currentUser?.id != null) {
            await _cloud.uploadLocalUser(_currentUser!.id!);
          }
        } catch (_) {
          _cloudNotice =
              'Google linked. Cloud sync will retry when App Check allows this app.';
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } catch (e) {
        // Linking failed — show error but keep the user logged in locally.
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    if (_currentUser != null) {
      // User has a local device account but no Firebase Auth session (e.g. App
      // Check blocked the original sign-in). Google linking requires a Firebase
      // Auth account.  Don't create a new Google-based account that would
      // replace the current user — explain what's needed instead.
      _error =
          'Sign in with your username and password first to connect to Firebase, '
          'then tap "Sign in with Google" to link your Google account.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Fresh sign-in from the login screen — use existing flow.
    try {
      final session = await GoogleOAuthService.instance.signIn();
      _cloud.applySession(session);

      final fallback = session.firebaseUid == null;

      final username = _cloud.username ?? 'google_user';
      final user = await _db.ensureGoogleLocalAccount(username);
      _currentUser = user;
      _db.setActiveUser(user);
      await SessionStorage.saveActiveUsername(user.username);

      if (!fallback) {
        try {
          final pulled = await _cloud.pullIntoLocalUser(user.id!);
          if (!pulled) {
            await _cloud.uploadLocalUser(user.id!);
          }
        } catch (_) {
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

  Future<void> logout() async {
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
      _db.setActiveUser(null);
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
