import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../../../localization/l10n.dart';

class TeacherSettings extends StatefulWidget {
  const TeacherSettings({super.key});

  @override
  TeacherSettingsState createState() => TeacherSettingsState();
}

class TeacherSettingsState extends State<TeacherSettings> {
  final _storage = FlutterSecureStorage();
  bool isLoading = true;
  Map<String, dynamic>? teacherProfile;
  List<String> allottedClasses = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherProfile();
  }

  Future<void> _fetchTeacherProfile() async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          teacherProfile = data;
          allottedClasses = List<String>.from(data['allotted_classes'] ?? []);
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch teacher profile: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching teacher profile: $e");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  void _updateProfile() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
            text: teacherProfile?['name'] ?? ''
        );
        final TextEditingController bioController = TextEditingController(
            text: teacherProfile?['bio'] ?? ''
        );
        final TextEditingController subjectController = TextEditingController(
            text: teacherProfile?['subject'] ?? ''
        );

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Update Profile')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Name'),
                  ),
                ),
                TextField(
                  controller: bioController,
                  decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Bio'),
                  ),
                  maxLines: 3,
                ),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Subject'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                await _submitProfileUpdate(
                  name: nameController.text,
                  bio: bioController.text,
                  subject: subjectController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(L10n.getTranslatedText(context, 'Update')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitProfileUpdate({
    required String name,
    required String bio,
    required String subject,
  }) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.put(
        ApiEndpoints.getUri(ApiEndpoints.updateTeacherProfile),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "name": name,
          "bio": bio,
          "subject": subject,
        }),
      );

      if (response.statusCode == 200) {
        _fetchTeacherProfile(); // Refresh profile
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(context, 'Profile updated successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("Failed to update profile");
      }
    } catch (e) {
      _showError("Error updating profile: $e");
    }
  }

  Widget _buildProfileSection() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  L10n.getTranslatedText(context, 'Teacher Profile'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _updateProfile,
                  icon: Icon(Icons.edit),
                  label: Text(L10n.getTranslatedText(context, 'Edit')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcademeTheme.appColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(
                    teacherProfile?['photo_url'] ??
                        'https://www.w3schools.com/w3images/avatar2.png',
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherProfile?['name'] ?? 'Unknown Teacher',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(teacherProfile?['email'] ?? ''),
                      Text(
                        teacherProfile?['subject'] ?? 'No subject specified',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (teacherProfile?['bio']?.isNotEmpty ?? false) ...[
              SizedBox(height: 16),
              Text(
                L10n.getTranslatedText(context, 'Bio'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(teacherProfile!['bio']),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAllottedClassesSection() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Allotted Classes'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (allottedClasses.isEmpty)
              Text(
                L10n.getTranslatedText(context, 'No classes allotted yet'),
                style: TextStyle(color: Colors.grey[600]),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allottedClasses.map((className) {
                  return Chip(
                    label: Text('Class $className'),
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

  Widget _buildPreferencesSection() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Preferences'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text(L10n.getTranslatedText(context, 'Notifications')),
              trailing: Switch(
                value: teacherProfile?['notifications_enabled'] ?? true,
                onChanged: (value) {
                  _updateNotificationPreference(value);
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text(L10n.getTranslatedText(context, 'Email Notifications')),
              trailing: Switch(
                value: teacherProfile?['email_notifications'] ?? true,
                onChanged: (value) {
                  _updateEmailNotificationPreference(value);
                },
              ),
            ),
            ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text(L10n.getTranslatedText(context, 'Auto-record Classes')),
              trailing: Switch(
                value: teacherProfile?['auto_record'] ?? false,
                onChanged: (value) {
                  _updateAutoRecordPreference(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateNotificationPreference(bool enabled) async {
    await _updatePreference('notifications_enabled', enabled);
  }

  Future<void> _updateEmailNotificationPreference(bool enabled) async {
    await _updatePreference('email_notifications', enabled);
  }

  Future<void> _updateAutoRecordPreference(bool enabled) async {
    await _updatePreference('auto_record', enabled);
  }

  Future<void> _updatePreference(String key, bool value) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.put(
        ApiEndpoints.getUri(ApiEndpoints.updateTeacherPreferences),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({key: value}),
      );

      if (response.statusCode == 200) {
        setState(() {
          teacherProfile?[key] = value;
        });
      }
    } catch (e) {
      debugPrint("Error updating preference: $e");
    }
  }

  Widget _buildStatsSection() {
    final stats = teacherProfile?['stats'] ?? {};

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Teaching Stats'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.school,
                    title: L10n.getTranslatedText(context, 'Total Students'),
                    value: '${stats['total_students'] ?? 0}',
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.video_call,
                    title: L10n.getTranslatedText(context, 'Classes Held'),
                    value: '${stats['classes_held'] ?? 0}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.content_copy,
                    title: L10n.getTranslatedText(context, 'Content Created'),
                    value: '${stats['content_created'] ?? 0}',
                    color: Colors.orange,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.star,
                    title: L10n.getTranslatedText(context, 'Avg Rating'),
                    value: '${(stats['average_rating'] ?? 0.0).toStringAsFixed(1)}',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileSection(),
            _buildAllottedClassesSection(),
            _buildStatsSection(),
            _buildPreferencesSection(),
          ],
        ),
      ),
    );
  }
}
