import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Community Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CrimeDataProvider>(
        builder: (context, crimeData, child) {
          if (crimeData.allIncidents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.report_problem, size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No incidents reported yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to report an incident',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: crimeData.allIncidents.length,
            itemBuilder: (context, index) {
              final incident = crimeData.allIncidents[index];
              return _IncidentCard(incident: incident);
            },
          );
        },
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final CrimeIncident incident;

  const _IncidentCard({required this.incident});

  @override
  Widget build(BuildContext context) {
    Color severityColor;
    IconData severityIcon;

    switch (incident.severity) {
      case CrimeSeverity.high:
        severityColor = AppTheme.errorColor;
        severityIcon = Icons.dangerous;
        break;
      case CrimeSeverity.medium:
        severityColor = AppTheme.accentColor;
        severityIcon = Icons.warning;
        break;
      case CrimeSeverity.low:
        severityColor = Colors.green;
        severityIcon = Icons.info;
        break;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: severityColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(severityIcon, color: severityColor, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.type,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    incident.description,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        _formatTime(incident.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          incident.severity.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: severityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.day}/${time.month}/${time.year} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
