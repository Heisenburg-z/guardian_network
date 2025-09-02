import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/incident_comment.dart';

class CommentInput extends StatefulWidget {
  final String incidentId;
  final VoidCallback onCommentAdded;

  const CommentInput({
    super.key,
    required this.incidentId,
    required this.onCommentAdded,
  });

  @override
  _CommentInputState createState() => _CommentInputState();
}

class _CommentInputState extends State<CommentInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isPosting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          SizedBox(width: 8),
          _isPosting
              ? CircularProgressIndicator()
              : IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: _controller.text.trim().isEmpty
                      ? null
                      : _postComment,
                ),
        ],
      ),
    );
  }

  Future<void> _postComment() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isPosting = true);

    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);

    final newComment = IncidentComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incidentId: widget.incidentId,
      userId: 'current_user', // Demo user ID
      userDisplayName: 'You',
      content: _controller.text.trim(),
      timestamp: DateTime.now(),
    );

    crimeData.addComment(newComment);
    _controller.clear();
    widget.onCommentAdded();

    setState(() => _isPosting = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
