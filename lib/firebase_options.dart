// This file is the central configuration hub that allows this Flutter application to communicate with the Firebase backend services.
// It contains the secret API keys, project IDs, and specific application identifiers needed to securely connect your app to its respective Firebase project.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

// This class acts as a customized dictionary that hands out the correct set of Firebase keys depending on which device the application is currently running on.
class DefaultFirebaseOptions {
  
  // This function checks the operating system of the device running the app.
  // It then returns the exact FirebaseOptions configuration required for that specific platform.
  // If the app is compiled for a platform that has not been set up yet, like Linux, it will throw an error to let the developer know.
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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // These are the specific connection details required when the app is running in a web browser.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA4QuhKcnFd4932ONUjoPA3fH8C8dv3f0s',
    appId: '1:995707878804:web:7016d1e0c4a756f63c2381',
    messagingSenderId: '995707878804',
    projectId: 'map-project-df6fd',
    authDomain: 'map-project-df6fd.firebaseapp.com',
    storageBucket: 'map-project-df6fd.firebasestorage.app',
  );

  // These are the specific connection details required when the app is installed and running on an Android device.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4RAxdB7UREYpGHfHoE--rEXGtf3WTmYE',
    appId: '1:995707878804:android:e0b0e9c28bbe57ff3c2381',
    messagingSenderId: '995707878804',
    projectId: 'map-project-df6fd',
    storageBucket: 'map-project-df6fd.firebasestorage.app',
  );

  // These are the specific connection details required when the app is installed and running on an Apple iOS device like an iPhone or iPad.
  // It includes an extra bundle ID to verify the app identity with Apple systems.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAveSBOGODxZdh9MjhM5psAnNFE6Nbl3KI',
    appId: '1:995707878804:ios:90ffef521ab8ddfa3c2381',
    messagingSenderId: '995707878804',
    projectId: 'map-project-df6fd',
    storageBucket: 'map-project-df6fd.firebasestorage.app',
    iosBundleId: 'com.example.mapProject',
  );

  // These are the specific connection details required when the app is running as a desktop application on an Apple Mac computer.
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAveSBOGODxZdh9MjhM5psAnNFE6Nbl3KI',
    appId: '1:995707878804:ios:90ffef521ab8ddfa3c2381',
    messagingSenderId: '995707878804',
    projectId: 'map-project-df6fd',
    storageBucket: 'map-project-df6fd.firebasestorage.app',
    iosBundleId: 'com.example.mapProject',
  );

  // These are the specific connection details required when the app is running as a desktop application on a Windows computer.
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4QuhKcnFd4932ONUjoPA3fH8C8dv3f0s',
    appId: '1:995707878804:web:bd37617c79e821863c2381',
    messagingSenderId: '995707878804',
    projectId: 'map-project-df6fd',
    authDomain: 'map-project-df6fd.firebaseapp.com',
    storageBucket: 'map-project-df6fd.firebasestorage.app',
  );
}