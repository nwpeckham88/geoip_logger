import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class GeoIPFirebaseFirestore {
  bool _isInitialized = false;
  bool _isLoaded = false;
  List<Map<String, dynamic>> _apis = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  GeoIPFirebaseFirestore(){}

  Future<void> initializeFirebase(FirebaseOptions options) async {
    try {
      await Firebase.initializeApp(options: options);
      await loadApis();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Firebase.');
      }
      throw 'Failed to initialize Firebase.';
    }
  }

  Future<List<Map<String, dynamic>>> loadApis() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('apis').get();
      _apis = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      _isLoaded = true;
      return _apis;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading APIs: $e');
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> serveData() async {
    return await loadApis();
  }

  bool isInitialized() {
    return _isInitialized;
  }

  bool isLoaded() {
    return _isLoaded;
  }
}
