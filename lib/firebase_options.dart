import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for Worklist (project: worklist-armoon).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyATBlLwSqsb7OAKhF1e1vkbNYddfZVZC1c',
    appId: '1:867700541514:android:7762f61d5690ffcb2afeb3',
    messagingSenderId: '867700541514',
    projectId: 'worklist-armoon',
    databaseURL: 'https://worklist-armoon-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'worklist-armoon.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC3hv95t2qwpwc4gPPK6aY0B6gAjchcL4g',
    appId: '1:867700541514:web:f75f3c3ce0b7d1c52afeb3',
    messagingSenderId: '867700541514',
    projectId: 'worklist-armoon',
    authDomain: 'worklist-armoon.firebaseapp.com',
    databaseURL: 'https://worklist-armoon-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'worklist-armoon.firebasestorage.app',
    measurementId: 'G-0QS1YEYJNZ',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyATBlLwSqsb7OAKhF1e1vkbNYddfZVZC1c',
    appId: '1:867700541514:android:7762f61d5690ffcb2afeb3',
    messagingSenderId: '867700541514',
    projectId: 'worklist-armoon',
    storageBucket: 'worklist-armoon.firebasestorage.app',
  );
}
