import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // ADD THIS IMPORT
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/crime_data_provider.dart';
import '../services/video_service.dart';
import '../models/video_report.dart';

class VideoReportScreen extends StatefulWidget {
  final LatLng location;
  final bool isAnonymous;

  const VideoReportScreen({
    super.key,
    required this.location,
    this.isAnonymous = true,
  });

  @override
  _VideoReportScreenState createState() => _VideoReportScreenState();
}

class _VideoReportScreenState extends State<VideoReportScreen> {
  final VideoService _videoService = VideoService();
  final TextEditingController _crimeTypeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isRecording = false;
  String? _recordedVideoPath;
  int _recordingTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    await _videoService.initializeCamera();
    setState(() {});
  }

  Future<void> _startRecording() async {
    final result = await _videoService.startRecording();
    if (result != null) {
      setState(() {
        _isRecording = true;
        _recordingTime = 0;
      });

      // Start timer to update UI with recording time
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingTime++;
        });

        // Auto-stop after 60 seconds
        if (_recordingTime >= 60) {
          _stopRecording();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    final videoPath = await _videoService.stopRecording();
    setState(() {
      _isRecording = false;
      _recordedVideoPath = videoPath;
    });
  }

  Future<void> _submitReport() async {
    if (_recordedVideoPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please record a video first')));
      return;
    }

    if (_crimeTypeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please specify the crime type')));
      return;
    }

    final report = VideoReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      videoPath: _recordedVideoPath!,
      location: widget.location,
      timestamp: DateTime.now(),
      userId: widget.isAnonymous ? null : 'current_user_id',
      isVerified: !widget.isAnonymous,
      crimeType: _crimeTypeController.text,
      description: _descriptionController.text,
    );

    Provider.of<CrimeDataProvider>(
      context,
      listen: false,
    ).addVideoReport(report);

    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Report submitted successfully!')));
  }

  @override
  void dispose() {
    _videoService.dispose();
    _timer?.cancel();
    _crimeTypeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Crime with Video'),
        actions: [
          if (_recordedVideoPath != null)
            IconButton(icon: Icon(Icons.check), onPressed: _submitReport),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview
          Expanded(
            flex: 3,
            child:
                _videoService.controller != null &&
                    _videoService.controller!.value.isInitialized
                ? AspectRatio(
                    aspectRatio: _videoService.controller!.value.aspectRatio,
                    child: CameraPreview(_videoService.controller!),
                  )
                : Center(child: CircularProgressIndicator()),
          ),

          // Recording Controls
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!_isRecording && _recordedVideoPath == null)
                  FloatingActionButton(
                    onPressed: _startRecording,
                    child: Icon(Icons.videocam),
                    backgroundColor: Colors.red,
                  ),
                if (_isRecording)
                  FloatingActionButton(
                    onPressed: _stopRecording,
                    child: Icon(Icons.stop),
                    backgroundColor: Colors.red,
                  ),
                if (_isRecording)
                  Padding(
                    padding: EdgeInsets.only(left: 16),
                    child: Text(
                      'Recording: $_recordingTime seconds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Report Form
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _crimeTypeController,
                    decoration: InputDecoration(
                      labelText: 'Crime Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.isAnonymous
                        ? 'Reporting anonymously'
                        : 'Reporting as verified user',
                    style: TextStyle(
                      color: widget.isAnonymous ? Colors.grey : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
