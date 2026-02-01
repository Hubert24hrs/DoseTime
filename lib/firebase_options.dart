// Firebase configuration for DoseTime
// This file should be regenerated using FlutterFire CLI for production:
// flutterfire configure
//
// Temporary placeholder configuration for development.
// Replace with actual Firebase project configuration.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'run flutterfire configure to generate.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace with your Firebase project configuration
  // To generate these values, run:
  // 1. Install FlutterFire CLI: dart pub global activate flutterfire_cli
  // 2. Configure: flutterfire configure
  //

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAl-MxTQGKmv9aNT00pwq8as6tevtw-l5E',
    appId: '1:220414378908:android:92397664c595ea5583fe59',
    messagingSenderId: '220414378908',
    projectId: 'fast-delivery-d8d5c',
    storageBucket: 'fast-delivery-d8d5c.firebasestorage.app',
  );

  // For now, using placeholder values that will need to be replaced

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB4D2wHc1zjLzsOXfmLGjWf927el2aajAs',
    appId: '1:220414378908:ios:a06b2bfb94849e8083fe59',
    messagingSenderId: '220414378908',
    projectId: 'fast-delivery-d8d5c',
    storageBucket: 'fast-delivery-d8d5c.firebasestorage.app',
    androidClientId: '220414378908-hd7uj2jjt6ukmqcqckds8radsle7c2cn.apps.googleusercontent.com',
    iosClientId: '220414378908-992uqd08rgfeb9b5juid26dogpdlj4ch.apps.googleusercontent.com',
    iosBundleId: 'com.example.doseTime',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBcXNVEQ7ikDGGpR5QrDMeW71K5RxorS5U',
    appId: '1:220414378908:web:9b3c12f6234d343783fe59',
    messagingSenderId: '220414378908',
    projectId: 'fast-delivery-d8d5c',
    authDomain: 'fast-delivery-d8d5c.firebaseapp.com',
    storageBucket: 'fast-delivery-d8d5c.firebasestorage.app',
    measurementId: 'G-W3T3WW8W61',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB4D2wHc1zjLzsOXfmLGjWf927el2aajAs',
    appId: '1:220414378908:ios:a06b2bfb94849e8083fe59',
    messagingSenderId: '220414378908',
    projectId: 'fast-delivery-d8d5c',
    storageBucket: 'fast-delivery-d8d5c.firebasestorage.app',
    androidClientId: '220414378908-hd7uj2jjt6ukmqcqckds8radsle7c2cn.apps.googleusercontent.com',
    iosClientId: '220414378908-992uqd08rgfeb9b5juid26dogpdlj4ch.apps.googleusercontent.com',
    iosBundleId: 'com.example.doseTime',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBcXNVEQ7ikDGGpR5QrDMeW71K5RxorS5U',
    appId: '1:220414378908:web:d053638278d20c9883fe59',
    messagingSenderId: '220414378908',
    projectId: 'fast-delivery-d8d5c',
    authDomain: 'fast-delivery-d8d5c.firebaseapp.com',
    storageBucket: 'fast-delivery-d8d5c.firebasestorage.app',
    measurementId: 'G-XJPCWE9VF8',
  );

}