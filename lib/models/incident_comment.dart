import 'package:flutter/foundation.dart';

class IncidentComment {
  final String id;
  final String incidentId;
  final String userId;
  final String userDisplayName;
  final String content;
  final DateTime timestamp;
  final int upvotes;
  final int downvotes;
  final List<String> likedBy;
  final List<String> dislikedBy;

  IncidentComment({
    required this.id,
    required this.incidentId,
    required this.userId,
    required this.userDisplayName,
    required this.content,
    required this.timestamp,
    this.upvotes = 0,
    this.downvotes = 0,
    this.likedBy = const [],
    this.dislikedBy = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'incidentId': incidentId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'upvotes': upvotes,
      'downvotes': downvotes,
      'likedBy': likedBy,
      'dislikedBy': dislikedBy,
    };
  }

  static IncidentComment fromJson(Map<String, dynamic> json) {
    return IncidentComment(
      id: json['id'],
      incidentId: json['incidentId'],
      userId: json['userId'],
      userDisplayName: json['userDisplayName'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      likedBy: List<String>.from(json['likedBy'] ?? []),
      dislikedBy: List<String>.from(json['dislikedBy'] ?? []),
    );
  }

  IncidentComment copyWith({
    String? content,
    int? upvotes,
    int? downvotes,
    List<String>? likedBy,
    List<String>? dislikedBy,
  }) {
    return IncidentComment(
      id: id,
      incidentId: incidentId,
      userId: userId,
      userDisplayName: userDisplayName,
      content: content ?? this.content,
      timestamp: timestamp,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      likedBy: likedBy ?? this.likedBy,
      dislikedBy: dislikedBy ?? this.dislikedBy,
    );
  }
}
