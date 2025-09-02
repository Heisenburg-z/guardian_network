import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'crime_incident.dart';

class CrimeDataProvider extends ChangeNotifier {
  List<CrimeIncident> _incidents = [];
  TimeFilter _timeFilter = TimeFilter.day;

  List<CrimeIncident> get allIncidents => _incidents;

  List<CrimeIncident> get filteredIncidents {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_timeFilter) {
      case TimeFilter.day:
        cutoff = now.subtract(const Duration(days: 1));
        break;
      case TimeFilter.week:
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case TimeFilter.month:
        cutoff = now.subtract(const Duration(days: 30));
        break;
    }

    return _incidents
        .where((incident) => incident.timestamp.isAfter(cutoff))
        .toList();
  }

  CrimeDataProvider() {
    _loadSampleData();
  }

  void _loadSampleData() {
    // Sample crime data for Johannesburg area - for hackathon demo
    final random = math.Random();
    final baseLocation = const LatLng(-26.2041, 28.0473);

    for (int i = 0; i < 20; i++) {
      final lat = baseLocation.latitude + (random.nextDouble() - 0.5) * 0.1;
      final lng = baseLocation.longitude + (random.nextDouble() - 0.5) * 0.1;
      final timestamp = DateTime.now().subtract(
        Duration(hours: random.nextInt(168)),
      );

      _incidents.add(
        CrimeIncident(
          id: i.toString(),
          type: ['Theft', 'Assault', 'Robbery', 'Vandalism'][random.nextInt(4)],
          location: LatLng(lat, lng),
          timestamp: timestamp,
          severity: CrimeSeverity.values[random.nextInt(3)],
          description: 'Sample incident for demo',
        ),
      );
    }
  }

  void addIncident(CrimeIncident incident) {
    _incidents.insert(0, incident);
    notifyListeners();
  }

  void setTimeFilter(TimeFilter filter) {
    _timeFilter = filter;
    notifyListeners();
  }

  List<CrimeIncident> getNearbyThreats(LatLng location, double radiusKm) {
    return filteredIncidents.where((incident) {
      final distance =
          Geolocator.distanceBetween(
            location.latitude,
            location.longitude,
            incident.location.latitude,
            incident.location.longitude,
          ) /
          1000; // Convert to km

      return distance <= radiusKm;
    }).toList();
  }
}
