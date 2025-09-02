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
  final bool isEdited;
  final DateTime? editedAt;
  final List<CommentMedia> media;

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
    this.isEdited = false,
    this.editedAt,
    this.media = const [], // Initialize as empty list
  });

  IncidentComment copyWith({
    String? id,
    String? incidentId,
    String? userId,
    String? userDisplayName,
    String? content,
    DateTime? timestamp,
    int? upvotes,
    int? downvotes,
    List<String>? likedBy,
    List<String>? dislikedBy,
    bool? isEdited,
    DateTime? editedAt,
    List<CommentMedia>? media,
  }) {
    return IncidentComment(
      id: id ?? this.id,
      incidentId: incidentId ?? this.incidentId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      likedBy: likedBy ?? this.likedBy,
      dislikedBy: dislikedBy ?? this.dislikedBy,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      media: media ?? this.media,
    );
  }

  // Calculate net score
  int get netScore => upvotes - downvotes;

  // Check if comment is controversial (similar upvotes and downvotes)
  bool get isControversial =>
      upvotes > 5 && downvotes > 5 && (upvotes - downvotes).abs() <= 2;

  // Check if comment is highly rated
  bool get isHighlyRated => netScore >= 10;

  @override
  String toString() {
    return 'IncidentComment(id: $id, userId: $userId, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IncidentComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Add to incident_comment.dart
enum MediaType { none, image, video }

class CommentMedia {
  final MediaType type;
  final String url;
  final String? caption;

  CommentMedia({required this.type, required this.url, this.caption});

  @override
  String toString() {
    return 'CommentMedia(type: $type, url: $url, caption: $caption)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CommentMedia &&
        other.type == type &&
        other.url == url &&
        other.caption == caption;
  }

  @override
  int get hashCode => Object.hash(type, url, caption);
}
