import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/crime_incident.dart';
import '../models/crime_data_provider.dart';

class CrimeMarker extends StatelessWidget {
  final CrimeIncident incident;

  const CrimeMarker({super.key, required this.incident});

  @override
  Widget build(BuildContext context) {
    Color markerColor;
    IconData markerIcon;

    switch (incident.severity) {
      case CrimeSeverity.high:
        markerColor = Colors.red;
        markerIcon = Icons.dangerous;
        break;
      case CrimeSeverity.medium:
        markerColor = Colors.orange;
        markerIcon = Icons.warning;
        break;
      case CrimeSeverity.low:
        markerColor = Colors.yellow;
        markerIcon = Icons.info;
        break;
    }

    // Create badges list
    List<Widget> badges = [];

    // Add video badge if incident has video
    if (incident.hasVideo) {
      badges.add(
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(Icons.videocam, size: 10, color: Colors.white),
          ),
        ),
      );
    }

    // Add verified badge if incident is verified
    if (incident.isVerified) {
      badges.add(
        Positioned(
          right: incident.hasVideo ? 14 : 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(Icons.verified_user, size: 10, color: Colors.white),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showIncidentDetails(context, incident),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(markerIcon, color: Colors.white, size: 22),
          ),
          ...badges,
        ],
      ),
    );
  }

  void _showIncidentDetails(BuildContext context, CrimeIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(incident.type),
            if (incident.isVerified)
              Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.verified, color: Colors.green, size: 18),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (incident.hasVideo)
              Container(
                margin: EdgeInsets.only(bottom: 12),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.play_arrow),
                  label: Text('Play Video Evidence'),
                  onPressed: () {
                    Navigator.pop(context);
                    _playVideo(context, incident.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            _buildDetailRow(Icons.access_time, _formatTime(incident.timestamp)),
            _buildDetailRow(
              Icons.warning,
              'Severity: ${incident.severity.name.toUpperCase()}',
            ),
            if (incident.isVerified)
              _buildDetailRow(
                Icons.verified_user,
                'Verified Report',
                color: Colors.green,
              ),
            if (incident.description.isNotEmpty)
              _buildDetailRow(Icons.description, incident.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _playVideo(BuildContext context, String incidentId) {
    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    final videoReport = crimeData.getVideoReport(incidentId);

    if (videoReport != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              VideoPlayerScreen(videoPath: videoReport.videoPath),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Video not available')));
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;

  const VideoPlayerScreen({super.key, required this.videoPath});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.file(File(widget.videoPath));
      await _controller.initialize();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error initializing video: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load video')));
      Navigator.pop(context);
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Evidence'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
                VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Colors.red,
                    bufferedColor: Colors.grey,
                    backgroundColor: Colors.grey[700]!,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10, size: 30),
                        color: Colors.white,
                        onPressed: () {
                          final newPosition =
                              _controller.value.position -
                              Duration(seconds: 10);
                          _controller.seekTo(
                            newPosition > Duration.zero
                                ? newPosition
                                : Duration.zero,
                          );
                        },
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 40,
                        ),
                        color: Colors.white,
                        onPressed: _togglePlayPause,
                      ),
                      SizedBox(width: 20),
                      IconButton(
                        icon: Icon(Icons.forward_10, size: 30),
                        color: Colors.white,
                        onPressed: () {
                          final newPosition =
                              _controller.value.position +
                              Duration(seconds: 10);
                          if (newPosition < _controller.value.duration) {
                            _controller.seekTo(newPosition);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
