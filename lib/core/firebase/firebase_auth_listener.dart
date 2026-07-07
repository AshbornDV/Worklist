import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

typedef FirebaseAuthUserHandler = Future<void> Function(User? user);

/// Subscribes to Firebase Auth state streams per the official Flutter guide.
class FirebaseAuthListener {
  FirebaseAuthListener._();
  static final FirebaseAuthListener instance = FirebaseAuthListener._();

  StreamSubscription<User?>? _authStateSubscription;
  StreamSubscription<User?>? _idTokenSubscription;

  void start({
    required FirebaseAuthUserHandler onAuthStateChanged,
    required FirebaseAuthUserHandler onIdTokenChanged,
  }) {
    stop();

    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((user) async {
      try {
        await onAuthStateChanged(user);
      } catch (error, stackTrace) {
        debugPrint('Firebase authStateChanges handler failed: $error');
        debugPrint('$stackTrace');
      }
    });

    _idTokenSubscription =
        FirebaseAuth.instance.idTokenChanges().listen((user) async {
      try {
        await onIdTokenChanged(user);
      } catch (error, stackTrace) {
        debugPrint('Firebase idTokenChanges handler failed: $error');
        debugPrint('$stackTrace');
      }
    });
  }

  void stop() {
    _authStateSubscription?.cancel();
    _idTokenSubscription?.cancel();
    _authStateSubscription = null;
    _idTokenSubscription = null;
  }
}
