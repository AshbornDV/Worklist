import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_config.dart';

class FirebaseAuthSession {
  final String idToken;
  final String refreshToken;
  final String? firebaseUid;
  final String? email;
  final String? displayName;

  /// When true, [FirebaseCloudService] refreshes tokens via [FirebaseAuth].
  final bool managedByFirebaseAuth;

  const FirebaseAuthSession({
    required this.idToken,
    this.refreshToken = '',
    this.firebaseUid,
    this.email,
    this.displayName,
    this.managedByFirebaseAuth = false,
  });
}

  /// Platform-aware Google sign-in that uses the native SDK on Android and desktop.
class GoogleOAuthService {
  GoogleOAuthService._();
  static final GoogleOAuthService instance = GoogleOAuthService._();

  GoogleSignIn? _googleSignIn;

  Future<FirebaseAuthSession> signIn() async {
    await FirebaseConfig.ensureLoaded();
    _ensureSupported();
    _ensureConfigured();
    return _signInWithGoogleSdk();
  }

  /// Signs in with Google, then links the Google credential to the current
  /// Firebase Auth user (the one obtained via email/password).  Throws if no
  /// Firebase user is currently signed in.
  Future<FirebaseAuthSession> linkToCurrentFirebaseUser() async {
    await FirebaseConfig.ensureLoaded();
    _ensureSupported();
    _ensureConfigured();

    final googleSignIn = _googleSignInInstance();
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(_missingIdTokenMessage());
    }

    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception(
          'No Firebase account to link to. Sign in with your email/password first.',
        );
      }

      await user.linkWithCredential(credential);

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase did not return an ID token after linking.');
      }

      return FirebaseAuthSession(
        idToken: firebaseIdToken,
        refreshToken: '',
        firebaseUid: user.uid,
        email: user.email,
        displayName: user.displayName,
        managedByFirebaseAuth: true,
      );
    } on FirebaseAuthException catch (e) {
      final message = e.message ?? '';
      if (e.code == 'credential-already-in-use') {
        throw Exception(
          'This Google account is already linked to a different Worklist '
          'account. Sign out first, then sign in with Google.',
        );
      }
      if (e.code == 'web-context-cancelled') {
        throw Exception('Google sign-in was cancelled.');
      }
      if (message.toLowerCase().contains('app check')) {
        throw Exception(
          'Firebase App Check rejected this app. Register the debug token '
          'shown in the app logs under Firebase Console → App Check → '
          'Manage debug tokens, then retry.',
        );
      }
      rethrow;
    }
  }

  Future<FirebaseAuthSession?> tryRestoreSilentSignIn() async {
    await FirebaseConfig.ensureLoaded();
    if (!_usesGoogleSdk()) return null;
    if (!FirebaseConfig.isGoogleSignInConfigured) return null;

    final googleSignIn = _googleSignInInstance();
    final account = await googleSignIn.signInSilently();
    if (account == null) return null;

    return _sessionFromGoogleAccount(account);
  }

  Future<void> signOut() async {
    if (_googleSignIn != null) {
      await _googleSignIn!.signOut();
    }
  }

  bool _usesGoogleSdk() {
    return FirebaseConfig.googleSignInPlatform ==
            GoogleSignInPlatform.android ||
        FirebaseConfig.googleSignInPlatform == GoogleSignInPlatform.desktop;
  }

  void _ensureSupported() {
    if (FirebaseConfig.googleSignInPlatform ==
        GoogleSignInPlatform.unsupported) {
      throw Exception(FirebaseConfig.googleSignInUnavailableMessage());
    }
  }

  void _ensureConfigured() {
    if (!FirebaseConfig.isGoogleSignInConfigured) {
      throw Exception(FirebaseConfig.googleSignInUnavailableMessage());
    }
  }

  GoogleSignIn _googleSignInInstance() {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email', 'profile'],
      serverClientId: FirebaseConfig.isAndroid &&
              FirebaseConfig.resolvedWebClientId.isNotEmpty
          ? FirebaseConfig.resolvedWebClientId
          : null,
      clientId: FirebaseConfig.isDesktop &&
              FirebaseConfig.resolvedDesktopClientId.isNotEmpty
          ? FirebaseConfig.resolvedDesktopClientId
          : null,
    );
  }

  Future<FirebaseAuthSession> _signInWithGoogleSdk() async {
    final googleSignIn = _googleSignInInstance();
    final account = await googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google sign-in was cancelled.');
    }
    return _sessionFromGoogleAccount(account);
  }

  Future<FirebaseAuthSession> _sessionFromGoogleAccount(
    GoogleSignInAccount account,
  ) async {
    final googleAuth = await account.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(_missingIdTokenMessage());
    }

    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase did not return a user profile.');
      }

      final firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception('Firebase did not return an ID token.');
      }

      return FirebaseAuthSession(
        idToken: firebaseIdToken,
        refreshToken: '',
        firebaseUid: user.uid,
        email: user.email,
        displayName: user.displayName,
        managedByFirebaseAuth: true,
      );
    } on FirebaseAuthException {
      // If Firebase Auth is blocked (App Check etc.), still allow local
      // Google sign-in with the raw Google ID token.
      return FirebaseAuthSession(
        idToken: idToken,
        email: account.email,
        displayName: account.displayName,
        managedByFirebaseAuth: false,
      );
    }
  }

  String _missingIdTokenMessage() {
    if (FirebaseConfig.isAndroid) {
      return 'Google did not return an ID token. Confirm the Google provider is '
          'enabled in Firebase Authentication, add your SHA-1 and SHA-256 '
          'fingerprints, download a new google-services.json that includes a '
          'Web OAuth client, copy it to assets/google-services.json, then rebuild.';
    }
    if (FirebaseConfig.isDesktop) {
      return 'Google did not return an ID token. Verify the Desktop OAuth client '
          'ID in Google Cloud Console (create an OAuth client of type Desktop app) '
          'and confirm Google sign-in is enabled in Firebase.';
    }
    return FirebaseConfig.googleSignInUnavailableMessage();
  }

}
