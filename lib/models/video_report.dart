import 'package:latlong2/latlong.dart'; // Make sure this import is present

class VideoReport {
  final String id;
  final String videoPath;
  final LatLng location;
  final DateTime timestamp;
  final String? userId;
  final bool isVerified;
  final String crimeType;
  final String description;

  VideoReport({
    required this.id,
    required this.videoPath,
    required this.location,
    required this.timestamp,
    this.userId,
    this.isVerified = false,
    required this.crimeType,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoPath': videoPath,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'isVerified': isVerified,
      'crimeType': crimeType,
      'description': description,
    };
  }

  static VideoReport fromJson(Map<String, dynamic> json) {
    return VideoReport(
      id: json['id'],
      videoPath: json['videoPath'],
      location: LatLng(json['latitude'], json['longitude']),
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      isVerified: json['isVerified'] ?? false,
      crimeType: json['crimeType'],
      description: json['description'],
    );
  }
}
