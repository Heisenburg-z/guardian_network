// screens/create_comment_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/incident_comment.dart';
import '../models/crime_incident.dart';

class CreateCommentScreen extends StatefulWidget {
  final CrimeIncident incident;

  const CreateCommentScreen({super.key, required this.incident});

  @override
  _CreateCommentScreenState createState() => _CreateCommentScreenState();
}

class _CreateCommentScreenState extends State<CreateCommentScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<CommentMedia> _media = [];
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Comment'),
        actions: [
          IconButton(icon: const Icon(Icons.send), onPressed: _submitComment),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comment on: ${widget.incident.type} incident',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _textController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Share your thoughts or information...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_media.isNotEmpty) _buildMediaPreview(),
                  ],
                ),
              ),
            ),
            _buildMediaButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _media.map((media) {
        return Stack(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: media.type == MediaType.image
                  ? Image.network(media.url, fit: BoxFit.cover)
                  : const Icon(Icons.videocam, size: 30),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: () => _removeMedia(media),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.photo_library),
          onPressed: _pickImage,
        ),
        IconButton(icon: const Icon(Icons.videocam), onPressed: _pickVideo),
        const Spacer(),
        TextButton(
          onPressed: () {
            if (_media.isNotEmpty) {
              _showCaptionDialog(_media.last);
            }
          },
          child: const Text('Add Caption'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _media.add(CommentMedia(type: MediaType.image, url: image.path));
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _media.add(CommentMedia(type: MediaType.video, url: video.path));
      });
    }
  }

  void _removeMedia(CommentMedia media) {
    setState(() {
      _media.remove(media);
    });
  }

  void _showCaptionDialog(CommentMedia media) {
    showDialog(
      context: context,
      builder: (context) {
        final captionController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Caption'),
          content: TextField(
            controller: captionController,
            decoration: const InputDecoration(hintText: 'Enter caption...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  final index = _media.indexOf(media);
                  _media[index] = CommentMedia(
                    type: media.type,
                    url: media.url,
                    caption: captionController.text,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _submitComment() {
    if (_textController.text.trim().isEmpty && _media.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please add text or media')));
      return;
    }

    final newComment = IncidentComment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      incidentId: widget.incident.id,
      userId: 'current_user',
      userDisplayName: 'Current User',
      content: _textController.text,
      timestamp: DateTime.now(),
      media: _media,
    );

    Navigator.pop(context, newComment);
  }
}
