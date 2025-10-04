import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../auth/auth_service.dart';
import 'package:ACADEMe/started/pages/login_view.dart';


class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  Map<String, dynamic>? teacherProfile;
  bool isLoading = true;
  bool isEditing = false;

  // Controllers for editing
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _subjectController = TextEditingController();
  final _photoUrlController = TextEditingController();
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _subjectController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          teacherProfile = json.decode(response.body);
          _populateControllers();
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _populateControllers() {
    if (teacherProfile != null) {
      _nameController.text = teacherProfile!['name'] ?? '';
      _bioController.text = teacherProfile!['bio'] ?? '';
      _subjectController.text = teacherProfile!['subject'] ?? '';
      _photoUrlController.text = teacherProfile!['photo_url'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Teacher Profile'),
          backgroundColor: AcademeTheme.appColor,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AcademeTheme.appColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Profile'),
        backgroundColor: AcademeTheme.appColor,
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
          if (isEditing) ...[
            TextButton(
              onPressed: _cancelEdit,
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _saveProfile,
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              SizedBox(height: 24),
              _buildProfileInfo(),
              SizedBox(height: 24),
              _buildPreferences(),
              SizedBox(height: 24),
              _buildAllottedClasses(),
              SizedBox(height: 24),
              _buildStatistics(),
              if (!isEditing) ...[
                SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AcademeTheme.appColor.withOpacity(0.1),
                  backgroundImage: (isEditing
                                  ? _photoUrlController.text
                                  : teacherProfile?['photo_url']) !=
                              null &&
                          (isEditing
                                  ? _photoUrlController.text
                                  : teacherProfile!['photo_url'])
                              .isNotEmpty
                      ? NetworkImage(isEditing
                          ? _photoUrlController.text
                          : teacherProfile!['photo_url'])
                      : null,
                  child: (isEditing
                                  ? _photoUrlController.text
                                  : teacherProfile?['photo_url']) ==
                              null ||
                          (isEditing
                                  ? _photoUrlController.text
                                  : teacherProfile!['photo_url'])
                              .isEmpty
                      ? Icon(Icons.person,
                          color: AcademeTheme.appColor, size: 50)
                      : null,
                ),
                if (isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AcademeTheme.appColor,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt,
                            color: Colors.white, size: 18),
                        onPressed: _showPhotoUrlDialog,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (isEditing)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              )
            else
              Text(
                teacherProfile?['name'] ?? 'Unknown Teacher',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AcademeTheme.appColor,
                ),
              ),
            SizedBox(height: 8),
            Text(
              teacherProfile?['email'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow(
                'Subject', _subjectController, teacherProfile?['subject']),
            SizedBox(height: 16),
            _buildBioSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
      String label, TextEditingController controller, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                )
              : Text(
                  value ?? 'Not specified',
                  style: TextStyle(fontSize: 16),
                ),
        ),
      ],
    );
  }

  Widget _buildBioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Bio:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        isEditing
            ? TextField(
                controller: _bioController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Tell us about yourself...',
                ),
                maxLines: 4,
              )
            : Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  teacherProfile?['bio'] ?? 'No bio provided',
                  style: TextStyle(fontSize: 16),
                ),
              ),
      ],
    );
  }

  Widget _buildPreferences() {
    final notificationsEnabled =
        teacherProfile?['notifications_enabled'] ?? true;
    final emailNotifications = teacherProfile?['email_notifications'] ?? true;
    final autoRecord = teacherProfile?['auto_record'] ?? false;

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            _buildPreferenceItem(
              'Push Notifications',
              'Receive push notifications on your device',
              notificationsEnabled,
              Icons.notifications,
              (value) => _updatePreference('notifications_enabled', value),
            ),
            _buildPreferenceItem(
              'Email Notifications',
              'Receive notifications via email',
              emailNotifications,
              Icons.email,
              (value) => _updatePreference('email_notifications', value),
            ),
            _buildPreferenceItem(
              'Auto Record Classes',
              'Automatically record live classes',
              autoRecord,
              Icons.fiber_manual_record,
              (value) => _updatePreference('auto_record', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceItem(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AcademeTheme.appColor),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AcademeTheme.appColor,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAllottedClasses() {
    final allottedClasses =
        teacherProfile?['allotted_classes'] as List<dynamic>? ?? [];

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allotted Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            if (allottedClasses.isEmpty)
              Text(
                'No classes assigned yet',
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allottedClasses.map((className) {
                  return Chip(
                    label: Text(className),
                    backgroundColor: AcademeTheme.appColor.withOpacity(0.1),
                    labelStyle: TextStyle(color: AcademeTheme.appColor),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = teacherProfile?['stats'] as Map<String, dynamic>? ?? {};

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teaching Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Students',
                    (stats['total_students'] ?? 0).toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Classes Taught',
                    (stats['classes_taught'] ?? 0).toString(),
                    Icons.school,
                    Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Content Uploaded',
                    (stats['content_uploaded'] ?? 0).toString(),
                    Icons.upload_file,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Live Sessions',
                    (stats['live_sessions'] ?? 0).toString(),
                    Icons.video_call,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _changePassword,
            icon: Icon(Icons.lock_outline),
            label: Text('Change Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _exportData,
            icon: Icon(Icons.download),
            label: Text('Export My Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AcademeTheme.appColor,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            label: Text('Logout'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoUrlDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Photo'),
        content: TextField(
          controller: _photoUrlController,
          decoration: InputDecoration(
            labelText: 'Photo URL',
            border: OutlineInputBorder(),
            hintText: 'Enter image URL',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {}); // Refresh to show new image
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AcademeTheme.appColor),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  void _cancelEdit() {
    setState(() {
      isEditing = false;
      _populateControllers(); // Reset to original values
    });
  }

  Future<void> _saveProfile() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.put(
        Uri.parse(ApiEndpoints.updateTeacherProfile),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'bio': _bioController.text.trim(),
          'subject': _subjectController.text.trim(),
          'photo_url': _photoUrlController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadProfile();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.put(
        Uri.parse(ApiEndpoints.updateTeacherPreferences),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({key: value}),
      );

      if (response.statusCode == 200) {
        setState(() {
          teacherProfile![key] = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preference updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update preference')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _changePassword() {
    // Implementation for changing password
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Change password feature coming soon!')),
    );
  }

  void _exportData() {
    // Implementation for exporting data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Export data feature coming soon!')),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Center(
                    child: CircularProgressIndicator(
                      color: AcademeTheme.appColor,
                    ),
                  ),
                );

                // Perform logout
                await authService.signOut();

                // Close loading indicator
                if (mounted) Navigator.pop(context);

                if (!mounted) return;

                // Navigate to login screen and clear navigation stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LogInView()),
                      (route) => false,
                );

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully logged out'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                debugPrint('Error during logout: $e');

                // Close loading indicator if still showing
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error logging out: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
