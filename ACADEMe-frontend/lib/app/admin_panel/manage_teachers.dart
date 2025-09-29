import 'dart:convert';
import 'package:ACADEMe/app/admin_panel/teacher_details.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../academe_theme.dart';
import '../../api_endpoints.dart';
import '../../localization/l10n.dart';

class ManageTeachersTab extends StatefulWidget {
  const ManageTeachersTab({super.key});

  @override
  ManageTeachersTabState createState() => ManageTeachersTabState();
}

class ManageTeachersTabState extends State<ManageTeachersTab>
    with SingleTickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  late TabController _tabController;

  List<Map<String, dynamic>> teachers = [];
  List<Map<String, dynamic>> adminEmails = [];
  bool isLoading = false;

  // Analytics data
  Map<String, dynamic> teacherStats = {};
  List<Map<String, dynamic>> classAnalytics = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => isLoading = true);
    await Future.wait([
      _loadTeachers(),
      _loadAdminEmails(),
      _loadTeacherAnalytics(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> _loadTeachers() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      debugPrint("No token found");
      return;
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri('${ApiEndpoints.baseUrl}/api/admin/teachers/all'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
          "accept": "application/json",
        },
      );

      debugPrint("Teachers API Response Status: ${response.statusCode}");
      debugPrint("Teachers API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // ✅ Parse the response as a Map first
        Map<String, dynamic> responseData = json.decode(utf8.decode(response.bodyBytes));

        // ✅ Extract the teachers list from the response
        List<dynamic> teachersData = responseData['teachers'] ?? [];

        debugPrint("Loaded ${teachersData.length} teachers");
        setState(() {
          teachers = teachersData.map((item) {
            // ✅ Transform the API response to match your expected structure
            return {
              'id': item['teacher_id'],
              'name': item['name'],
              'email': item['email'],
              'subject': item['subject'],
              'bio': item['bio'],
              'allotted_classes': item['allotted_classes'],
              'is_active': item['is_active'],
              'created_at': item['created_at'],
              // Include any other fields you need
            };
          }).toList();
        });
      } else {
        debugPrint("Failed to load teachers: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error loading teachers: $e");
    }
  }


  Future<void> _loadAdminEmails() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.adminEmails),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          adminEmails = data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading admin emails: $e");
    }
  }

  Future<void> _loadTeacherAnalytics() async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      // Load teacher statistics
      final statsResponse = await http.get(
        ApiEndpoints.getUri('${ApiEndpoints.baseUrl}/api/admin/teachers/stats'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (statsResponse.statusCode == 200) {
        setState(() {
          teacherStats = json.decode(utf8.decode(statsResponse.bodyBytes));
        });
      }

      // Load class analytics for all teachers
      final analyticsResponse = await http.get(
        ApiEndpoints.getUri('${ApiEndpoints.baseUrl}/api/admin/teachers/analytics'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (analyticsResponse.statusCode == 200) {
        List<dynamic> data = json.decode(utf8.decode(analyticsResponse.bodyBytes));
        setState(() {
          classAnalytics = data.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading teacher analytics: $e");
    }
  }

  void _showAddTeacherDialog() {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController subjectController = TextEditingController(); // ✅ added
    final TextEditingController bioController = TextEditingController();
    List<String> selectedClasses = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Add Teacher')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Name'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController, // ✅ subject input
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Subject'),
                        prefixIcon: const Icon(Icons.book),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Bio'),
                        prefixIcon: const Icon(Icons.info),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.getTranslatedText(context, 'Allotted Classes'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: ['5', '6', '7', '8', '9', '10', '11', '12']
                          .map((className) => FilterChip(
                        label: Text('Class $className'),
                        selected: selectedClasses.contains(className),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedClasses.add(className);
                            } else {
                              selectedClasses.remove(className);
                            }
                          });
                        },
                      ))
                          .toList(),
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
                    await _addTeacher(
                      emailController.text,
                      nameController.text,
                      subjectController.text, // ✅ now passing subject
                      bioController.text,
                      selectedClasses,
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
      },
    );
  }


  Future<void> _addTeacher(
      String email, String name, String subject, String bio, List<String> classes) async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      final response = await http.post(
        ApiEndpoints.getUri('${ApiEndpoints.baseUrl}/api/admin/teachers/add'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "email": email,
          "name": name,
          "subject": subject,   // ✅ Added this
          "bio": bio,
          "allotted_classes": classes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Teacher added successfully')),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData();
      } else {
        throw Exception('Failed to add teacher: ${response.body}');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              L10n.getTranslatedText(context, 'Failed to add teacher: $e')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Future<void> _removeTeacher(String email, {String reason = ""}) async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.removeTeacher),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: jsonEncode({
          "email": email,   // must be a valid email, not an ID
          "reason": reason,
        }),
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(context, 'Teacher removed successfully')),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Failed to remove teacher')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  void _showEditTeacherDialog(Map<String, dynamic> teacher) {
    final TextEditingController emailController =
    TextEditingController(text: teacher['email'] ?? '');
    final TextEditingController nameController =
    TextEditingController(text: teacher['name'] ?? '');
    final TextEditingController subjectController =
    TextEditingController(text: teacher['subject'] ?? '');
    final TextEditingController bioController =
    TextEditingController(text: teacher['bio'] ?? '');
    List<String> selectedClasses =
    List<String>.from(teacher['allotted_classes'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Edit Teacher')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Email'),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      enabled: false, // Email shouldn't be editable
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Name'),
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Subject'),
                        prefixIcon: const Icon(Icons.book),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: bioController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Bio'),
                        prefixIcon: const Icon(Icons.info),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      L10n.getTranslatedText(context, 'Allotted Classes'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: ['5', '6', '7', '8', '9', '10', '11', '12']
                          .map((className) => FilterChip(
                        label: Text('Class $className'),
                        selected: selectedClasses.contains(className),
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedClasses.add(className);
                            } else {
                              selectedClasses.remove(className);
                            }
                          });
                        },
                      ))
                          .toList(),
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
                    await _updateTeacher(
                      emailController.text,         // ✅ pass email
                      nameController.text,
                      subjectController.text,       // ✅ new subject
                      bioController.text,
                      selectedClasses,
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
      },
    );
  }


  Future<void> _updateTeacher(
      String email,
      String name,
      String subject,
      String bio,
      List<String> classes,
      ) async {
    String? token = await _storage.read(key: "access_token");
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoints.baseUrl}/api/admin/teachers/update'),
        headers: {
          "Authorization": "Bearer $token",
          "accept": "application/json",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "email": email,               // ✅ required
          "name": name,
          "subject": subject,           // ✅ required
          "allotted_classes": classes,
          "bio": bio,
        }),
      );

      if (response.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(context, 'Teacher updated successfully')),
            backgroundColor: Colors.green,
          ),
        );
        _loadInitialData();
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(context, 'Failed to update teacher')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  Widget _buildTeachersTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                L10n.getTranslatedText(context, 'Teachers List'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddTeacherDialog,
                icon: const Icon(Icons.add),
                label: Text(L10n.getTranslatedText(context, 'Add Teacher')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AcademeTheme.appColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: teachers.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    L10n.getTranslatedText(context, 'No teachers found'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.white,
                  child: InkWell(
                    onTap: () {
                      // Navigate to Teacher Details Screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeacherDetailsScreen(teacher: teacher),
                        ),
                      );
                    },
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: AcademeTheme.appColor,
                        child: Text(
                          (teacher['name'] ?? 'T').substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        teacher['name'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher['email'] ?? ''),
                          if (teacher['allotted_classes'] != null)
                            Text(
                              'Classes: ${(teacher['allotted_classes'] as List).join(', ')}',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 18),
                                const SizedBox(width: 8),
                                Text(L10n.getTranslatedText(context, 'Edit')),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(Icons.delete,
                                    size: 18, color: Colors.red),
                                const SizedBox(width: 8),
                                Text(
                                  L10n.getTranslatedText(context, 'Remove'),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditTeacherDialog(teacher);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(teacher);
                          }
                        },
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (teacher['bio'] != null &&
                                  teacher['bio'].isNotEmpty)
                                Text(
                                  'Bio: ${teacher['bio']}',
                                  style: const TextStyle(fontStyle: FontStyle.italic),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.access_time,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Active: ${teacher['is_active'] ?? false ? 'Yes' : 'No'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              if (teacher['created_at'] != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Added: ${teacher['created_at']}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> teacher) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.getTranslatedText(context, 'Confirm Deletion')),
        content: Text(
          '${L10n.getTranslatedText(context, 'Are you sure you want to remove')} ${teacher['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeTeacher(teacher['email'].toString());  // ✅ Correct
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              L10n.getTranslatedText(context, 'Remove'),
              style: const TextStyle(color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    // Directly return the Teachers screen
    return _buildTeachersTab();
  }

}