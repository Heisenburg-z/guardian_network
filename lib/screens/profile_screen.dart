// screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Update the build method in ProfileScreen
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = userProvider.user;

    // Check if we have a Firebase user but no user data yet
    final hasFirebaseUser = authService.currentUser != null;
    final hasUserData = user != null && user.displayName.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              userProvider.clearUser();
            },
          ),
        ],
      ),
      body: !hasFirebaseUser
          ? const Center(child: Text('No user logged in'))
          : !hasUserData
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserHeader(user!),
                  const SizedBox(height: 24),
                  _buildUserStats(user),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(),
                  const SizedBox(height: 24),
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Setting up your profile...'),
        ],
      ),
    );
  }

  Widget _buildUserHeader(AppUser user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.blue[100],
          backgroundImage: user.avatarUrl != null
              ? NetworkImage(user.avatarUrl!)
              : null,
          child: user.avatarUrl == null
              ? Text(
                  user.displayName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                user.email ?? 'No email',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Chip(
                label: Text(
                  user.role.toString().split('.').last.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
                backgroundColor: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserStats(AppUser user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Community Contributions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Reports', user.reportCount),
                _buildStatItem('Comments', user.commentCount),
                _buildStatItem('Score', user.contributionScore),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value:
                  user.contributionScore /
                  1000, // Adjust based on your level system
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(user.levelColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Level: ${user.level.toString().split('.').last}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: user.levelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preferences',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Push Notifications'),
              value: true,
              onChanged: (value) {
                // Update preferences
              },
            ),
            ListTile(
              title: const Text('Alert Radius'),
              subtitle: const Text('5 km'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Show radius selection
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.verified_user),
            title: const Text('Verification Status'),
            trailing: Chip(
              label: const Text('Not Verified'),
              backgroundColor: Colors.orange[100],
            ),
            onTap: () {
              // Show verification process
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Activity History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to activity history
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Navigate to help section
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Show privacy policy
            },
          ),
        ],
      ),
    );
  }
}
