// providers/user_provider.dart
import 'dart:async'; // Add this import for StreamSubscription
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  AppUser? get user => _user;

  // Initialize user provider
  void initialize() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        // Start listening to user document when user is authenticated
        _listenToUserDocument(firebaseUser.uid);
      } else {
        // Clear user when signed out
        clearUser();
      }
    });
  }

  // Listen to user document changes
  void _listenToUserDocument(String uid) {
    // Cancel any existing subscription
    _userSubscription?.cancel();

    _userSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (DocumentSnapshot snapshot) {
            if (snapshot.exists) {
              _user = AppUser.fromMap(snapshot.data() as Map<String, dynamic>);
              notifyListeners();
            } else {
              // Create user document if it doesn't exist
              _createUserDocument(uid);
            }
          },
          onError: (error) {
            print("Error listening to user document: $error");
          },
        );
  }

  // Create user document if it doesn't exist
  Future<void> _createUserDocument(String uid) async {
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser != null) {
        final userData = {
          'id': uid,
          'email': authUser.email,
          'displayName': authUser.displayName ?? 'User',
          'photoURL': authUser.photoURL,
          'joinDate': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isVerified': false,
          'isAnonymous': false,
          'contributionScore': 0,
          'role': 'user',
          'badges': [],
          'reportCount': 0,
          'commentCount': 0,
          'preferences': {
            'notifications': true,
            'alertRadius': 5,
            'theme': 'system',
          },
          'blockedUsers': [],
        };

        await _firestore.collection('users').doc(uid).set(userData);
      }
    } catch (e) {
      print("Error creating user document: $e");
    }
  }

  // Fetch user data manually (for use in auth_wrapper)
  Future<void> fetchUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _user = AppUser.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
      } else {
        await _createUserDocument(uid);
        // After creating, fetch again
        await fetchUserData(uid);
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Clear user data
  void clearUser() {
    _userSubscription?.cancel();
    _user = null;
    notifyListeners();
  }

  // Dispose provider
  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
