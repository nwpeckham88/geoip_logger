// lib/firebase_options.dart

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {

      return const FirebaseOptions(
        apiKey: "AIzaSyBH8IRntYetulk_PpJUlTN8_ZzmC-RahfA",
        authDomain: "geoip-logger.firebaseapp.com",
        projectId: "geoip-logger",
        storageBucket: "geoip-logger.firebasestorage.app",
        messagingSenderId: "398153664691",
        appId: "1:398153664691:web:ad6ae36553b4c3363348c6",
        measurementId: "G-VCFC36P079",
      );
  }
}