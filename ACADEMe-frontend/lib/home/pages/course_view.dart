import 'dart:convert';
import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/home/pages/ask_me.dart';
import 'package:ACADEMe/home/components/askme_button.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'topic_view.dart';

class CourseDataCache {
  static final CourseDataCache _instance = CourseDataCache._internal();
  factory CourseDataCache() => _instance;
  CourseDataCache._internal();

  List<Map<String, dynamic>>? _cachedCourses;
  String? _cachedLanguage;
  DateTime? _lastFetchTime;

  // Cache validity duration (30 minutes)
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  bool get isCacheValid {
    if (_lastFetchTime == null || _cachedCourses == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  List<Map<String, dynamic>>? getCachedCourses(String language) {
    if (_cachedLanguage == language && isCacheValid) {
      return _cachedCourses;
    }
    return null;
  }

  void setCachedCourses(List<Map<String, dynamic>> courses, String language) {
    _cachedCourses = courses;
    _cachedLanguage = language;
    _lastFetchTime = DateTime.now();
  }

  void clearCache() {
    _cachedCourses = null;
    _cachedLanguage = null;
    _lastFetchTime = null;
  }

  void invalidateIfLanguageChanged(String newLanguage) {
    if (_cachedLanguage != null && _cachedLanguage != newLanguage) {
      clearCache();
    }
  }
}

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  CourseListScreenState createState() => CourseListScreenState();
}

class CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  late TabController _tabController;
  bool isLoading = false;
  bool hasInitialized = false;
  List<Map<String, dynamic>> courses = [];
  String backendUrl = dotenv.env['BACKEND_URL'] ?? '';
  final storage = FlutterSecureStorage();
  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();
  final CourseDataCache _cache = CourseDataCache();

  // Track if this is the first time opening the screen in this app session
  static bool _hasEverFetched = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeCourses() async {
    if (!mounted) return;

    String currentLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Check if language changed and invalidate cache if needed
    _cache.invalidateIfLanguageChanged(currentLanguage);

    // Try to get cached data first
    List<Map<String, dynamic>>? cachedCourses = _cache.getCachedCourses(currentLanguage);

    if (cachedCourses != null) {
      // Use cached data
      setState(() {
        courses = cachedCourses;
        hasInitialized = true;
      });

      // Update progress for cached courses in background
      _updateCourseProgressInBackground();
      return;
    }

    // Only fetch from backend if:
    // 1. No cache available, OR
    // 2. This is the first time opening in this app session
    if (!_hasEverFetched || !_cache.isCacheValid) {
      await fetchCourses();
      _hasEverFetched = true;
    }
  }

  Future<void> fetchCourses({bool forceRefresh = false}) async {
    if (!mounted) return;

    String currentLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // If not forcing refresh and we have valid cached data, use it
    if (!forceRefresh) {
      List<Map<String, dynamic>>? cachedCourses = _cache.getCachedCourses(currentLanguage);
      if (cachedCourses != null) {
        setState(() {
          courses = cachedCourses;
          hasInitialized = true;
        });
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("No access token found");
      if (mounted) {
        setState(() {
          isLoading = false;
          hasInitialized = true;
        });
      }
      return;
    }

    try {
      if (!mounted) return;

      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/?target_language=$currentLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted && response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<Map<String, dynamic>> newCourses = data
            .map((course) => {
          "id": course["id"],
          "title": course["title"],
          "progress": 0.0, // Will be updated by background task
        })
            .toList();

        // Cache the new data
        _cache.setCachedCourses(newCourses, currentLanguage);

        setState(() {
          courses = newCourses;
        });

        // Update progress in background
        _updateCourseProgressInBackground();
      } else {
        log("Failed to fetch courses: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching courses: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasInitialized = true;
        });
      }
    }
  }

  // Background task to update course progress
  Future<void> _updateCourseProgressInBackground() async {
    for (int i = 0; i < courses.length; i++) {
      try {
        double progress = await _getLocalCourseProgress(courses[i]["id"]);
        if (mounted) {
          setState(() {
            courses[i]["progress"] = progress;
          });

          // Update cache with new progress
          String currentLanguage = Provider.of<LanguageProvider>(context, listen: false)
              .locale
              .languageCode;
          _cache.setCachedCourses(courses, currentLanguage);
        }
      } catch (e) {
        log("Error updating progress for course ${courses[i]["id"]}: $e");
      }
    }
  }

  // Calculate course progress locally
  Future<double> _getLocalCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
    if (totalTopics == 0) return 0.0;

    List<String> completedTopics = prefs.getStringList('completed_topics') ?? [];
    int count = completedTopics.where((key) => key.startsWith('$courseId|')).length;

    return count / totalTopics;
  }

  Future<String> _getModuleProgressText(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
    List<String> completedTopics = prefs.getStringList('completed_topics') ?? [];
    int completedCount = completedTopics.where((key) => key.startsWith('$courseId|')).length;

    return "$completedCount/$totalTopics ${L10n.getTranslatedText(context, 'Modules')}";
  }

  // Method to manually refresh data
  Future<void> refreshCourses() async {
    await fetchCourses(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ASKMeButton(
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMe()),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AcademeTheme.appColor,
          automaticallyImplyLeading: false,
          elevation: 0,
          title: Text(
            L10n.getTranslatedText(context, 'My Courses'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: isLoading ? null : refreshCourses,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 2, color: Colors.blue),
                ),
                tabs: [
                  _buildSynchronizedTab(context, 'ALL'),
                  _buildSynchronizedTab(context, 'ON GOING'),
                  _buildSynchronizedTab(context, 'COMPLETED'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCourseList(),
                  _buildFilteredCourses(ongoing: true),
                  _buildFilteredCourses(ongoing: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSynchronizedTab(BuildContext context, String labelKey) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: _tabTextGroup,
        style: TextStyle(fontSize: 16),
        minFontSize: 12,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCourseList() {
    if (isLoading && !hasInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: AcademeTheme.appColor,
        ),
      );
    }

    if (courses.isEmpty && hasInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              L10n.getTranslatedText(context, 'No courses available'),
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: refreshCourses,
              child: Text(L10n.getTranslatedText(context, 'Refresh')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshCourses,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(courses[index]);
        },
      ),
    );
  }

  Widget _buildFilteredCourses({required bool ongoing}) {
    if (isLoading && !hasInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: AcademeTheme.appColor,
        ),
      );
    }

    List<Map<String, dynamic>> filteredCourses = courses.where((course) {
      return ongoing ? course["progress"] < 1.0 : course["progress"] >= 1.0;
    }).toList();

    if (filteredCourses.isEmpty && hasInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              L10n.getTranslatedText(context, ongoing ? 'No ongoing courses' : 'No completed courses'),
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: refreshCourses,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: filteredCourses.length,
        itemBuilder: (context, index) {
          return _buildCourseCard(filteredCourses[index]);
        },
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return GestureDetector(
      onTap: () async {
        String selectedCourseId = course["id"];
        log("Selected Course ID: $selectedCourseId");

        try {
          await storage.write(key: 'course_id', value: selectedCourseId);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicViewScreen(courseId: selectedCourseId),
            ),
          );
        } catch (error) {
          log("Error storing course ID: $error");
        }
      },
      child: Container(
        height: 120,
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(10),
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
            SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course["title"],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
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
                            (course["progress"].clamp(0.0, 1.0) * 0.6),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: _getModuleProgressText(course["id"]),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? "0/0 ${L10n.getTranslatedText(context, 'Modules')}",
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(course["progress"].clamp(0.0, 1.0) * 100).toInt()}%",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
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