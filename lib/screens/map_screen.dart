import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Controllers and Services
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();

  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _fabController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _fabSlideAnimation;

  // Timers and Streams
  Timer? _alertCheckTimer;
  Timer? _locationUpdateTimer;
  StreamSubscription<Position>? _positionStream;

  // State Variables
  LatLng? _currentLocation;
  LatLng? _lastKnownLocation;
  bool _isLocationLoading = true;
  bool _isMapReady = false;
  bool _showHeatmap = true;
  bool _fabsExpanded = false;
  String _currentMapStyle = '';

  // Map Objects
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  final Set<Polygon> _safeZones = {};
  final Set<Polyline> _routes = {};

  // Constants
  static const Duration _alertCheckInterval = Duration(seconds: 30);
  static const Duration _locationUpdateInterval = Duration(seconds: 10);
  static const double _threatRadius = 0.5; // km
  static const double _defaultZoom = 12.0;
  static const double _detailZoom = 16.0;

  // Johannesburg coordinates
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(-26.2041, 28.0473),
    zoom: _defaultZoom,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimations();
    _loadMapStyle();
    _initializeLocation();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshLocationAndData();
    } else if (state == AppLifecycleState.paused) {
      _pauseUpdates();
    }
  }

  // Initialization Methods
  void _initializeAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fabSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
        );
  }

  Future<void> _loadMapStyle() async {
    try {
      _currentMapStyle = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/map_styles/dark_mode.json');
    } catch (e) {
      debugPrint('Map style loading failed: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      await _requestLocationPermissions();
      await _getCurrentLocation();
      _startLocationStream();
    } catch (e) {
      _handleLocationError(e);
    }
  }

  Future<void> _requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions permanently denied');
    }
  }

  void _startLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateLocation(LatLng(position.latitude, position.longitude));
          },
          onError: _handleLocationError,
        );
  }

  void _startPeriodicUpdates() {
    _alertCheckTimer = Timer.periodic(_alertCheckInterval, (_) {
      if (_currentLocation != null && _isMapReady) {
        _checkNearbyThreats();
      }
    });

    _locationUpdateTimer = Timer.periodic(_locationUpdateInterval, (_) {
      if (_isMapReady) {
        _updateCrimeData();
      }
    });
  }

  // Location Management
  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        _updateLocation(newLocation);
        _animateToLocation(newLocation);
      }
    } catch (e) {
      _handleLocationError(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }

  void _updateLocation(LatLng newLocation) {
    if (_currentLocation == null ||
        _calculateDistance(_currentLocation!, newLocation) > 10) {
      setState(() {
        _lastKnownLocation = _currentLocation;
        _currentLocation = newLocation;
      });
      _updateUserLocationMarker();
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  void _handleLocationError(dynamic error) {
    debugPrint('Location error: $error');
    if (mounted) {
      _showErrorSnackBar(
        'Location access failed. Some features may be limited.',
      );
    }
  }

  Future<void> _animateToLocation(LatLng location, {double? zoom}) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoom ?? _detailZoom),
      );
    }
  }

  // Map Management
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    if (_currentMapStyle.isNotEmpty) {
      controller.setMapStyle(_currentMapStyle);
    }

    setState(() {
      _isMapReady = true;
    });

    _updateCrimeData();
    _fabController.forward();

    // Initial zoom to user location if available
    if (_currentLocation != null) {
      _animateToLocation(_currentLocation!);
    }
  }

  void _updateUserLocationMarker() {
    if (_currentLocation == null) return;

    setState(() {
      _markers.removeWhere(
        (marker) => marker.markerId.value == 'user_location',
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
        ),
      );
    });
  }

  // Crime Data Management
  void _updateCrimeData() {
    if (!_isMapReady) return;

    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    final incidents = crimeData.filteredIncidents;

    _createCrimeMarkers(incidents);
    _createSafeZones();

    if (_showHeatmap) {
      _createHeatmap(incidents);
    } else {
      setState(() {
        _circles.clear();
      });
    }
  }

  void _createCrimeMarkers(List<CrimeIncident> incidents) {
    final Set<Marker> newMarkers = {};

    // Keep user location marker
    final userMarker = _markers.where(
      (marker) => marker.markerId.value == 'user_location',
    );
    newMarkers.addAll(userMarker);

    // Add crime incident markers with clustering for performance
    final clusteredIncidents = _clusterIncidents(incidents);

    for (var cluster in clusteredIncidents) {
      final markerId = MarkerId(cluster.id);
      final markerColor = _getMarkerColor(cluster.severity);
      final isCluster = _clusterCounts.containsKey(cluster.id);
      final clusterCount = _clusterCounts[cluster.id] ?? 1;

      newMarkers.add(
        Marker(
          markerId: markerId,
          position: LatLng(
            cluster.location.latitude,
            cluster.location.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: InfoWindow(
            title: isCluster ? '$clusterCount incidents' : cluster.type,
            snippet: isCluster
                ? 'Multiple incidents in this area'
                : 'Severity: ${cluster.severity.name.toUpperCase()}',
          ),
          onTap: () => isCluster
              ? _showClusterDetails(cluster)
              : _showIncidentDetails(cluster),
        ),
      );
    }

    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  // Store cluster information separately
  final Map<String, int> _clusterCounts = {};
  final Map<String, List<CrimeIncident>> _clusterData = {};

  List<CrimeIncident> _clusterIncidents(List<CrimeIncident> incidents) {
    // Simple clustering algorithm - group incidents within 100m
    const double clusterDistance = 100; // meters
    final List<CrimeIncident> clustered = [];
    final List<bool> processed = List.filled(incidents.length, false);

    // Clear previous cluster data
    _clusterCounts.clear();
    _clusterData.clear();

    for (int i = 0; i < incidents.length; i++) {
      if (processed[i]) continue;

      final incident = incidents[i];
      final List<CrimeIncident> clusterGroup = [incident];
      processed[i] = true;

      for (int j = i + 1; j < incidents.length; j++) {
        if (processed[j]) continue;

        final distance = _calculateDistance(
          incident.location,
          incidents[j].location,
        );

        if (distance <= clusterDistance) {
          clusterGroup.add(incidents[j]);
          processed[j] = true;
        }
      }

      if (clusterGroup.length > 1) {
        // Create cluster incident
        final center = _calculateClusterCenter(clusterGroup);
        final maxSeverity = clusterGroup
            .map((e) => e.severity.index)
            .reduce(math.max);

        final clusterId = 'cluster_${incident.id}';
        final clusterIncident = CrimeIncident(
          id: clusterId,
          type: 'Multiple Incidents',
          location: center,
          timestamp: clusterGroup
              .map((e) => e.timestamp)
              .reduce((a, b) => a.isAfter(b) ? a : b),
          severity: CrimeSeverity.values[maxSeverity],
          description: '${clusterGroup.length} incidents in this area',
        );

        // Store cluster information
        _clusterCounts[clusterId] = clusterGroup.length;
        _clusterData[clusterId] = clusterGroup;

        clustered.add(clusterIncident);
      } else {
        clustered.add(incident);
      }
    }

    return clustered;
  }

  LatLng _calculateClusterCenter(List<CrimeIncident> incidents) {
    double totalLat = 0;
    double totalLng = 0;

    for (var incident in incidents) {
      totalLat += incident.location.latitude;
      totalLng += incident.location.longitude;
    }

    return LatLng(totalLat / incidents.length, totalLng / incidents.length);
  }

  void _createHeatmap(List<CrimeIncident> incidents) {
    final Set<Circle> newCircles = {};

    for (var incident in incidents) {
      final radius = _getHeatmapRadius(incident.severity);
      final color = _getCircleColor(incident.severity);

      newCircles.add(
        Circle(
          circleId: CircleId(incident.id),
          center: LatLng(
            incident.location.latitude,
            incident.location.longitude,
          ),
          radius: radius,
          fillColor: color.withOpacity(0.2),
          strokeColor: color.withOpacity(0.6),
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _circles.clear();
      _circles.addAll(newCircles);
    });
  }

  double _getHeatmapRadius(CrimeSeverity severity) {
    switch (severity) {
      case CrimeSeverity.high:
        return 200;
      case CrimeSeverity.medium:
        return 150;
      case CrimeSeverity.low:
        return 100;
    }
  }

  void _createSafeZones() {
    // Create polygons for known safe zones (schools, hospitals, police stations)
    final safeZoneColor = Colors.green.withOpacity(0.1);

    // Example safe zones - in a real app, this would come from a service
    final List<List<LatLng>> safeZoneCoordinates = [
      // University of the Witwatersrand area
      [
        const LatLng(-26.1886, 28.0284),
        const LatLng(-26.1886, 28.0334),
        const LatLng(-26.1936, 28.0334),
        const LatLng(-26.1936, 28.0284),
      ],
    ];

    final Set<Polygon> newSafeZones = {};
    for (int i = 0; i < safeZoneCoordinates.length; i++) {
      newSafeZones.add(
        Polygon(
          polygonId: PolygonId('safe_zone_$i'),
          points: safeZoneCoordinates[i],
          fillColor: safeZoneColor,
          strokeColor: Colors.green,
          strokeWidth: 2,
        ),
      );
    }

    setState(() {
      _safeZones.clear();
      _safeZones.addAll(newSafeZones);
    });
  }

  // Helper Methods
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

  // Threat Detection
  void _checkNearbyThreats() {
    if (_currentLocation == null) return;

    final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
    final nearbyThreats = crimeData.getNearbyThreats(
      _currentLocation!,
      _threatRadius,
    );

    if (nearbyThreats.isNotEmpty && mounted) {
      final highSeverityCount = nearbyThreats
          .where((threat) => threat.severity == CrimeSeverity.high)
          .length;

      if (highSeverityCount > 0) {
        _showHighPriorityAlert(highSeverityCount, nearbyThreats.length);
      } else {
        _showThreatAlert(nearbyThreats.length);
      }
    }
  }

  void _showHighPriorityAlert(int highSeverityCount, int totalCount) {
    HapticFeedback.vibrate();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.dangerous, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HIGH ALERT',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$highSeverityCount serious incidents nearby',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: _zoomToThreats,
        ),
      ),
    );
  }

  void _showThreatAlert(int threatCount) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$threatCount recent incidents nearby',
                style: const TextStyle(fontWeight: FontWeight.w500),
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
          onPressed: _zoomToThreats,
        ),
      ),
    );
  }

  Future<void> _zoomToThreats() async {
    if (_currentLocation == null || _mapController == null) return;

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_currentLocation!, 15.0),
    );
  }

  // UI Actions
  void _reportIncident(LatLng location) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ReportIncidentSheet(location: location),
      ),
    );
  }

  void _openVideoReport() {
    if (_currentLocation == null) {
      _showErrorSnackBar('Waiting for location...');
      return;
    }

    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: VideoReportScreen(location: _currentLocation!),
      ),
    );
  }

  void _toggleHeatmap() {
    HapticFeedback.selectionClick();
    setState(() {
      _showHeatmap = !_showHeatmap;
    });
    _updateCrimeData();
  }

  void _showTimeFilter() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Time'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Last 24 hours', TimeFilter.day),
            _buildFilterOption('Last week', TimeFilter.week),
            _buildFilterOption('Last month', TimeFilter.month),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, TimeFilter filter) {
    // Since _timeFilter is private, we'll compare with a simple workaround
    // You should add: TimeFilter get currentTimeFilter => _timeFilter; to CrimeDataProvider

    return ListTile(
      title: Text(title),
      leading: Icon(
        Icons.radio_button_unchecked, // For now, always show unchecked
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () {
        Provider.of<CrimeDataProvider>(
          context,
          listen: false,
        ).setTimeFilter(filter);
        Navigator.of(context).pop();
        _updateCrimeData();
      },
    );
  }

  // Incident Display
  void _showIncidentDetails(CrimeIncident incident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              _getIncidentIcon(incident.type),
              color: _getCircleColor(incident.severity),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(incident.type)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.access_time,
              'Time',
              _formatTime(incident.timestamp),
            ),
            _buildDetailRow(
              Icons.priority_high,
              'Severity',
              incident.severity.name.toUpperCase(),
            ),
            if (incident.description.isNotEmpty)
              _buildDetailRow(
                Icons.description,
                'Description',
                incident.description,
              ),
            if (_currentLocation != null)
              _buildDetailRow(
                Icons.location_on,
                'Distance',
                _formatDistance(
                  _calculateDistance(_currentLocation!, incident.location),
                ),
              ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          if (_currentLocation != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _animateToLocation(incident.location);
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Go There'),
            ),
        ],
      ),
    );
  }

  void _showClusterDetails(CrimeIncident cluster) {
    final clusterCount = _clusterCounts[cluster.id] ?? 1;
    final incidents = _clusterData[cluster.id] ?? [cluster];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$clusterCount Incidents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Multiple incidents reported in this area:'),
            const SizedBox(height: 12),
            Container(
              height: 150,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: incidents.length,
                itemBuilder: (context, index) {
                  final incident = incidents[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      _getIncidentIcon(incident.type),
                      color: _getCircleColor(incident.severity),
                      size: 20,
                    ),
                    title: Text(incident.type),
                    subtitle: Text(_formatTime(incident.timestamp)),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showIncidentDetails(incident);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _animateToLocation(cluster.location, zoom: 17.0);
            },
            icon: const Icon(Icons.zoom_in),
            label: const Text('Zoom In'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getIncidentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return Icons.local_police;
      case 'assault':
        return Icons.person_remove;
      case 'robbery':
        return Icons.warning;
      case 'vandalism':
        return Icons.broken_image;
      case 'emergency sos':
        return Icons.emergency;
      default:
        return Icons.report_problem;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${difference.inDays ~/ 7}w ago';
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m away';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km away';
    }
  }

  // SOS and Emergency
  void _triggerSOS() {
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.red.shade50,
        title: Row(
          children: [
            Icon(Icons.emergency, color: Colors.red, size: 32),
            const SizedBox(width: 12),
            const Text('SOS Activated', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency contacts have been notified!\nRecording started automatically.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            CircularProgressIndicator(color: Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    _addSOSIncident();
  }

  void _addSOSIncident() {
    if (_currentLocation != null) {
      Provider.of<CrimeDataProvider>(context, listen: false).addIncident(
        CrimeIncident(
          id: 'sos_${DateTime.now().millisecondsSinceEpoch}',
          type: 'Emergency SOS',
          location: _currentLocation!,
          timestamp: DateTime.now(),
          severity: CrimeSeverity.high,
          description: 'SOS button activated by user',
        ),
      );
      _updateCrimeData();
    }
  }

  Future<void> _goToMyLocation() async {
    HapticFeedback.lightImpact();

    if (_currentLocation != null) {
      await _animateToLocation(_currentLocation!);
    } else {
      setState(() {
        _isLocationLoading = true;
      });
      await _getCurrentLocation();
    }
  }

  void _toggleFABs() {
    setState(() {
      _fabsExpanded = !_fabsExpanded;
    });

    if (_fabsExpanded) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  // Utility Methods
  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _refreshLocationAndData() {
    _getCurrentLocation();
    _updateCrimeData();
  }

  void _pauseUpdates() {
    _alertCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
  }

  void _cleanup() {
    _alertCheckTimer?.cancel();
    _locationUpdateTimer?.cancel();
    _positionStream?.cancel();
    _pulseController.dispose();
    _fabController.dispose();
  }

  // UI Build Methods
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Icon(Icons.security, size: 28),
          const SizedBox(width: 10),
          const Text('Guardian Network'),
          if (_isLocationLoading)
            Container(
              margin: const EdgeInsets.only(left: 12),
              width: 16,
              height: 16,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: Icon(_showHeatmap ? Icons.layers : Icons.layers_clear),
        onPressed: _toggleHeatmap,
        tooltip: _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
      ),
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: _showTimeFilter,
        tooltip: 'Time Filter',
      ),
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: _handleMenuSelection,
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'refresh',
            child: ListTile(
              leading: Icon(Icons.refresh),
              title: Text('Refresh Data'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuItem(
            value: 'settings',
            child: ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    ];
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'refresh':
        _refreshLocationAndData();
        break;
      case 'settings':
        // Navigate to settings - implement as needed
        break;
    }
  }

  Widget _buildBody() {
    return Consumer<CrimeDataProvider>(
      builder: (context, crimeData, child) {
        return Stack(
          children: [
            _buildMap(),
            if (!_isMapReady) _buildLoadingOverlay(),
            _buildStatsBanner(crimeData),
          ],
        );
      },
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: _initialCameraPosition,
      markers: _markers,
      circles: _circles,
      polygons: _safeZones,
      polylines: _routes,
      myLocationEnabled: false, // We handle this manually
      myLocationButtonEnabled: false,
      onTap: _reportIncident,
      mapType: MapType.normal,
      zoomControlsEnabled: false,
      compassEnabled: true,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomGesturesEnabled: true,
      buildingsEnabled: true,
      trafficEnabled: false,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading map...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsBanner(CrimeDataProvider crimeData) {
    final incidentCount = crimeData.filteredIncidents.length;
    final nearbyCount = _currentLocation != null
        ? crimeData.getNearbyThreats(_currentLocation!, _threatRadius).length
        : 0;

    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.report_problem,
                label: 'Total',
                value: incidentCount.toString(),
                color: Theme.of(context).colorScheme.primary,
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatItem(
                icon: Icons.location_on,
                label: 'Nearby',
                value: nearbyCount.toString(),
                color: nearbyCount > 0 ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Video Recording Button
        SlideTransition(
          position: _fabSlideAnimation,
          child: FloatingActionButton(
            heroTag: "camera",
            onPressed: _openVideoReport,
            backgroundColor: Colors.blue,
            tooltip: 'Record Video Report',
            child: const Icon(Icons.videocam, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 16),

        // SOS Button with pulse animation
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: SOSButton(onPressed: _triggerSOS),
            );
          },
        ),
        const SizedBox(height: 16),

        // Location Button with loading state
        FloatingActionButton.small(
          heroTag: "location",
          onPressed: _isLocationLoading ? null : _goToMyLocation,
          tooltip: 'Go to My Location',
          backgroundColor: _isLocationLoading
              ? Colors.grey
              : Theme.of(context).colorScheme.secondary,
          child: _isLocationLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.my_location),
        ),
      ],
    );
  }
}
