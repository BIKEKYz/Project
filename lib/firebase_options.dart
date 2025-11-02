import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
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

  // (ใช้เมื่อรันบนเว็บเท่านั้น; ค่านี้ยังไม่ critical ถ้ายังไม่ได้สร้าง Web app)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC24KotwT-r4dzJzucZJQqkKvrLXu3CUqs',
    authDomain: 'condoplantadvisor.firebaseapp.com',
    projectId: 'condoplantadvisor',
    storageBucket: 'condoplantadvisor.appspot.com',
    messagingSenderId: '548611691877',
    appId: 'YOUR_WEB_APP_ID',
  );

  // Android — อิงจาก android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC24KotwT-r4dzJzucZJQqkKvrLXu3CUqs', // current_key
    appId: '1:548611691877:android:f7bb169d9cac079e207d8c', // mobilesdk_app_id
    messagingSenderId: '548611691877', // project_number
    projectId: 'condoplantadvisor', // project_id
    storageBucket: 'condoplantadvisor.firebasestorage.app', // storage_bucket
  );
}
