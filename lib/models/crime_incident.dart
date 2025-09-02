import 'package:latlong2/latlong.dart';

enum CrimeSeverity { low, medium, high }

enum TimeFilter { day, week, month }

class CrimeIncident {
  final String id;
  final String type;
  final LatLng location;
  final DateTime timestamp;
  final CrimeSeverity severity;
  final String description;

  CrimeIncident({
    required this.id,
    required this.type,
    required this.location,
    required this.timestamp,
    required this.severity,
    required this.description,
  });
}
