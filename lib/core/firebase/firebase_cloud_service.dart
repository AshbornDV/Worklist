import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../database/database_helper.dart';
import 'app_check_service.dart';
import 'firebase_config.dart';
import 'google_oauth_service.dart';
import 'session_storage.dart';

class FirebaseCloudService {
  FirebaseCloudService._();
  static final FirebaseCloudService instance = FirebaseCloudService._();

  final _db = DatabaseHelper();

  String? _idToken;
  String? _refreshToken;
  String? _firebaseUid;
  String? _username;
  String? _email;
  DateTime? _tokenExpiresAt;
  Future<void>? _uploadFuture;

  bool get isSignedIn => _idToken != null && _firebaseUid != null;
  String? get username => _username;
  String? get email => _email;

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

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final idToken = await firebaseUser.getIdToken();
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
      } catch (_) {
        return false;
      }
    }

    final silentSession =
        await GoogleOAuthService.instance.tryRestoreSilentSignIn();
    if (silentSession == null) return false;
    applySession(silentSession);
    return true;
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

  Future<bool> pullIntoLocalUser(int localUserId) async {
    final token = await _validIdToken();
    final uid = _requireUid();
    final response = await http.get(
      _firestoreDocumentUri(uid),
      headers: await _jsonHeaders(authToken: token),
    );

    if (response.statusCode == 404) return false;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_firebaseMessage(response.body));
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = body['fields'] as Map<String, dynamic>? ?? {};
    final dataJson = fields['data']?['stringValue'] as String?;
    if (dataJson == null || dataJson.isEmpty) return false;

    await _db.replaceUserData(
      localUserId,
      Map<String, dynamic>.from(jsonDecode(dataJson) as Map),
    );
    return true;
  }

  Future<void> uploadLocalUser(int localUserId) async {
    final token = await _validIdToken();
    final uid = _requireUid();
    final data = await _db.exportUserData(localUserId);
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await http.patch(
      _firestoreDocumentUri(uid),
      headers: await _jsonHeaders(authToken: token),
      body: jsonEncode({
        'fields': {
          'username': {'stringValue': _username ?? ''},
          'email': {'stringValue': _email ?? ''},
          'updatedAt': {'timestampValue': now},
          'data': {'stringValue': jsonEncode(data)},
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_firebaseMessage(response.body));
    }
  }

  void uploadActiveUserInBackground() {
    final userId = _db.activeUserId;
    if (!isSignedIn || userId == null) return;
    _uploadFuture = (_uploadFuture ?? Future.value()).then((_) {
      return uploadLocalUser(userId);
    }).catchError((_) {
      // Cloud sync should never interrupt normal local data entry.
    });
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
    } on FirebaseAuthException catch (error) {
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
      throw Exception(_firebaseMessage(response.body));
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
    final appCheckToken = await AppCheckService.instance.getToken();
    if (appCheckToken != null && appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }
    return headers;
  }

  Future<Map<String, String>> _formHeaders() async {
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final appCheckToken = await AppCheckService.instance.getToken();
    if (appCheckToken != null && appCheckToken.isNotEmpty) {
      headers['X-Firebase-AppCheck'] = appCheckToken;
    }
    return headers;
  }

  String _requireUid() {
    final uid = _firebaseUid;
    if (uid == null) {
      throw Exception('Please sign in again before syncing with Firebase.');
    }
    return uid;
  }

  Uri _firestoreDocumentUri(String uid) => Uri.https(
        'firestore.googleapis.com',
        '/v1/projects/${FirebaseConfig.projectId}/databases/(default)/documents/worklistUsers/$uid',
      );

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

  String _firebaseMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      final message = decoded['error']?['message']?.toString() ?? '';
      if (message.toLowerCase().contains('app check')) {
        return 'Firebase App Check rejected this app. Register the debug token shown in the app logs, then retry.';
      }
      return message.isEmpty ? 'Firebase request failed.' : message;
    } catch (_) {
      return 'Firebase request failed.';
    }
  }
}
