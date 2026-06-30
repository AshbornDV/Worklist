import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../firebase/firebase_cloud_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final _db = DatabaseHelper();
  final _cloud = FirebaseCloudService.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  String? _cloudNotice;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get cloudNotice => _cloudNotice;
  String? get cloudEmail => _cloud.email;
  bool get cloudSignedIn => _cloud.isSignedIn;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    _cloudNotice = null;
    notifyListeners();

    final cleanedUsername = username.trim().toLowerCase();
    try {
      await _cloud.signIn(cleanedUsername, password);
      final user = await _db.ensureLocalAccount(cleanedUsername, password);
      _currentUser = user;
      _db.setActiveUser(user);

      try {
        final pulled = await _cloud.pullIntoLocalUser(user.id!);
        if (!pulled) {
          await _cloud.uploadLocalUser(user.id!);
        }
      } catch (_) {
        _cloudNotice =
            'Signed in locally. Firebase cloud sync will retry when App Check allows this app.';
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_cloud.isRecoverableCloudBlock(e)) {
        final localUser = await _db.authenticate(cleanedUsername, password);
        if (localUser != null) {
          _cloud.signOut();
          _currentUser = localUser;
          _db.setActiveUser(localUser);
          _cloudNotice =
              'Opened saved local data. Firebase cloud sync is paused because Firebase App Check rejected this app.';
          _isLoading = false;
          notifyListeners();
          return true;
        }
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
      await _cloud.uploadLocalUser(user.id!);
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

  void logout() {
    _currentUser = null;
    _cloud.signOut();
    _db.setActiveUser(null);
    _error = null;
    _cloudNotice = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _cloudNotice = null;
    notifyListeners();
  }
}
