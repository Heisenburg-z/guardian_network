import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/crime_incident.dart';

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

    return GestureDetector(
      onTap: () => _showIncidentDetails(context, incident),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
        child: Icon(markerIcon, color: Colors.white, size: 20),
      ),
    );
  }

  void _showIncidentDetails(BuildContext context, CrimeIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident.type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${_formatTime(incident.timestamp)}'),
            Text('Severity: ${incident.severity.name.toUpperCase()}'),
            if (incident.description.isNotEmpty)
              Text('Description: ${incident.description}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
