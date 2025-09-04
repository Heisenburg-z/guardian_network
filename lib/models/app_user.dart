import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String? email;
  final String displayName;
  final DateTime joinDate;
  final DateTime lastActive;
  final bool isVerified;
  final bool isAnonymous;
  final int contributionScore;
  final String? avatarUrl;
  final UserRole role;
  final List<String> badges;
  final int reportCount;
  final int commentCount;
  final UserPreferences preferences;
  final List<String> blockedUsers;

  AppUser({
    required this.id,
    this.email,
    required this.displayName,
    required this.joinDate,
    required this.lastActive,
    this.isVerified = false,
    this.isAnonymous = false,
    this.contributionScore = 0,
    this.avatarUrl,
    this.role = UserRole.member,
    this.badges = const [],
    this.reportCount = 0,
    this.commentCount = 0,
    UserPreferences? preferences,
    this.blockedUsers = const [],
  }) : preferences = preferences ?? UserPreferences();

  // Factory constructor from Firestore document
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'],
      displayName: map['displayName'] ?? 'User',
      joinDate: (map['joinDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (map['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isVerified: map['isVerified'] ?? false,
      isAnonymous: map['isAnonymous'] ?? false,
      contributionScore: map['contributionScore'] ?? 0,
      avatarUrl: map['photoURL'] ?? map['avatarUrl'],
      role: _parseRole(map['role']),
      badges: List<String>.from(map['badges'] ?? []),
      reportCount: map['reportCount'] ?? 0,
      commentCount: map['commentCount'] ?? 0,
      preferences: _parsePreferences(map['preferences']),
      blockedUsers: List<String>.from(map['blockedUsers'] ?? []),
    );
  }

  static UserRole _parseRole(dynamic role) {
    if (role == null) return UserRole.member;
    if (role is String) {
      switch (role) {
        case 'admin':
          return UserRole.admin;
        case 'moderator':
          return UserRole.moderator;
        default:
          return UserRole.member;
      }
    }
    return UserRole.member;
  }

  static UserPreferences _parsePreferences(dynamic preferences) {
    if (preferences is Map<String, dynamic>) {
      return UserPreferences(
        notifications: preferences['notifications'] ?? true,
        alertRadius: (preferences['alertRadius'] ?? 5).toDouble(),
        theme: preferences['theme'] ?? 'system',
      );
    }
    return UserPreferences();
  }

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'joinDate': joinDate,
      'lastActive': lastActive,
      'isVerified': isVerified,
      'isAnonymous': isAnonymous,
      'contributionScore': contributionScore,
      'photoURL': avatarUrl,
      'role': role.toString().split('.').last,
      'badges': badges,
      'reportCount': reportCount,
      'commentCount': commentCount,
      'preferences': {
        'notifications': preferences.notifications,
        'alertRadius': preferences.alertRadius,
        'theme': preferences.theme,
      },
      'blockedUsers': blockedUsers,
    };
  }

  // Factory constructor for demo users
  factory AppUser.demo(String id) {
    final demoData = _getDemoUserData(id);
    return AppUser(
      id: id,
      displayName: demoData['displayName'],
      joinDate: demoData['joinDate'],
      lastActive: DateTime.now(),
      isVerified: demoData['isVerified'],
      contributionScore: demoData['contributionScore'],
      role: demoData['role'],
      badges: List<String>.from(demoData['badges']),
      reportCount: demoData['reportCount'],
      commentCount: demoData['commentCount'],
    );
  }

  static Map<String, dynamic> _getDemoUserData(String id) {
    final demoUsers = {
      'user1': {
        'displayName': 'SafetyHero',
        'joinDate': DateTime.now().subtract(Duration(days: 365)),
        'isVerified': true,
        'contributionScore': 250,
        'role': UserRole.moderator,
        'badges': ['Top Contributor', 'Verified Reporter'],
        'reportCount': 15,
        'commentCount': 45,
      },
      'user2': {
        'displayName': 'NeighborhoodWatch',
        'joinDate': DateTime.now().subtract(Duration(days: 180)),
        'isVerified': true,
        'contributionScore': 180,
        'role': UserRole.member,
        'badges': ['Community Guardian'],
        'reportCount': 8,
        'commentCount': 32,
      },
      'user3': {
        'displayName': 'CommunityGuardian',
        'joinDate': DateTime.now().subtract(Duration(days: 90)),
        'isVerified': false,
        'contributionScore': 95,
        'role': UserRole.member,
        'badges': ['New Member'],
        'reportCount': 3,
        'commentCount': 18,
      },
      'user4': {
        'displayName': 'LocalResident',
        'joinDate': DateTime.now().subtract(Duration(days: 45)),
        'isVerified': false,
        'contributionScore': 30,
        'role': UserRole.member,
        'badges': [],
        'reportCount': 1,
        'commentCount': 8,
      },
      'user5': {
        'displayName': 'CitySafety',
        'joinDate': DateTime.now().subtract(Duration(days: 200)),
        'isVerified': true,
        'contributionScore': 320,
        'role': UserRole.admin,
        'badges': ['Safety Expert', 'Admin', 'Top Contributor'],
        'reportCount': 25,
        'commentCount': 78,
      },
    };

    return demoUsers[id] ??
        {
          'displayName': 'Anonymous User',
          'joinDate': DateTime.now(),
          'isVerified': false,
          'contributionScore': 0,
          'role': UserRole.member,
          'badges': <String>[],
          'reportCount': 0,
          'commentCount': 0,
        };
  }

  // Calculate user level based on contribution score
  UserLevel get level {
    if (contributionScore >= 500) return UserLevel.expert;
    if (contributionScore >= 200) return UserLevel.advanced;
    if (contributionScore >= 50) return UserLevel.intermediate;
    return UserLevel.beginner;
  }

  // Get user level color
  Color get levelColor {
    switch (level) {
      case UserLevel.expert:
        return Colors.purple;
      case UserLevel.advanced:
        return Colors.blue;
      case UserLevel.intermediate:
        return Colors.green;
      case UserLevel.beginner:
        return Colors.grey;
    }
  }

  // Check if user is trusted (verified or high contribution)
  bool get isTrusted => isVerified || contributionScore >= 100;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    DateTime? joinDate,
    DateTime? lastActive,
    bool? isVerified,
    bool? isAnonymous,
    int? contributionScore,
    String? avatarUrl,
    UserRole? role,
    List<String>? badges,
    int? reportCount,
    int? commentCount,
    UserPreferences? preferences,
    List<String>? blockedUsers,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      joinDate: joinDate ?? this.joinDate,
      lastActive: lastActive ?? this.lastActive,
      isVerified: isVerified ?? this.isVerified,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      contributionScore: contributionScore ?? this.contributionScore,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      badges: badges ?? this.badges,
      reportCount: reportCount ?? this.reportCount,
      commentCount: commentCount ?? this.commentCount,
      preferences: preferences ?? this.preferences,
      blockedUsers: blockedUsers ?? this.blockedUsers,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, displayName: $displayName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class UserPreferences {
  final bool notifications;
  final double alertRadius;
  final String theme;

  UserPreferences({
    this.notifications = true,
    this.alertRadius = 5.0,
    this.theme = 'system',
  });
}

enum UserRole { member, moderator, admin }

enum UserLevel { beginner, intermediate, advanced, expert }
