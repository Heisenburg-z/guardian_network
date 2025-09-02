// components/comment_card.dart
import 'package:flutter/material.dart';
import '../models/incident_comment.dart';
import '../models/crime_incident.dart';
import './media_viewer.dart';

class CommentCard extends StatelessWidget {
  final IncidentComment comment;
  final CrimeIncident incident;
  final VoidCallback onTap;
  final bool showIncidentInfo;

  const CommentCard({
    super.key,
    required this.comment,
    required this.incident,
    required this.onTap,
    this.showIncidentInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIncidentInfo) _buildIncidentHeader(),
              if (showIncidentInfo) const SizedBox(height: 12),
              _buildCommentHeader(),
              const SizedBox(height: 8),
              _buildCommentContent(),
              if (comment.media.isNotEmpty) ...[
                const SizedBox(height: 12),
                MediaViewer(media: comment.media),
              ],
              const SizedBox(height: 12),
              _buildCommentActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIncidentHeader() {
    return Row(
      children: [
        Icon(Icons.report_problem, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Regarding: ${incident.type} incident',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCommentHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.blue[100],
          child: Text(
            comment.userDisplayName[0].toUpperCase(),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.userDisplayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatTimeAgo(comment.timestamp),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        if (comment.isHighlyRated)
          Icon(Icons.star, color: Colors.amber[600], size: 16),
      ],
    );
  }

  Widget _buildCommentContent() {
    return Text(
      comment.content,
      style: const TextStyle(fontSize: 15, height: 1.4),
    );
  }

  Widget _buildCommentActions() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.thumb_up, size: 18),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        Text(
          comment.upvotes.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: Icon(Icons.thumb_down, size: 18),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        Text(
          comment.downvotes.toString(),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.reply, size: 18),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.share, size: 18),
          onPressed: () {},
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
