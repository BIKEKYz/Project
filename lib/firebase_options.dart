import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

abstract class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC24KotwT-r4dzJzucZJQqkKvrLXu3CUqs',
    authDomain: 'condoplantadvisor.firebaseapp.com',
    projectId: 'condoplantadvisor',
    storageBucket: 'condoplantadvisor.appspot.com',
    messagingSenderId: '548611691877',
    appId: 'YOUR_WEB_APP_ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC24KotwT-r4dzJzucZJQqkKvrLXu3CUqs',
    appId: '1:548611691877:android:f7bb169d9cac079e207d8c',
    messagingSenderId: '548611691877',
    projectId: 'condoplantadvisor',
    storageBucket: 'condoplantadvisor.firebasestorage.app',
  );
}
