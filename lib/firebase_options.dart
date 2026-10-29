// Firebase configuration for DoseAlert (project: dosealert-42199).
// Matches android/app/google-services.json and ios/Runner/GoogleService-Info.plist.
// Regenerate with `flutterfire configure --project=dosealert-42199` if apps change.
//
// These are public client identifiers, not secrets; access is controlled by
// Firebase Auth settings and security rules.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'run flutterfire configure to add a web app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD5z09JhgyOdWz12lcK7N8k4VtQMnDE29M',
    appId: '1:957206156322:android:961034a119823617ede67b',
    messagingSenderId: '957206156322',
    projectId: 'dosealert-42199',
    storageBucket: 'dosealert-42199.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1stWDihvZcQYCpguyHrQTrp27gdoB1Zw',
    appId: '1:957206156322:ios:243b6d78c824cff5ede67b',
    messagingSenderId: '957206156322',
    projectId: 'dosealert-42199',
    storageBucket: 'dosealert-42199.firebasestorage.app',
    androidClientId: '957206156322-bj5u76o8kftf7em4g3v1p9kfenp1qk4a.apps.googleusercontent.com',
    iosClientId: '957206156322-6hr652asmb6edecpr0ceumi39vddsgua.apps.googleusercontent.com',
    iosBundleId: 'dev.hubert.dosetime',
  );

  // macOS shares the iOS app registration (same bundle id).
  static const FirebaseOptions macos = ios;
}
