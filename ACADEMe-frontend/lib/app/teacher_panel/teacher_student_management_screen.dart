import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../auth/auth_service.dart';

class TeacherStudentManagementScreen extends StatefulWidget {
  const TeacherStudentManagementScreen({super.key});

  @override
  State<TeacherStudentManagementScreen> createState() => _TeacherStudentManagementScreenState();
}

class _TeacherStudentManagementScreenState extends State<TeacherStudentManagementScreen> {
  List<String> allottedClasses = [];
  Map<String, List<dynamic>> classStudents = {};
  Map<String, Map<String, dynamic>> classAnalytics = {};
  bool isLoading = true;
  String? selectedClass;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadAllottedClasses();
  }

  Future<void> _loadAllottedClasses() async {
    setState(() {
      isLoading = true;
    });

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
        final classes = List<String>.from(json.decode(response.body));
        setState(() {
          allottedClasses = classes;
        });

        // Load analytics for all classes
        await _loadAllClassAnalytics();
      }
    } catch (e) {
      print('Error loading allotted classes: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllClassAnalytics() async {
    for (String className in allottedClasses) {
      await _loadClassAnalytics(className);
    }
  }

  Future<void> _loadClassAnalytics(String className) async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.classAnalytics(className)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          classAnalytics[className] = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading analytics for $className: $e');
    }
  }

  Future<void> _loadStudentsForClass(String className) async {
    if (classStudents[className] != null) return; // Already loaded

    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.studentsByClass(className)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          classStudents[className] = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading students for $className: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Student Management'),
          backgroundColor: AcademeTheme.appColor,
        ),
        body: Center(
          child: CircularProgressIndicator(color: AcademeTheme.appColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Management'),
        backgroundColor: AcademeTheme.appColor,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAllottedClasses,
          ),
        ],
      ),
      body: selectedClass == null ? _buildClassListView() : _buildStudentListView(),
    );
  }

  Widget _buildClassListView() {
    if (allottedClasses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'No Classes Assigned',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'You have not been assigned to any classes yet',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllottedClasses,
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Your Assigned Classes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AcademeTheme.appColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap on any class to view students and their progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          ...allottedClasses.map((className) => _buildClassCard(className)),
        ],
      ),
    );
  }

  Widget _buildClassCard(String className) {
    final analytics = classAnalytics[className];
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _selectClass(className),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AcademeTheme.appColor,
                    child: Text(
                      className.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          className,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AcademeTheme.appColor,
                          ),
                        ),
                        if (analytics != null)
                          Text(
                            '${analytics['total_students'] ?? 0} students',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (analytics != null) ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Students',
                        (analytics['total_students'] ?? 0).toString(),
                        Icons.people,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Active Students',
                        (analytics['active_students'] ?? 0).toString(),
                        Icons.people_alt,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Avg Progress',
                        '${(analytics['avg_progress'] ?? 0).toStringAsFixed(1)}%',
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Completion Rate',
                        '${(analytics['completion_rate'] ?? 0).toStringAsFixed(1)}%',
                        Icons.check_circle,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentListView() {
    final students = classStudents[selectedClass] ?? [];
    
    return Column(
      children: [
        // Header with back button and class info
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AcademeTheme.appColor.withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => setState(() => selectedClass = null),
                icon: Icon(Icons.arrow_back),
                color: AcademeTheme.appColor,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedClass!,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AcademeTheme.appColor,
                      ),
                    ),
                    Text(
                      '${students.length} students',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showClassProgressSummary(),
                icon: Icon(Icons.analytics),
                color: AcademeTheme.appColor,
                tooltip: 'View Class Analytics',
              ),
            ],
          ),
        ),
        // Students list
        Expanded(
          child: students.isEmpty
              ? _buildEmptyStudentsState()
              : RefreshIndicator(
                  onRefresh: () => _refreshStudents(),
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return _buildStudentCard(student);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyStudentsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Students Found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'No students are enrolled in this class yet',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewStudentDetails(student),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AcademeTheme.appColor.withOpacity(0.1),
                backgroundImage: student['photo_url'] != null 
                    ? NetworkImage(student['photo_url']) 
                    : null,
                child: student['photo_url'] == null 
                    ? Icon(Icons.person, color: AcademeTheme.appColor, size: 25)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] ?? 'Unknown Student',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      student['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (student['last_active'] != null)
                      Text(
                        'Last active: ${_formatDateTime(student['last_active'])}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProgressColor(student['progress'] ?? 0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(student['progress'] ?? 0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: _getProgressColor(student['progress'] ?? 0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.yellow[800]!;
    return Colors.red;
  }

  void _selectClass(String className) {
    setState(() {
      selectedClass = className;
    });
    _loadStudentsForClass(className);
  }

  Future<void> _refreshStudents() async {
    if (selectedClass != null) {
      classStudents.remove(selectedClass);
      await _loadStudentsForClass(selectedClass!);
      await _loadClassAnalytics(selectedClass!);
    }
  }

  void _viewStudentDetails(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentDetailScreen(
          student: student,
          className: selectedClass!,
        ),
      ),
    );
  }

  void _showClassProgressSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassProgressSummaryScreen(
          className: selectedClass!,
        ),
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Never';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Student Detail Screen
class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final String className;
  

  const StudentDetailScreen({
    Key? key,
    required this.student,
    required this.className,
  }) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Map<String, dynamic>? progressData;
  bool isLoading = true;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadStudentProgress();
  }

  Future<void> _loadStudentProgress() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse('${ApiEndpoints.teacherClassProgress(widget.className)}?student_id=${widget.student['id']}&include_visuals=true'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          progressData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading student progress: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student['name'] ?? 'Student Details'),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AcademeTheme.appColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStudentHeader(),
                  SizedBox(height: 24),
                  _buildProgressOverview(),
                  SizedBox(height: 24),
                  _buildDetailedStats(),
                  SizedBox(height: 24),
                  _buildRecentActivity(),
                ],
              ),
            ),
    );
  }

  Widget _buildStudentHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AcademeTheme.appColor.withOpacity(0.1),
              backgroundImage: widget.student['photo_url'] != null 
                  ? NetworkImage(widget.student['photo_url']) 
                  : null,
              child: widget.student['photo_url'] == null 
                  ? Icon(Icons.person, color: AcademeTheme.appColor, size: 40)
                  : null,
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student['name'] ?? 'Unknown Student',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.student['email'] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Class: ${widget.className}',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverview() {
    final progress = widget.student['progress'] ?? 0.0;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Progress',
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
                  child: Column(
                    children: [
                      Text(
                        '${progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _getProgressColor(progress),
                        ),
                      ),
                      Text('Complete'),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation(_getProgressColor(progress)),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats() {
    if (progressData == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Detailed statistics will be shown here'),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            // Add more detailed stats based on progressData
            Text('Quiz Scores: Coming soon'),
            Text('Time Spent: Coming soon'),
            Text('Topics Completed: Coming soon'),
            Text('Assignments Submitted: Coming soon'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 16),
            Text('Recent activity data will be shown here'),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 60) return Colors.orange;
    if (progress >= 40) return Colors.yellow[800]!;
    return Colors.red;
  }
}

// Class Progress Summary Screen
class ClassProgressSummaryScreen extends StatefulWidget {
  final String className;

  const ClassProgressSummaryScreen({
    Key? key,
    required this.className,
  }) : super(key: key);

  @override
  State<ClassProgressSummaryScreen> createState() => _ClassProgressSummaryScreenState();
}

class _ClassProgressSummaryScreenState extends State<ClassProgressSummaryScreen> {
  Map<String, dynamic>? summaryData;
  bool isLoading = true;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadProgressSummary();
  }

  Future<void> _loadProgressSummary() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherClassProgressSummary(widget.className)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          summaryData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading progress summary: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.className} - Analytics'),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AcademeTheme.appColor))
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Class analytics and visual data will be displayed here',
                    style: TextStyle(fontSize: 16),
                  ),
                  // Add charts and analytics here based on summaryData
                ],
              ),
            ),
    );
  }
}