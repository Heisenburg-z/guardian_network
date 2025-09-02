// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
import 'incident_detail_screen.dart';
import '../components/incident_card.dart';
import '../components/comment_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.report), text: 'Incidents'),
            Tab(icon: Icon(Icons.chat), text: 'Discussions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncidentsTab(), _buildDiscussionsTab()],
      ),
    );
  }

  Widget _buildIncidentsTab() {
    return Consumer<CrimeDataProvider>(
      builder: (context, crimeData, child) {
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: crimeData.allIncidents.length,
          itemBuilder: (context, index) {
            final incident = crimeData.allIncidents[index];
            final comments = crimeData.getCommentsForIncident(incident.id);

            return IncidentCard(
              incident: incident,
              commentCount: comments.length,
              onTap: () => _showIncidentDetails(context, incident),
            );
          },
        );
      },
    );
  }

  Widget _buildDiscussionsTab() {
    return Consumer<CrimeDataProvider>(
      builder: (context, crimeData, child) {
        final allComments = crimeData.comments;

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: allComments.length,
          itemBuilder: (context, index) {
            final comment = allComments[index];
            final incident = crimeData.allIncidents.firstWhere(
              (incident) => incident.id == comment.incidentId,
              orElse: () => CrimeIncident(
                id: 'unknown',
                type: 'Unknown Incident',
                location: LatLng(0, 0),
                timestamp: DateTime.now(),
                severity: CrimeSeverity.low,
                description: '',
              ),
            );

            return CommentCard(
              comment: comment,
              incident: incident,
              onTap: () => _showIncidentDetails(context, incident),
            );
          },
        );
      },
    );
  }

  void _showIncidentDetails(BuildContext context, CrimeIncident incident) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IncidentDetailScreen(incident: incident),
      ),
    );
  }
}
