import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';

class ReportIncidentSheet extends StatefulWidget {
  final LatLng location;

  const ReportIncidentSheet({super.key, required this.location});

  @override
  State<ReportIncidentSheet> createState() => _ReportIncidentSheetState();
}

class _ReportIncidentSheetState extends State<ReportIncidentSheet> {
  String _selectedType = 'Theft';
  String _description = '';
  CrimeSeverity _severity = CrimeSeverity.medium;

  final List<String> _crimeTypes = [
    'Theft',
    'Assault',
    'Robbery',
    'Vandalism',
    'Suspicious Activity',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Report Incident',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Incident Type'),
            items: _crimeTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
            ),
            maxLines: 3,
            onChanged: (value) => _description = value,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Severity: '),
              SegmentedButton<CrimeSeverity>(
                segments: const [
                  ButtonSegment(value: CrimeSeverity.low, label: Text('Low')),
                  ButtonSegment(
                    value: CrimeSeverity.medium,
                    label: Text('Med'),
                  ),
                  ButtonSegment(value: CrimeSeverity.high, label: Text('High')),
                ],
                selected: {_severity},
                onSelectionChanged: (Set<CrimeSeverity> selection) {
                  setState(() => _severity = selection.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Submit Report',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _submitReport() {
    final incident = CrimeIncident(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      location: widget.location,
      timestamp: DateTime.now(),
      severity: _severity,
      description: _description,
    );

    Provider.of<CrimeDataProvider>(
      context,
      listen: false,
    ).addIncident(incident);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Incident reported successfully!')),
    );
  }
}
