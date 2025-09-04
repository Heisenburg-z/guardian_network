// services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream for auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Email sign in error: $e");
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name in Firebase Auth
      await result.user?.updateDisplayName(displayName);

      // Update profile to set display name
      await result.user?.updateProfile(displayName: displayName);

      // Create user document in Firestore
      await _createUserDocument(result.user!, displayName, email);

      return result.user;
    } catch (e) {
      print("Email registration error: $e");
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);

      // Check if user is new, create document if needed
      if (result.additionalUserInfo?.isNewUser ?? false) {
        await _createUserDocument(
          result.user!,
          result.user?.displayName ?? 'New User',
          result.user?.email ?? '',
        );
      } else {
        // For existing users, ensure the document exists
        final doc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();
        if (!doc.exists) {
          await _createUserDocument(
            result.user!,
            result.user?.displayName ?? 'User',
            result.user?.email ?? '',
          );
        }
      }

      return result.user;
    } catch (e) {
      print("Google sign in error: $e");
      rethrow;
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String displayName,
    String email,
  ) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {
          'id': user.uid,
          'email': email,
          'displayName': displayName,
          'photoURL': user.photoURL,
          'joinDate': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'isVerified': false,
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
        },
        SetOptions(merge: true),
      ); // Use merge to avoid overwriting existing data
    } catch (e) {
      print("Error creating user document: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
    } catch (e) {
      print("Sign out error: $e");
      rethrow;
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Password reset error: $e");
      rethrow;
    }
  }
}
