import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class VideoService {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _maxRecordingDuration = 60; // 1 minute max

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _controller = CameraController(firstCamera, ResolutionPreset.medium);

    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
  }

  Future<Map<String, dynamic>?> startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }

    if (_isRecording) return null;

    try {
      // Get storage directory
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = path.join(extDir.path, 'crime_reports');
      await Directory(dirPath).create(recursive: true);

      final String filePath = path.join(
        dirPath,
        '${DateTime.now().millisecondsSinceEpoch}.mp4',
      );

      // Get current location
      final Position position = await Geolocator.getCurrentPosition();
      final LatLng location = LatLng(position.latitude, position.longitude);

      // Start recording
      await _controller!.startVideoRecording();
      _isRecording = true;

      // Start timer to auto-stop recording
      _recordingTimer = Timer(Duration(seconds: _maxRecordingDuration), () {
        stopRecording();
      });

      return {
        'filePath': filePath,
        'location': location,
        'startTime': DateTime.now(),
      };
    } catch (e) {
      print('Error starting video recording: $e');
      return null;
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _recordingTimer?.cancel();
      final XFile videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;

      // Return the path of the recorded video
      return videoFile.path;
    } catch (e) {
      print('Error stopping video recording: $e');
      return null;
    }
  }

  CameraController? get controller => _controller;
  Future<void>? get initializeFuture => _initializeControllerFuture;
  bool get isRecording => _isRecording;

  void dispose() {
    _controller?.dispose();
    _recordingTimer?.cancel();
  }
}
