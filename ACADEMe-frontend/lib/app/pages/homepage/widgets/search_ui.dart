// Modified SearchUI with fixed search logic
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../localization/l10n.dart';
import '../../courses/controllers/course_controller.dart';
import 'dart:developer';
import '../../topics/screens/topic_view_screen.dart';

class SearchUI extends StatefulWidget {
  final ValueNotifier<bool> showSearchUI;
  final List<Map<String, dynamic>> allCourses; // Changed to work with Map data

  const SearchUI({
    super.key,
    required this.showSearchUI,
    required this.allCourses,
  });

  @override
  State<SearchUI> createState() => _SearchUIState();
}

class _SearchUIState extends State<SearchUI> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Only allow these specific subjects
  final List<String> _allowedSubjects = [
    'mathematics',
    'english',
    'environmental science',
    'hindi'
  ];



  List<Map<String, dynamic>> get _filteredCourses {
    if (_searchQuery.isEmpty) {
      return [];
    }

    final normalizedQuery = _searchQuery.toLowerCase().trim();

    return widget.allCourses.where((course) {
      final courseTitle = (course['title'] ?? '').toString().toLowerCase();

      // First check for exact subject matches
      if (_allowedSubjects.contains(normalizedQuery)) {
        // For exact subject match, return only courses that contain that exact subject
        return courseTitle.contains(normalizedQuery);
      }

      // For partial matches, require that:
      // 1. The course title contains the search query
      // 2. The course belongs to an allowed subject
      return courseTitle.contains(normalizedQuery) &&
          _allowedSubjects.any((subject) => courseTitle.contains(subject));
    }).toList();
  }


  // Function for module progress text using Map data
  Future<String> getModuleProgressText(String courseId, BuildContext context) async {
    final course = widget.allCourses.firstWhere(
          (c) => c['id'].toString() == courseId,
      orElse: () => <String, dynamic>{},
    );

    if (course.isNotEmpty && course['completedModules'] != null && course['totalModules'] != null) {
      return "${course['completedModules']}/${course['totalModules']} ${L10n.getTranslatedText(context, 'Modules')}";
    } else {
      return "0/0 ${L10n.getTranslatedText(context, 'Modules')}";
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        widget.showSearchUI.value = false;
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
        return false;
      },
      child: GestureDetector(
        onTap: () {
          widget.showSearchUI.value = false;
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ));
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "${L10n.getTranslatedText(context, 'Search')}...",
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Show Popular Searches only when search is empty
                        if (_searchQuery.isEmpty) ...[
                          Text(
                            L10n.getTranslatedText(context, 'Popular Searches'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            children: [
                              ActionChip(
                                label: const Text('Mathematics'),
                                onPressed: () {
                                  _searchController.text = 'Mathematics';
                                  setState(() {
                                    _searchQuery = 'Mathematics';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('English'),
                                onPressed: () {
                                  _searchController.text = 'English';
                                  setState(() {
                                    _searchQuery = 'English';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('Environmental Science'),
                                onPressed: () {
                                  _searchController.text = 'Environmental Science';
                                  setState(() {
                                    _searchQuery = 'Environmental Science';
                                  });
                                },
                              ),
                              ActionChip(
                                label: const Text('Hindi'),
                                onPressed: () {
                                  _searchController.text = 'Hindi';
                                  setState(() {
                                    _searchQuery = 'Hindi';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Search Results Section
                        if (_searchQuery.isNotEmpty) ...[
                          Text(
                            'Results for "$_searchQuery"',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),

                          // Show results or no results message
                          if (_filteredCourses.isEmpty) ...[
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(
                                    Icons.search_off_sharp,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    L10n.getTranslatedText(context, 'No results found'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Use CourseCardMap for displaying results
                            Column(
                              children: _filteredCourses.map((course) =>
                                  CourseCardMap(
                                    courseData: course,
                                    getModuleProgressText: getModuleProgressText,
                                  )
                              ).toList(),
                            ),
                          ],
                        ],

                        // Show Recent Searches only when search is empty
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            L10n.getTranslatedText(context, 'Searches For You'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Mathematics'),
                            onTap: () {
                              _searchController.text = 'Mathematics';
                              setState(() {
                                _searchQuery = 'Mathematics';
                              });
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Environmental Science'),
                            onTap: () {
                              _searchController.text = 'Environmental Science';
                              setState(() {
                                _searchQuery = 'Environmental Science';
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CourseCard modified to work with Map data
class CourseCardMap extends StatelessWidget {
  final Map<String, dynamic> courseData;
  final Future<String> Function(String courseId, BuildContext context)
  getModuleProgressText;

  const CourseCardMap({
    super.key,
    required this.courseData,
    required this.getModuleProgressText,
  });

  @override
  Widget build(BuildContext context) {
    final String courseId = courseData['id'].toString();
    final String courseTitle = courseData['title'] ?? 'Untitled Course';
    final double progress = (courseData['progress'] ?? 0.0).toDouble();

    return GestureDetector(
      onTap: () async {
        log("Selected Course ID: $courseId");

        try {
          final controller =
          Provider.of<CourseController>(context, listen: false);
          await controller.selectCourse(courseId);

          if (!context.mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicViewScreen(
                courseId: courseId,
                courseTitle: courseTitle,
              ),
            ),
          );
        } catch (error) {
          log("Error storing course ID: $error");
        }
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    courseTitle,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width *
                            (progress.clamp(0.0, 1.0)),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: getModuleProgressText(courseId, context),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ??
                                  "0/0 ${L10n.getTranslatedText(context, 'Modules')}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(progress.clamp(0.0, 1.0) * 100).toInt()}%",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}