// providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? get user => _user;

  // Fetch user data from Firestore
  Future<void> fetchUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final data = doc.data()!;
        _user = AppUser(
          id: data['id'],
          email: data['email'],
          displayName: data['displayName'],
          joinDate: (data['joinDate'] as Timestamp).toDate(),
          isVerified: data['isVerified'] ?? false,
          contributionScore: data['contributionScore'] ?? 0,
          avatarUrl: data['photoURL'],
          role: _parseUserRole(data['role']),
          badges: List<String>.from(data['badges'] ?? []),
          reportCount: data['reportCount'] ?? 0,
          commentCount: data['commentCount'] ?? 0,
        );
        notifyListeners();
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    if (_user == null) return;

    try {
      await _firestore.collection('users').doc(_user!.id).update(updates);
      await fetchUserData(_user!.id); // Refresh local data
    } catch (e) {
      print("Error updating user data: $e");
      rethrow;
    }
  }

  UserRole _parseUserRole(String role) {
    switch (role) {
      case 'moderator':
        return UserRole.moderator;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.member;
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
