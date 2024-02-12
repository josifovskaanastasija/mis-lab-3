import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Application is not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBsLZ-G5_yISIO8Q95GJpIiYBoKMXG-8Mo',
    appId: '1:442966443733:android:05af55e6e43a77aecb845c',
    messagingSenderId: '442966443733',
    projectId: 'mis-labs-80924',
    storageBucket: 'mis-labs-80924.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBfpa3jytNJpRGJQASBGfxNgTWXAYwRTeE',
    appId: '1:442966443733:ios:e470018a8b1dd1cdcb845c',
    messagingSenderId: '442966443733',
    projectId: 'mis-labs-80924',
    storageBucket: 'mis-labs-80924.appspot.com',
    iosBundleId: 'com.example.lab3',
  );
}