import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const String pulseWiseWebVapidKey =
    'BODaBbSum9KijsDi0JFsExQTgRf8jlVXzsIBXxGMplJCE4Xx2Z89p69BrZtXUAlZLKFbWPWwVn0M0rfaHOOKEBw';

const FirebaseOptions pulseWiseWebFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyC_zloU6cHVH0Pr6swWTbEAVPTaMBI6RLQ',
  appId: '1:930387576551:web:043db2513f75abcfc60442',
  messagingSenderId: '930387576551',
  projectId: 'pulse-wise-app',
  authDomain: 'pulse-wise-app.firebaseapp.com',
  storageBucket: 'pulse-wise-app.firebasestorage.app',
  measurementId: 'G-CJDJ059LSQ',
);

FirebaseOptions? firebaseInitializationOptionsForCurrentPlatform() {
  if (kIsWeb) {
    return pulseWiseWebFirebaseOptions;
  }

  return null;
}
