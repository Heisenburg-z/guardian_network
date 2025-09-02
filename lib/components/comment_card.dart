import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident_comment.dart';
import '../models/crime_incident.dart';
import '../models/crime_data_provider.dart';

class CommentCard extends StatelessWidget {
  final IncidentComment comment;
  final CrimeIncident incident;
  final bool showIncidentInfo;
  final VoidCallback? onTap; // ADD THIS

  const CommentCard({
    super.key,
    required this.comment,
    required this.incident,
    this.showIncidentInfo = true,
    this.onTap, // ADD THIS
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap, // ADD THIS
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIncidentInfo)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RE: ${incident.type}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Text(
                      comment.userDisplayName[0],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.userDisplayName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatTime(comment.timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  _buildVoteButtons(context),
                ],
              ),
              SizedBox(height: 8),
              Text(comment.content),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.thumb_up, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('${comment.upvotes}'),
                  SizedBox(width: 16),
                  Icon(Icons.thumb_down, size: 14, color: Colors.red),
                  SizedBox(width: 4),
                  Text('${comment.downvotes}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButtons(BuildContext context) {
    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    final currentUserId = 'demo_user'; // For hackathon demo

    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.thumb_up, size: 18),
          color: comment.likedBy.contains(currentUserId)
              ? Colors.green
              : Colors.grey,
          onPressed: () => crimeData.likeComment(comment.id, currentUserId),
        ),
        IconButton(
          icon: Icon(Icons.thumb_down, size: 18),
          color: comment.dislikedBy.contains(currentUserId)
              ? Colors.red
              : Colors.grey,
          onPressed: () => crimeData.dislikeComment(comment.id, currentUserId),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}
