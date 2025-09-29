import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:provider/provider.dart';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../../../localization/l10n.dart';
import '../../../localization/language_provider.dart';

class TeacherContent extends StatefulWidget {
  const TeacherContent({super.key});

  @override
  TeacherContentState createState() => TeacherContentState();
}

class TeacherContentState extends State<TeacherContent>
    with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  late TabController _tabController;
  bool isLoading = true;

  // Data storage
  List<Map<String, dynamic>> teacherCourses = [];
  List<Map<String, dynamic>> teacherTopics = [];
  List<Map<String, dynamic>> teacherMaterials = [];

  String? selectedCourseId;
  String? selectedTopicId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTeacherCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeacherCourses() async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherCourses),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          teacherCourses = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch teacher courses: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching teacher courses: $e");
    }
  }

  Future<void> _fetchTeacherTopics(String courseId) async {
    setState(() => isLoading = true);
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherCourseTopics(courseId)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          teacherTopics = data.cast<Map<String, dynamic>>();
          selectedCourseId = courseId;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching teacher topics: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> _fetchTeacherMaterials(String courseId, String topicId) async {
    setState(() => isLoading = true);
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(
            ApiEndpoints.teacherTopicMaterials(courseId, topicId)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          teacherMaterials = data.cast<Map<String, dynamic>>();
          selectedTopicId = topicId;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching teacher materials: $e");
    }
    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  void _addTeacherCourse() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();
        final TextEditingController classController = TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Create Teacher Course')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Course Title')),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Description')),
                maxLines: 3,
              ),
              TextField(
                controller: classController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Class Name')),
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
                await _submitTeacherCourse(
                  title: titleController.text,
                  description: descriptionController.text,
                  className: classController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(L10n.getTranslatedText(context, 'Create')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTeacherCourse({
    required String title,
    required String description,
    required String className,
  }) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.teacherCoursesCreate),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "title": title,
          "description": description,
          "class_name": className,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchTeacherCourses(); // Refresh the list
      } else {
        _showError("Failed to create course");
      }
    } catch (e) {
      _showError("Error creating course: $e");
    }
  }

  void _addTeacherTopic() {
    if (selectedCourseId == null) {
      _showError("Please select a course first");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();

        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Add Teacher Topic')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                    labelText: L10n.getTranslatedText(context, 'Topic Title')),
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
                await _submitTeacherTopic(
                  title: titleController.text,
                  description: descriptionController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: Text(L10n.getTranslatedText(context, 'Add')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitTeacherTopic({
    required String title,
    required String description,
  }) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.post(
        ApiEndpoints.getUri(
            ApiEndpoints.teacherCourseTopicsCreate(selectedCourseId!)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "title": title,
          "description": description,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchTeacherTopics(selectedCourseId!); // Refresh the list
      } else {
        _showError("Failed to add topic");
      }
    } catch (e) {
      _showError("Error adding topic: $e");
    }
  }

  void _addTeacherMaterial() {
    if (selectedCourseId == null || selectedTopicId == null) {
      _showError("Please select a course and topic first");
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        String? selectedType;
        String? category;
        String? filePath;
        String? textContent;
        String? optionalText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  L10n.getTranslatedText(context, 'Add Teacher Material')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          labelText: L10n.getTranslatedText(context, 'Type')),
                      items: ["text", "video", "image", "audio", "document"]
                          .map((type) =>
                          DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedType = value ?? ""),
                    ),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          labelText: L10n.getTranslatedText(
                              context, 'Category')),
                      items: [
                        "Teacher Notes",
                        "Assignments",
                        "Resources",
                        "Extra Practice"
                      ]
                          .map((type) =>
                          DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => category = value ?? ""),
                    ),
                    if (selectedType == "text") ...[
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(labelText: "Text Content"),
                        onChanged: (value) =>
                            setDialogState(() => textContent = value),
                        maxLines: 4,
                      ),
                    ],
                    if (selectedType != null && selectedType != "text") ...[
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () async {
                          FilePickerResult? result =
                          await FilePicker.platform.pickFiles();
                          if (result != null &&
                              result.files.single.path != null) {
                            setDialogState(() {
                              filePath = result.files.single.path!;
                            });
                          }
                        },
                        icon: Icon(Icons.attach_file),
                        label: Text(L10n.getTranslatedText(
                            context, 'Attach File')),
                      ),
                      if (filePath != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text("Selected: ${filePath!.split('/').last}"),
                        ),
                    ],
                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                          labelText: L10n.getTranslatedText(
                              context, 'Optional Text')),
                      onChanged: (value) =>
                          setDialogState(() => optionalText = value),
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
                    if (selectedType != null && category != null) {
                      await _uploadTeacherMaterial(
                        type: selectedType!,
                        category: category!,
                        optionalText: optionalText,
                        textContent: textContent,
                        filePath: filePath,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    } else {
                      _showError("Please fill all required fields");
                    }
                  },
                  child: Text(L10n.getTranslatedText(context, 'Upload')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadTeacherMaterial({
    required String type,
    required String category,
    String? optionalText,
    String? textContent,
    String? filePath,
  }) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      var request = http.MultipartRequest(
        "POST",
        ApiEndpoints.getUri(ApiEndpoints.teacherTopicMaterialsCreate(
            selectedCourseId!, selectedTopicId!)),
      );

      request.headers["Authorization"] = "Bearer $token";
      request.fields["type"] = type;
      request.fields["category"] = category;

      if (optionalText != null) {
        request.fields["optional_text"] = optionalText;
      }

      if (type == "text" && textContent != null) {
        request.fields["text_content"] = textContent;
      } else if (filePath != null) {
        String mimeType = _getMimeType(filePath);
        request.files.add(
          await http.MultipartFile.fromPath(
            "file",
            filePath,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchTeacherMaterials(selectedCourseId!, selectedTopicId!);
      } else {
        _showError("Failed to upload material");
      }
    } catch (e) {
      _showError("Error uploading material: $e");
    }
  }

  String _getMimeType(String filePath) {
    final extension = filePath
        .split('.')
        .last
        .toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Widget _buildCoursesTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _addTeacherCourse,
            icon: Icon(Icons.add),
            label: Text(L10n.getTranslatedText(context, 'Create New Course')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: teacherCourses.isEmpty
              ? Center(
              child: Text(
                  L10n.getTranslatedText(context, 'No courses created yet')))
              : ListView.builder(
            itemCount: teacherCourses.length,
            itemBuilder: (context, index) {
              final course = teacherCourses[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(course["title"] ?? "Unknown Course"),
                  subtitle: Text(course["description"] ?? "No description"),
                  trailing: Text("Class ${course["class_name"] ?? "N/A"}"),
                  onTap: () {
                    _fetchTeacherTopics(course["id"]);
                    _tabController.animateTo(1);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsTab() {
    return Column(
      children: [
        if (selectedCourseId != null) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addTeacherTopic,
              icon: Icon(Icons.add),
              label: Text(L10n.getTranslatedText(context, 'Add New Topic')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcademeTheme.appColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        Expanded(
          child: selectedCourseId == null
              ? Center(
              child: Text(
                  L10n.getTranslatedText(context, 'Select a course first')))
              : teacherTopics.isEmpty
              ? Center(
              child: Text(
                  L10n.getTranslatedText(context, 'No topics created yet')))
              : ListView.builder(
            itemCount: teacherTopics.length,
            itemBuilder: (context, index) {
              final topic = teacherTopics[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(topic["title"] ?? "Unknown Topic"),
                  subtitle: Text(topic["description"] ?? "No description"),
                  onTap: () {
                    _fetchTeacherMaterials(selectedCourseId!, topic["id"]);
                    _tabController.animateTo(2);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsTab() {
    return Column(
      children: [
        if (selectedTopicId != null) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _addTeacherMaterial,
              icon: Icon(Icons.add),
              label: Text(L10n.getTranslatedText(context, 'Add New Material')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcademeTheme.appColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        Expanded(
          child: selectedTopicId == null
              ? Center(
              child: Text(
                  L10n.getTranslatedText(context, 'Select a topic first')))
              : teacherMaterials.isEmpty
              ? Center(
              child: Text(
                  L10n.getTranslatedText(context, 'No materials uploaded yet')))
              : ListView.builder(
            itemCount: teacherMaterials.length,
            itemBuilder: (context, index) {
              final material = teacherMaterials[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(_getTypeIcon(material["type"])),
                  title: Text(material["type"]?.toUpperCase() ?? "UNKNOWN"),
                  subtitle: Text(material["category"] ?? "No category"),
                  trailing: Icon(Icons.open_in_new),
                  onTap: () {
                    // Navigate to material view
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'video':
        return Icons.video_library;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'document':
        return Icons.description;
      case 'text':
      default:
        return Icons.text_snippet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        labelColor: AcademeTheme.appColor,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(text: L10n.getTranslatedText(context, 'Courses')),
          Tab(text: L10n.getTranslatedText(context, 'Topics')),
          Tab(text: L10n.getTranslatedText(context, 'Materials')),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildCoursesTab(),
          _buildTopicsTab(),
          _buildMaterialsTab(),
        ],
      ),
    );
  }
}
