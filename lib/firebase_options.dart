// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAwH8IMUiRuV2c38-_OWOzG3CLNMQxQiQs',
    appId: '1:389015407422:web:c44a3019052614a6a1fa6f',
    messagingSenderId: '389015407422',
    projectId: 'distributionapp-476c6',
    authDomain: 'distributionapp-476c6.firebaseapp.com',
    storageBucket: 'distributionapp-476c6.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtMBDlfl45wXF597MtulUZ4mVRvehQ3Oo',
    appId: '1:389015407422:android:834dd3101c0eb74da1fa6f',
    messagingSenderId: '389015407422',
    projectId: 'distributionapp-476c6',
    storageBucket: 'distributionapp-476c6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAGH2_iwfvHaphcKhDFN-dOj5ddmjBu1cQ',
    appId: '1:389015407422:ios:383ad120b684a6e4a1fa6f',
    messagingSenderId: '389015407422',
    projectId: 'distributionapp-476c6',
    storageBucket: 'distributionapp-476c6.firebasestorage.app',
    iosBundleId: 'com.example.distributionManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAGH2_iwfvHaphcKhDFN-dOj5ddmjBu1cQ',
    appId: '1:389015407422:ios:383ad120b684a6e4a1fa6f',
    messagingSenderId: '389015407422',
    projectId: 'distributionapp-476c6',
    storageBucket: 'distributionapp-476c6.firebasestorage.app',
    iosBundleId: 'com.example.distributionManagement',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAwH8IMUiRuV2c38-_OWOzG3CLNMQxQiQs',
    appId: '1:389015407422:web:02ef1afc5c019a9ea1fa6f',
    messagingSenderId: '389015407422',
    projectId: 'distributionapp-476c6',
    authDomain: 'distributionapp-476c6.firebaseapp.com',
    storageBucket: 'distributionapp-476c6.firebasestorage.app',
  );

}