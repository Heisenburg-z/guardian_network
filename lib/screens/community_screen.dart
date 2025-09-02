import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/crime_data_provider.dart';
import '../models/crime_incident.dart';
import '../models/incident_comment.dart';
import 'incident_detail_screen.dart';
import '../components/incident_card.dart';
import '../components/comment_card.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'create_comment_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCrimeType = 'All';
  CrimeSeverity? _selectedSeverity;
  bool _showOnlyVerified = false;
  bool _showSearchFilters = false;

  final List<String> _crimeTypes = [
    'All',
    'Theft',
    'Assault',
    'Robbery',
    'Vandalism',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _showCreateCommentScreen(CrimeIncident incident) async {
    final newComment = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateCommentScreen(incident: incident),
      ),
    );

    if (newComment != null) {
      // Add the new comment to your data provider
      final crimeData = Provider.of<CrimeDataProvider>(context, listen: false);
      crimeData.addComment(newComment);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment added successfully')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text(
          'Community Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showSearchFilters = !_showSearchFilters;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Refresh data - could trigger a reload in real app
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Community data refreshed'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showSearchFilters ? 200 : 100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search incidents or discussions...',
                    prefixIcon: Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
              ),

              // Filters (collapsible)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: _showSearchFilters ? 120 : 0,
                child: _showSearchFilters ? _buildFilters() : null,
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: Colors.blue[700],
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.blue[700],
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.report_problem, size: 18),
                        SizedBox(width: 8),
                        Text('Incidents'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum, size: 18),
                        SizedBox(width: 8),
                        Text('Discussions'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildIncidentsTab(), _buildDiscussionsTab()],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: () {
                // For demo, use the first incident
                // In a real app, you might want to let users choose
                if (Provider.of<CrimeDataProvider>(
                  context,
                  listen: false,
                ).allIncidents.isNotEmpty) {
                  final firstIncident = Provider.of<CrimeDataProvider>(
                    context,
                    listen: false,
                  ).allIncidents.first;
                  _showCreateCommentScreen(firstIncident);
                }
              },
              child: const Icon(Icons.add_comment),
            )
          : null,
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Crime Type Filter
          Row(
            children: [
              Text('Type: ', style: TextStyle(fontWeight: FontWeight.w500)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _crimeTypes.map((type) {
                      final isSelected = _selectedCrimeType == type;
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(type),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCrimeType = type;
                            });
                          },
                          selectedColor: Colors.blue[100],
                          checkmarkColor: Colors.blue[700],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          // Severity and Verified Filters
          Row(
            children: [
              Text('Severity: ', style: TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<CrimeSeverity?>(
                value: _selectedSeverity,
                hint: Text('Any'),
                onChanged: (severity) {
                  setState(() {
                    _selectedSeverity = severity;
                  });
                },
                items: [
                  DropdownMenuItem(value: null, child: Text('Any')),
                  ...CrimeSeverity.values.map((severity) {
                    return DropdownMenuItem(
                      value: severity,
                      child: Text(severity.name.toUpperCase()),
                    );
                  }),
                ],
              ),
              Spacer(),
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyVerified,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyVerified = value ?? false;
                      });
                    },
                  ),
                  Text('Verified only'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentsTab() {
    return Consumer<CrimeDataProvider>(
      builder: (context, crimeData, child) {
        final filteredIncidents = _getFilteredIncidents(crimeData);

        if (filteredIncidents.isEmpty) {
          return _buildEmptyState(
            icon: Icons.report_problem_outlined,
            title: 'No incidents found',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'No incidents match your current filters',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Simulate refresh
            await Future.delayed(Duration(seconds: 1));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Incidents refreshed')));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredIncidents.length + 1, // +1 for stats header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildStatsHeader(filteredIncidents.length, crimeData);
              }

              final incident = filteredIncidents[index - 1];
              final comments = crimeData.getCommentsForIncident(incident.id);

              return IncidentCard(
                incident: incident,
                commentCount: comments.length,
                onTap: () => _showIncidentDetails(context, incident),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDiscussionsTab() {
    return Consumer<CrimeDataProvider>(
      builder: (context, crimeData, child) {
        final filteredComments = _getFilteredComments(crimeData);

        if (filteredComments.isEmpty) {
          return _buildEmptyState(
            icon: Icons.forum_outlined,
            title: 'No discussions found',
            subtitle: _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Be the first to start a discussion!',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 1));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Discussions refreshed')));
          },
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: filteredComments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildDiscussionStats(filteredComments, crimeData);
              }

              final comment = filteredComments[index - 1];
              final incident = crimeData.allIncidents.firstWhere(
                (incident) => incident.id == comment.incidentId,
                orElse: () => CrimeIncident(
                  id: 'unknown',
                  type: 'Unknown Incident',
                  location: LatLng(0, 0),
                  timestamp: DateTime.now(),
                  severity: CrimeSeverity.low,
                  description: 'Incident not found',
                ),
              );

              return CommentCard(
                comment: comment,
                incident: incident,
                onTap: () => _showIncidentDetails(context, incident),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatsHeader(int incidentCount, CrimeDataProvider crimeData) {
    final highSeverityCount = crimeData.allIncidents
        .where((i) => i.severity == CrimeSeverity.high)
        .length;
    final verifiedCount = crimeData.allIncidents
        .where((i) => i.isVerified)
        .length;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.report,
                  label: 'Total',
                  value: '$incidentCount',
                  color: Colors.blue,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.dangerous,
                  label: 'High Priority',
                  value: '$highSeverityCount',
                  color: Colors.red,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.verified,
                  label: 'Verified',
                  value: '$verifiedCount',
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscussionStats(
    List<IncidentComment> comments,
    CrimeDataProvider crimeData,
  ) {
    final totalUpvotes = comments.fold(
      0,
      (sum, comment) => sum + comment.upvotes,
    );
    final activeUsers = comments.map((c) => c.userId).toSet().length;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discussion Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.chat,
                  label: 'Comments',
                  value: '${comments.length}',
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.thumb_up,
                  label: 'Upvotes',
                  value: '$totalUpvotes',
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                _buildStatChip(
                  icon: Icons.people,
                  label: 'Users',
                  value: '$activeUsers',
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_searchQuery.isNotEmpty || _hasActiveFilters()) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
                icon: Icon(Icons.clear_all),
                label: Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedCrimeType != 'All' ||
        _selectedSeverity != null ||
        _showOnlyVerified;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _selectedCrimeType = 'All';
      _selectedSeverity = null;
      _showOnlyVerified = false;
    });
  }

  List<CrimeIncident> _getFilteredIncidents(CrimeDataProvider crimeData) {
    var incidents = crimeData.allIncidents;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      incidents = incidents.where((incident) {
        return incident.type.toLowerCase().contains(_searchQuery) ||
            incident.description.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply crime type filter
    if (_selectedCrimeType != 'All') {
      incidents = incidents.where((incident) {
        return incident.type == _selectedCrimeType;
      }).toList();
    }

    // Apply severity filter
    if (_selectedSeverity != null) {
      incidents = incidents.where((incident) {
        return incident.severity == _selectedSeverity;
      }).toList();
    }

    // Apply verified filter
    if (_showOnlyVerified) {
      incidents = incidents.where((incident) {
        return incident.isVerified;
      }).toList();
    }

    // Sort by timestamp (newest first)
    incidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return incidents;
  }

  List<IncidentComment> _getFilteredComments(CrimeDataProvider crimeData) {
    var comments = crimeData.comments;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      comments = comments.where((comment) {
        return comment.content.toLowerCase().contains(_searchQuery) ||
            comment.userDisplayName.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Filter by incident criteria if filters are applied
    if (_hasActiveFilters()) {
      final filteredIncidentIds = _getFilteredIncidents(
        crimeData,
      ).map((i) => i.id).toSet();
      comments = comments.where((comment) {
        return filteredIncidentIds.contains(comment.incidentId);
      }).toList();
    }

    // Sort by timestamp (newest first)
    comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return comments;
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
