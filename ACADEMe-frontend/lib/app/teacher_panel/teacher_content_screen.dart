import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../auth/auth_service.dart';

class TeacherContentScreen extends StatefulWidget {
  const TeacherContentScreen({super.key});

  @override
  State<TeacherContentScreen> createState() => _TeacherContentScreenState();
}

class _TeacherContentScreenState extends State<TeacherContentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> teacherCourses = [];
  List<dynamic> studyMaterials = [];
  bool isLoading = true;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadTeacherCourses(),
        _loadStudyMaterials(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTeacherCourses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherCourses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          teacherCourses = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading teacher courses: $e');
    }
  }

  Future<void> _loadStudyMaterials() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.courses('en')),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          studyMaterials = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading study materials: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Content Management'),
          backgroundColor: AcademeTheme.appColor,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "My Content"),
              Tab(text: "Self Study Material"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildMyContentTab(),
            _buildStudyMaterialTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _showCreateCourseDialog,
                backgroundColor: AcademeTheme.appColor,
                icon: Icon(Icons.add),
                label: Text('Create Course'),
              )
            : null,
      ),
    );
  }

  Widget _buildMyContentTab() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTeacherCourses,
      child: teacherCourses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: teacherCourses.length,
              itemBuilder: (context, index) {
                final course = teacherCourses[index];
                return _buildCourseCard(course);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.upload_file,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Content Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Create your first course to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showCreateCourseDialog,
            icon: Icon(Icons.add),
            label: Text('Create Course'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? 'Untitled Course',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AcademeTheme.appColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Class: ${course['class_name'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'add_topic') {
                      _showAddTopicDialog(course['id']);
                    } else if (value == 'edit') {
                      _showEditCourseDialog(course);
                    } else if (value == 'delete') {
                      _showDeleteCourseDialog(course['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'add_topic', child: Text('Add Topic')),
                    PopupMenuItem(value: 'edit', child: Text('Edit Course')),
                    PopupMenuItem(value: 'delete', child: Text('Delete Course')),
                  ],
                ),
              ],
            ),
            if (course['description'] != null && course['description'].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  course['description'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Created: ${_formatDate(course['created_at'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _navigateToTopics(course),
                  icon: Icon(Icons.folder_open, size: 16),
                  label: Text('View Topics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcademeTheme.appColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyMaterialTab() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudyMaterials,
      child: studyMaterials.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 20),
                  Text(
                    'No Study Materials Available',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: studyMaterials.length,
              itemBuilder: (context, index) {
                final material = studyMaterials[index];
                return _buildStudyMaterialCard(material);
              },
            ),
    );
  }

  Widget _buildStudyMaterialCard(Map<String, dynamic> material) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AcademeTheme.appColor.withOpacity(0.1),
          child: Icon(
            Icons.menu_book,
            color: AcademeTheme.appColor,
          ),
        ),
        title: Text(
          material['title'] ?? 'Untitled',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          material['description'] ?? 'No description',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToMaterial(material),
      ),
    );
  }

  void _showCreateCourseDialog() {
    final titleController = TextEditingController();
    final classController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Course Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: classController,
              decoration: InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createCourse(
              titleController.text,
              classController.text,
              descriptionController.text,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCourse(String title, String className, String description) async {
    if (title.trim().isEmpty || className.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    try {
      final token = await authService.getAccessToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.teacherCoursesCreate),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title.trim(),
          'class_name': className.trim(),
          'description': description.trim(),
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Course created successfully!')),
        );
        _loadTeacherCourses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create course')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showAddTopicDialog(String courseId) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Topic'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Topic Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _addTopic(courseId, titleController.text, descriptionController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AcademeTheme.appColor),
            child: Text('Add Topic'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTopic(String courseId, String title, String description) async {
    if (title.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a topic title')),
      );
      return;
    }

    try {
      final token = await authService.getAccessToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.teacherCourseTopicsCreate(courseId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'title': title.trim(),
          'description': description.trim(),
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Topic added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add topic')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showEditCourseDialog(Map<String, dynamic> course) {
    // Implementation for editing course
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit course feature coming soon!')),
    );
  }

  void _showDeleteCourseDialog(String courseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Course'),
        content: Text('Are you sure you want to delete this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCourse(courseId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourse(String courseId) async {
    // Implementation for deleting course
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Delete course feature coming soon!')),
    );
  }

  void _navigateToTopics(Map<String, dynamic> course) {
    // Navigate to course topics page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherCourseTopicsScreen(
          courseId: course['id'],
          courseTitle: course['title'],
        ),
      ),
    );
  }

  void _navigateToMaterial(Map<String, dynamic> material) {
    // Navigate to study material details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudyMaterialDetailScreen(
          materialId: material['id'],
          materialTitle: material['title'],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}

// Placeholder screens for navigation
class TeacherCourseTopicsScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const TeacherCourseTopicsScreen({
    Key? key,
    required this.courseId,
    required this.courseTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseTitle),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Center(
        child: Text('Course Topics Screen - Implementation needed'),
      ),
    );
  }
}

class StudyMaterialDetailScreen extends StatelessWidget {
  final String materialId;
  final String materialTitle;

  const StudyMaterialDetailScreen({
    Key? key,
    required this.materialId,
    required this.materialTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(materialTitle),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Center(
        child: Text('Study Material Detail Screen - Implementation needed'),
      ),
    );
  }
}