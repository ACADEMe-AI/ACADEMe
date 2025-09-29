import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../academe_theme.dart';
import '../../api_endpoints.dart';
import '../../localization/l10n.dart';
import 'manage_teachers.dart';
import 'topic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  CourseManagementScreenState createState() => CourseManagementScreenState();
}

class CourseManagementScreenState extends State<CourseManagementScreen> {
  List<Map<String, dynamic>> courses = [];
  final _storage = FlutterSecureStorage();
  String? _targetLanguage;
  bool isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _loadLanguageAndCourses();
  }

  Future<void> _loadLanguageAndCourses() async {
    // Fetch the app's language from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _targetLanguage =
        prefs.getString('language') ?? 'en'; // Default to 'en' if not set

    // Load courses after fetching the language
    _loadCourses();
  }

  void _loadCourses() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      debugPrint("No access token found");
      return;
    }

    final response = await http.get(
      ApiEndpoints.getUri(ApiEndpoints.courses(_targetLanguage!)),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type":
        "application/json; charset=UTF-8", // Ensure UTF-8 encoding
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data =
      json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
      setState(() {
        courses = data
            .map((item) => {
          "id": item["id"].toString(),
          "title": item["title"],
          "class_name": item["class_name"],
          "description": item["description"],
        })
            .toList();
      });
    } else {
      debugPrint("Failed to fetch courses: ${response.body}");
    }
  }

  void _addCourse() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController classController = TextEditingController();
        final TextEditingController descriptionController =
        TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Course')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Course Title')),
              ),
              TextField(
                controller: classController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Class Name')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                String? token = await _storage.read(key: "access_token");
                if (token == null) {
                  debugPrint("No access token found");
                  return;
                }

                final response = await http.post(
                  ApiEndpoints.getUri(ApiEndpoints.coursesNoLang),
                  headers: {
                    "Authorization": "Bearer $token",
                    "Content-Type":
                    "application/json; charset=UTF-8", // Ensure UTF-8 encoding
                  },
                  body: json.encode({
                    "title": titleController.text,
                    "class_name": classController.text,
                    "description": descriptionController.text,
                  }),
                );

                if (!context.mounted) {
                  return; // Now properly wrapped in a block
                }

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.pop(context);
                  setState(() {
                    _loadCourses();
                  });
                } else {
                  debugPrint("Failed to add course: ${response.body}");
                }
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  void _manageTeachers() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController emailController = TextEditingController();
        List<String> teacherEmails = [];

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Manage Teachers')),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText:
                        L10n.getTranslatedText(context, 'Teacher Email'),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            if (emailController.text.isNotEmpty) {
                              setDialogState(() {
                                teacherEmails.add(emailController.text);
                                emailController.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (teacherEmails.isNotEmpty)
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: teacherEmails.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(teacherEmails[index]),
                              trailing: IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setDialogState(() {
                                    teacherEmails.removeAt(index);
                                  });
                                },
                              ),
                            );
                          },
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
                    await _submitTeacherEmails(teacherEmails);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(L10n.getTranslatedText(context, 'Save')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitTeacherEmails(List<String> emails) async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      final response = await http.post(
        ApiEndpoints.getUri('/api/admin/teachers/manage'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({"teacher_emails": emails}),
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'Teachers updated successfully'))),
        );
      }
    } catch (e) {
      debugPrint("Error updating teachers: $e");
    }
  }

  void _navigateToTopics(String courseId, String courseTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TopicScreen(courseId: courseId, courseTitle: courseTitle),
      ),
    );
  }

  Widget _buildMenuItem(String label, IconData icon, VoidCallback onTap) {
    return FloatingActionButton.extended(
      heroTag: label, // unique tag to prevent hero conflicts
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      backgroundColor: AcademeTheme.appColor,
    );
  }


  // Updated main widget with tabs
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AcademeTheme.appColor,
          title: Text(
            L10n.getTranslatedText(context, 'Admin Panel'),
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          // ❌ remove TabBar from here
        ),
        body: Column(
          children: [
            // ✅ TabBar BELOW AppBar
            Material(
              color: Colors.white,
              child: TabBar(
                indicatorColor: AcademeTheme.appColor,
                labelColor: AcademeTheme.appColor,
                unselectedLabelColor: Colors.black38,
                tabs: [
                  Tab(
                    icon: Icon(Icons.book),
                    text:
                    L10n.getTranslatedText(context, 'Self Study Material'),
                  ),
                  Tab(
                    icon: Icon(Icons.school),
                    text:
                    L10n.getTranslatedText(context, 'Manage Teachers'),
                  ),
                ],
              ),
            ),
            // ✅ TabBarView takes the remaining space
            Expanded(
              child: TabBarView(
                children: [
                  // Self Study Material Tab
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              L10n.getTranslatedText(context, 'Course List'),
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          child: courses.isEmpty
                              ? Center(
                            child: CircularProgressIndicator(
                              color: AcademeTheme.appColor,
                            ),
                          )
                              : ListView(
                            children: courses
                                .map(
                                  (course) => Card(
                                color: Colors.white,
                                margin: EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  title: Text(course["title"]!),
                                  subtitle:
                                  Text(course["description"]!),
                                  onTap: () => _navigateToTopics(
                                      course["id"]!,
                                      course["title"]!),
                                ),
                              ),
                            )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Manage Teachers Tab
                  ManageTeachersTab(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isMenuOpen) ...[
              _buildMenuItem(
                L10n.getTranslatedText(context, 'Add Course'),
                Icons.add,
                _addCourse,
              ),
              SizedBox(height: 10),
            ],
            FloatingActionButton(
              onPressed: () => setState(() => isMenuOpen = !isMenuOpen),
              backgroundColor: AcademeTheme.appColor,
              child: Icon(
                isMenuOpen ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
