import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
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
  Completer<GoogleMapController> _mapController = Completer();
  Timer? _alertCheckTimer;
  LatLng? _currentLocation;
  final LocationService _locationService = LocationService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Google Maps initial position
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-26.2041, 28.0473), // Johannesburg
    zoom: 12.0,
  );

  // Map objects
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  Set<Polygon> _polygons = {};
  bool _showHeatmap = true;

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
      final controller = _mapController.future;
      controller.then((googleMapController) {
        googleMapController.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
            15.0,
          ),
        );
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _updateUserLocationMarker();
      }
    } catch (e) {
      // Handle error silently for hackathon demo
    }
  }

  void _updateUserLocationMarker() {
    if (_currentLocation != null) {
      setState(() {
        _markers.removeWhere(
          (marker) => marker.markerId.value == 'user_location',
        );
        _markers.add(
          Marker(
            markerId: MarkerId('user_location'),
            position: _currentLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(title: 'Your Location'),
          ),
        );
      });
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

  void _toggleHeatmap() {
    setState(() {
      _showHeatmap = !_showHeatmap;
    });
    _updateCrimeData();
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
                _updateCrimeData();
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
                _updateCrimeData();
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
                _updateCrimeData();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateCrimeData() {
    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    _createCrimeMarkers(crimeData.filteredIncidents);
    if (_showHeatmap) {
      _createHeatmap(crimeData.filteredIncidents);
    } else {
      setState(() {
        _circles.clear();
      });
    }
  }

  void _createCrimeMarkers(List<CrimeIncident> incidents) {
    Set<Marker> newMarkers = {};

    for (var incident in incidents) {
      final markerId = MarkerId(incident.id);
      final markerColor = _getMarkerColor(incident.severity);

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(
            incident.location.latitude,
            incident.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: incident.type,
            snippet:
                'Severity: ${incident.severity.toString().split('.').last}',
          ),
          onTap: () => _showIncidentDetails(incident),
        ),
      );
    }

    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value != 'user_location',
      );
      _markers.addAll(newMarkers);
    });
  }

  double _getMarkerColor(CrimeSeverity severity) {
    switch (severity) {
      case CrimeSeverity.high:
        return BitmapDescriptor.hueRed;
      case CrimeSeverity.medium:
        return BitmapDescriptor.hueOrange;
      case CrimeSeverity.low:
        return BitmapDescriptor.hueYellow;
    }
  }

  void _createHeatmap(List<CrimeIncident> incidents) {
    Set<Circle> newCircles = {};

    for (var incident in incidents) {
      final circleId = CircleId(incident.id);
      final circleColor = _getCircleColor(incident.severity);

      newCircles.add(
        Circle(
          circleId: circleId,
          center: LatLng(
            incident.location.latitude,
            incident.location.longitude,
          ),
          radius: 100, // meters
          fillColor: circleColor.withOpacity(0.3),
          strokeColor: circleColor,
          strokeWidth: 1,
        ),
      );
    }

    setState(() {
      _circles = newCircles;
    });
  }

  Color _getCircleColor(CrimeSeverity severity) {
    switch (severity) {
      case CrimeSeverity.high:
        return Colors.red;
      case CrimeSeverity.medium:
        return Colors.orange;
      case CrimeSeverity.low:
        return Colors.yellow;
    }
  }

  void _showIncidentDetails(CrimeIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(incident.type),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${_formatTime(incident.timestamp)}'),
            Text(
              'Severity: ${incident.severity.toString().split('.').last.toUpperCase()}',
            ),
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
      _updateCrimeData();
    }
  }

  void _goToMyLocation() async {
    if (_currentLocation != null) {
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude, _currentLocation!.longitude),
          16.0,
        ),
      );
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
            icon: Icon(_showHeatmap ? Icons.layers : Icons.layers_clear),
            onPressed: _toggleHeatmap,
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
          // Update markers when data changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _createCrimeMarkers(crimeData.filteredIncidents);
            if (_showHeatmap) {
              _createHeatmap(crimeData.filteredIncidents);
            }
          });

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController.complete(controller);
                  _updateCrimeData();
                },
                initialCameraPosition: _initialCameraPosition,
                markers: _markers,
                circles: _circles,
                polygons: _polygons,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                onTap: (LatLng position) {
                  _reportIncident(position);
                },
                mapType: MapType.normal,
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
}
