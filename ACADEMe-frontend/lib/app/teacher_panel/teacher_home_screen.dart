import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../academe_theme.dart';
import '../../api_endpoints.dart';
import '../../app/auth/auth_service.dart';

class TeacherHomeScreen extends StatefulWidget {
  final Function() onProfileTap;
  final Function() onContentTap;
  final int selectedIndex;

  const TeacherHomeScreen({
    super.key,
    required this.onProfileTap,
    required this.onContentTap,
    required this.selectedIndex,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  Map<String, dynamic>? teacherProfile;
  List<dynamic> upcomingClasses = [];
  List<String> allottedClasses = [];
  bool isLoading = true;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    try {
      await Future.wait([
        _loadProfile(),
        _loadUpcomingClasses(),
        _loadAllottedClasses(),
      ]);
    } catch (e) {
      print('Error loading teacher data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
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
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadUpcomingClasses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherUpcomingClasses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          upcomingClasses = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading upcoming classes: $e');
    }
  }

  Future<void> _loadAllottedClasses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherAllottedClasses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allottedClasses = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error loading allotted classes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Teacher Dashboard'),
          backgroundColor: AcademeTheme.appColor,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: AcademeTheme.appColor,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        backgroundColor: AcademeTheme.appColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadTeacherData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTeacherData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              SizedBox(height: 16),
              _buildStatsCards(),
              SizedBox(height: 16),
              _buildUpcomingClasses(),
              SizedBox(height: 16),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AcademeTheme.appColor,
              backgroundImage: teacherProfile?['photo_url'] != null
                  ? NetworkImage(teacherProfile!['photo_url'])
                  : null,
              child: teacherProfile?['photo_url'] == null
                  ? Icon(Icons.person, color: Colors.white, size: 30)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back,',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    teacherProfile?['name'] ?? 'Teacher',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  if (teacherProfile?['subject'] != null)
                    Text(
                      teacherProfile!['subject'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = teacherProfile?['stats'] ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Classes Allotted',
            allottedClasses.length.toString(),
            Icons.class_,
            Colors.blue,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Upcoming Classes',
            upcomingClasses.length.toString(),
            Icons.schedule,
            Colors.orange,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total Students',
            (stats['total_students'] ?? 0).toString(),
            Icons.people,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
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
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingClasses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Classes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AcademeTheme.appColor,
          ),
        ),
        SizedBox(height: 8),
        if (upcomingClasses.isEmpty)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No upcoming classes scheduled',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ...upcomingClasses
              .take(3)
              .map((classData) => _buildClassCard(classData)),
        if (upcomingClasses.length > 3)
          TextButton(
            onPressed: () {
              // Navigate to full upcoming classes list
            },
            child: Text('View All Upcoming Classes'),
          ),
      ],
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AcademeTheme.appColor,
          child: Icon(Icons.video_call, color: Colors.white),
        ),
        title: Text(
          classData['title'] ?? 'Class',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(classData['class_name'] ?? ''),
            Text(
              _formatDateTime(classData['scheduled_time']),
              style: TextStyle(color: AcademeTheme.appColor, fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigate to class details
        },
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AcademeTheme.appColor,
          ),
        ),
        SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            _buildActionCard(
              'Upload Content',
              Icons.upload_file,
              Colors.purple,
              widget.onContentTap,
            ),
            _buildActionCard(
              'Schedule Class',
              Icons.add_circle,
              Colors.blue,
              () {
                // Navigate to schedule class
              },
            ),
            _buildActionCard(
              'View Students',
              Icons.people_outline,
              Colors.green,
              () {
                // Navigate to student management
              },
            ),
            _buildActionCard(
              'Update Profile',
              Icons.person_outline,
              Colors.orange,
              widget.onProfileTap,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
