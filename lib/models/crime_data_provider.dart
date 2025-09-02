import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'crime_incident.dart';
import 'video_report.dart';
import 'incident_comment.dart';
import 'app_user.dart';

class CrimeDataProvider extends ChangeNotifier {
  List<CrimeIncident> _incidents = [];
  List<VideoReport> _videoReports = [];
  TimeFilter _timeFilter = TimeFilter.day;

  List<CrimeIncident> get allIncidents => _incidents;
  List<VideoReport> get videoReports => _videoReports;
  List<IncidentComment> _comments = [];
  List<AppUser> _demoUsers = [];

  List<IncidentComment> get comments => _comments;
  List<AppUser> get demoUsers => _demoUsers;

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
    _loadDemoUsers();
    _loadDemoComments();
  }
  void _loadDemoUsers() {
    _demoUsers = [
      AppUser.demo('user1'),
      AppUser.demo('user2'),
      AppUser.demo('user3'),
      AppUser.demo('user4'),
      AppUser.demo('user5'),
    ];
  }

  void _loadDemoComments() {
    final comments = [
      IncidentComment(
        id: '1',
        incidentId: '0', // Matches sample incident
        userId: 'user1',
        userDisplayName: 'SafetyHero',
        content:
            'I saw this happen too! The suspect was wearing a blue jacket.',
        timestamp: DateTime.now().subtract(Duration(hours: 2)),
        upvotes: 15,
        downvotes: 2,
      ),
      IncidentComment(
        id: '2',
        incidentId: '0',
        userId: 'user2',
        userDisplayName: 'NeighborhoodWatch',
        content:
            'There are security cameras on that corner. Should check with the store owners.',
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        upvotes: 8,
        downvotes: 1,
      ),
      IncidentComment(
        id: '3',
        incidentId: '1', // Another incident
        userId: 'user3',
        userDisplayName: 'CommunityGuardian',
        content:
            'This area has been getting worse lately. We need more patrols.',
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        upvotes: 5,
        downvotes: 0,
      ),
    ];
    _comments.addAll(comments);
  }

  List<IncidentComment> getCommentsForIncident(String incidentId) {
    return _comments
        .where((comment) => comment.incidentId == incidentId)
        .toList();
  }

  void addComment(IncidentComment comment) {
    _comments.insert(0, comment);
    notifyListeners();
  }

  void likeComment(String commentId, String userId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final comment = _comments[index];
      final newLikedBy = List<String>.from(comment.likedBy)..add(userId);
      final newDislikedBy = List<String>.from(comment.dislikedBy)
        ..remove(userId);

      _comments[index] = comment.copyWith(
        upvotes: comment.likedBy.contains(userId)
            ? comment.upvotes
            : comment.upvotes + 1,
        downvotes: comment.dislikedBy.contains(userId)
            ? comment.downvotes - 1
            : comment.downvotes,
        likedBy: newLikedBy,
        dislikedBy: newDislikedBy,
      );
      notifyListeners();
    }
  }

  void dislikeComment(String commentId, String userId) {
    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index != -1) {
      final comment = _comments[index];
      final newDislikedBy = List<String>.from(comment.dislikedBy)..add(userId);
      final newLikedBy = List<String>.from(comment.likedBy)..remove(userId);

      _comments[index] = comment.copyWith(
        downvotes: comment.dislikedBy.contains(userId)
            ? comment.downvotes
            : comment.downvotes + 1,
        upvotes: comment.likedBy.contains(userId)
            ? comment.upvotes - 1
            : comment.upvotes,
        dislikedBy: newDislikedBy,
        likedBy: newLikedBy,
      );
      notifyListeners();
    }
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
          hasVideo: random.nextBool(),
          isVerified: random.nextBool(),
        ),
      );
    }
  }

  void addIncident(CrimeIncident incident) {
    _incidents.insert(0, incident);
    notifyListeners();
  }

  void addVideoReport(VideoReport report) {
    _videoReports.insert(0, report);

    // Also create a regular incident for the map
    addIncident(
      CrimeIncident(
        id: report.id,
        type: report.crimeType,
        location: report.location,
        timestamp: report.timestamp,
        severity: CrimeSeverity.medium,
        description: report.description,
        hasVideo: true,
        isVerified: report.isVerified,
      ),
    );

    notifyListeners();
  }

  VideoReport? getVideoReport(String id) {
    try {
      return _videoReports.firstWhere((report) => report.id == id);
    } catch (e) {
      return null;
    }
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

  AppUser? getUser(String userId) {
    return _demoUsers.firstWhere((user) => user.id == userId);
  }
}
