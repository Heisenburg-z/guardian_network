import 'package:flutter/material.dart';
import '../models/crime_incident.dart';

class IncidentCard extends StatelessWidget {
  final CrimeIncident incident;
  final int commentCount;
  final VoidCallback onTap;

  const IncidentCard({
    super.key,
    required this.incident,
    required this.commentCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildSeverityIcon(incident.severity),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      incident.type,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.chat_bubble_outline, size: 16),
                  SizedBox(width: 4),
                  Text('$commentCount'),
                ],
              ),
              SizedBox(height: 8),
              Text(
                incident.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 12),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(incident.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Spacer(),
                  if (incident.hasVideo)
                    Row(
                      children: [
                        Icon(Icons.videocam, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Video',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityIcon(CrimeSeverity severity) {
    Color color;
    IconData icon;

    switch (severity) {
      case CrimeSeverity.high:
        color = Colors.red;
        icon = Icons.dangerous;
        break;
      case CrimeSeverity.medium:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case CrimeSeverity.low:
        color = Colors.yellow;
        icon = Icons.info;
        break;
    }

    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: Colors.white),
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
