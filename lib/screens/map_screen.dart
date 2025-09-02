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
      backgroundColor: Colors.transparent,
      builder: (context) => ReportIncidentSheet(location: location),
    );
  }

  void _showHeatmapToggle() {
    // For hackathon demo - toggle between different visualizations
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Heatmap view toggled'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showTimeFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Time Filter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(height: 16),
            Divider(height: 1),
            ListTile(
              leading: Icon(Icons.today, color: AppTheme.primaryColor),
              title: Text('Last 24 hours'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.day);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.date_range, color: AppTheme.primaryColor),
              title: Text('Last week'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.week);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              title: Text('Last month'),
              onTap: () {
                Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).setTimeFilter(TimeFilter.month);
                Navigator.of(context).pop();
              },
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _triggerSOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.errorColor),
            SizedBox(width: 10),
            Text('SOS Activated'),
          ],
        ),
        content: Text(
          'Emergency contacts notified!\nRecording started automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
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

  void _openVideoReport(LatLng location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: VideoReportScreen(location: location),
      ),
    );
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
                    FloatingActionButton.small(
                      heroTag: "location",
                      onPressed: _goToMyLocation,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      child: Icon(
                        Icons.my_location,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    SOSButton(onPressed: _triggerSOS),
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
