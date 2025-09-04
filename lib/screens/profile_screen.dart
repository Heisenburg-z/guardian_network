// screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Add this import
import 'package:firebase_auth/firebase_auth.dart'; // Add this import
import '../services/auth_service.dart';
import '../providers/user_provider.dart';
import '../models/app_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isEditing = false;
  final TextEditingController _displayNameController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      _displayNameController.text = userProvider.user!.displayName;
    }
  }

  Future<void> _uploadProfilePicture() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        print('Starting upload for user: ${userProvider.user!.id}');

        // Upload to Firebase Storage
        final Reference storageRef = FirebaseStorage.instance.ref().child(
          'users/${userProvider.user!.id}/profile.jpg',
        );

        print('Storage reference created: ${storageRef.fullPath}');

        // Add metadata and handle upload state
        final SettableMetadata metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'uploaded_by': userProvider.user!.id},
        );

        final UploadTask uploadTask = storageRef.putFile(imageFile, metadata);

        // Listen to upload state changes
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          print(
            'Upload progress: ${snapshot.bytesTransferred}/${snapshot.totalBytes}',
          );
        });

        // Wait for upload to complete
        final TaskSnapshot snapshot = await uploadTask;
        print('Upload completed successfully');

        // Get download URL
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Download URL: $downloadUrl');

        // Update user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.user!.id)
            .update({
              'photoURL': downloadUrl,
              'lastActive': FieldValue.serverTimestamp(),
            });

        print('Firestore document updated');

        // Update local user data
        userProvider.updateUser(
          userProvider.user!.copyWith(avatarUrl: downloadUrl),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
          ),
        );
      }
    } catch (e) {
      print('Error uploading profile picture: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _updateDisplayName() async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.user!.id)
          .update({
            'displayName': newName,
            'lastActive': FieldValue.serverTimestamp(),
          });

      // Update local user data
      userProvider.updateUser(
        userProvider.user!.copyWith(displayName: newName),
      );

      // Update in Firebase Auth
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
      await FirebaseAuth.instance.currentUser?.updateProfile(
        displayName: newName,
      );

      setState(() {
        _isEditing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating display name: $e')),
      );
    }
  }

  Future<void> _updatePreference(String key, dynamic value) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userProvider.user!.id)
          .update({
            'preferences.$key': value,
            'lastActive': FieldValue.serverTimestamp(),
          });

      // Update local user preferences
      final updatedPreferences = userProvider.user!.preferences.copyWith(
        notifications: key == 'notifications'
            ? value as bool
            : userProvider.user!.preferences.notifications,
        alertRadius: key == 'alertRadius'
            ? value.toDouble()
            : userProvider.user!.preferences.alertRadius,
        theme: key == 'theme'
            ? value as String
            : userProvider.user!.preferences.theme,
      );

      userProvider.updateUser(
        userProvider.user!.copyWith(preferences: updatedPreferences),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preference updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating preference: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateDisplayName,
            )
          else if (user != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              userProvider.clearUser();
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserHeader(user),
                  const SizedBox(height: 24),
                  _buildUserStats(user),
                  const SizedBox(height: 24),
                  _buildPreferencesSection(user),
                  const SizedBox(height: 24),
                  _buildAccountActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserHeader(AppUser user) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue[100],
              backgroundImage:
                  user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                  ? NetworkImage(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                  ? Text(
                      user.displayName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (!_isUploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, size: 18),
                    color: Colors.white,
                    onPressed: _uploadProfilePicture,
                  ),
                ),
              )
            else
              Positioned.fill(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue.shade300,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isEditing)
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter display name',
                    border: OutlineInputBorder(),
                  ),
                )
              else
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
              value: user.contributionScore / 1000,
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

  Widget _buildPreferencesSection(AppUser user) {
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
              value: user.preferences.notifications,
              onChanged: (value) => _updatePreference('notifications', value),
            ),
            ListTile(
              title: const Text('Alert Radius'),
              subtitle: Text('${user.preferences.alertRadius} km'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRadiusDialog(user.preferences.alertRadius),
            ),
            ListTile(
              title: const Text('Theme'),
              subtitle: Text(user.preferences.theme),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeDialog(user.preferences.theme),
            ),
          ],
        ),
      ),
    );
  }

  void _showRadiusDialog(double currentRadius) {
    showDialog(
      context: context,
      builder: (context) {
        double selectedRadius = currentRadius;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Alert Radius'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: selectedRadius,
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '${selectedRadius.round()} km',
                    onChanged: (value) {
                      setState(() {
                        selectedRadius = value;
                      });
                    },
                  ),
                  Text('${selectedRadius.round()} km'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    _updatePreference('alertRadius', selectedRadius.round());
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showThemeDialog(String currentTheme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile(
                title: const Text('Light'),
                value: 'light',
                groupValue: currentTheme,
                onChanged: (value) {
                  _updatePreference('theme', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('Dark'),
                value: 'dark',
                groupValue: currentTheme,
                onChanged: (value) {
                  _updatePreference('theme', value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile(
                title: const Text('System'),
                value: 'system',
                groupValue: currentTheme,
                onChanged: (value) {
                  _updatePreference('theme', value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
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

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }
}
