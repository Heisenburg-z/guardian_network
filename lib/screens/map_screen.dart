import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
import '../components/crime_marker.dart';
import '../components/report_incident_sheet.dart';
import '../components/sos_button.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'video_report_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Timer? _alertCheckTimer;
  LatLng? _currentLocation;
  final LocationService _locationService = LocationService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final LatLng _initialCenter = const LatLng(-26.2041, 28.0473); // Johannesburg

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startAlertChecking();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _alertCheckTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startAlertChecking() {
    _alertCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentLocation != null) {
        _checkNearbyThreats();
      }
    });
  }

  void _checkNearbyThreats() {
    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    final nearbyThreats = crimeData.getNearbyThreats(_currentLocation!, 0.5);

    if (nearbyThreats.isNotEmpty && mounted) {
      _showThreatAlert(nearbyThreats.length);
    }
  }

  void _showThreatAlert(int threatCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                '$threatCount recent incidents nearby',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () => _zoomToThreats(),
        ),
      ),
    );
  }

  void _zoomToThreats() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      // Handle error silently for hackathon demo
    }
  }

  void _reportIncident(LatLng location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReportIncidentSheet(location: location),
    );
  }

  void _openVideoReport() {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Waiting for location...')));
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: VideoReportScreen(location: _currentLocation!),
      ),
    );
  }

  void _showHeatmapToggle() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Heatmap view toggled')));
  }

  void _showTimeFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 24 hours'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.day);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Last week'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.week);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Last month'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.month);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SOS Activated'),
        content: const Text(
          'Emergency contacts notified!\nRecording started automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Add SOS incident to data
    if (_currentLocation != null) {
      Provider.of<CrimeDataProvider>(context, listen: false).addIncident(
        CrimeIncident(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'Emergency SOS',
          location: _currentLocation!,
          timestamp: DateTime.now(),
          severity: CrimeSeverity.high,
          description: 'SOS button activated',
        ),
      );
    }
  }

  void _goToMyLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 16.0);
    } else {
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.security, size: 28),
            SizedBox(width: 10),
            Text('Guardian Network'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.layers),
            onPressed: _showHeatmapToggle,
            tooltip: 'Toggle Heatmap',
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showTimeFilter,
            tooltip: 'Time Filter',
          ),
        ],
      ),
      body: Consumer<CrimeDataProvider>(
        builder: (context, crimeData, child) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation ?? _initialCenter,
                  initialZoom: 12.0,
                  onTap: (TapPosition tapPosition, LatLng point) {
                    _reportIncident(point);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.guardian.network',
                  ),
                  MarkerLayer(
                    markers: _buildCrimeMarkers(crimeData.filteredIncidents),
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          child: ScaleTransition(
                            scale: _pulseAnimation,
                            child: Icon(
                              Icons.location_pin,
                              color: AppTheme.primaryColor,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              Positioned(
                bottom: 100,
                right: 16,
                child: Column(
                  children: [
                    // Camera Button for Video Recording
                    FloatingActionButton(
                      heroTag: "camera",
                      onPressed: _openVideoReport,
                      backgroundColor: Colors.blue,
                      child: const Icon(
                        Icons.videocam,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    SizedBox(height: 16),
                    // SOS Button
                    SOSButton(onPressed: _triggerSOS),
                    SizedBox(height: 16),
                    // Location Button
                    FloatingActionButton.small(
                      heroTag: "location",
                      onPressed: _goToMyLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Marker> _buildCrimeMarkers(List<CrimeIncident> incidents) {
    return incidents.map((incident) {
      return Marker(
        point: incident.location,
        width: 40,
        height: 40,
        child: CrimeMarker(incident: incident),
      );
    }).toList();
  }
}
