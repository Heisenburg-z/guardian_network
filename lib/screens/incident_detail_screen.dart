import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
import '../models/incident_comment.dart';
import '../components/comment_card.dart';
import '../components/comment_input.dart';

class IncidentDetailScreen extends StatefulWidget {
  final CrimeIncident incident;

  const IncidentDetailScreen({super.key, required this.incident});

  @override
  _IncidentDetailScreenState createState() => _IncidentDetailScreenState();
}

class _IncidentDetailScreenState extends State<IncidentDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Incident Discussion')),
      body: Consumer<CrimeDataProvider>(
        builder: (context, crimeData, child) {
          final comments = crimeData.getCommentsForIncident(widget.incident.id);

          return Column(
            children: [
              // Incident Header
              _buildIncidentHeader(),

              // Comments List
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) => CommentCard(
                    comment: comments[index],
                    incident: widget.incident,
                    showIncidentInfo: false,
                  ),
                ),
              ),

              // Comment Input
              CommentInput(
                incidentId: widget.incident.id,
                onCommentAdded: () => setState(() {}),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncidentHeader() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.incident.type,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              widget.incident.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              '${_formatTime(widget.incident.timestamp)} • ${widget.incident.severity.name.toUpperCase()}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
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
