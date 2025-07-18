import 'dart:convert';
import 'dart:developer';
import 'package:ACADEMe/home/courses/overview/lessons.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'qna.dart';
import 'package:ACADEMe/home/courses/overview/lessons.dart';

class OverviewScreen extends StatefulWidget {
  final String courseId;
  final String topicId;

  const OverviewScreen(
      {super.key, required this.courseId, required this.topicId});

  @override
  OverviewScreenState createState() => OverviewScreenState();
}

class OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl =
      dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  String topicTitle = "Loading...";
  String topicDescription = "Fetching topic details...";
  bool isLoading = true;
  bool hasSubtopicData = false;

  // Progress tracking variables
  List<Map<String, dynamic>> userProgress = [];
  double progressPercentage = 0.0;
  int completedSubtopics = 0;
  int totalSubtopics = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    fetchData();
  }

  Future<void> fetchData() async {
    await fetchTopicDetails();
    await fetchSubtopicData();
    await fetchUserProgress();
  }

  Future<void> fetchTopicDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return;
    }
    if (!mounted) {
      return;
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      log("🔹 Topic API Response: ${response.body}");

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        if (jsonData is List) {
          final topic = jsonData.firstWhere(
                (topic) => topic['id'] == widget.topicId,
            orElse: () => null,
          );
          if (topic != null) {
            updateTopicDetails(topic);
          }
        }
      }
    } catch (e) {
      log("❌ Error fetching topic details: $e");
    }
  }

  Future<void> fetchSubtopicData() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return;
    }
    if (!mounted) {
      return;
    }
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/${widget.courseId}/topics/${widget.topicId}/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> subtopics = jsonDecode(responseBody);

        setState(() {
          hasSubtopicData = true;
          totalSubtopics = subtopics.length;
        });

        // Store total subtopics for progress calculation
        _storeTopicTotalSubtopics(widget.courseId, widget.topicId, totalSubtopics);
      }
    } catch (e) {
      log("❌ Error fetching subtopic data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Store total subtopics for topic
  Future<void> _storeTopicTotalSubtopics(String courseId, String topicId, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_subtopics_${courseId}_${topicId}', total);
  }

  // Check if all materials in a subtopic are completed
  bool _isSubtopicCompleted(String subtopicId) {
    // Get all materials for this subtopic
    final subtopicMaterials = userProgress.where((progress) =>
    progress['subtopic_id'] == subtopicId &&
        progress['activity_type'] == 'reading');

    // Get all quizzes for this subtopic
    final subtopicQuizzes = userProgress.where((progress) =>
    progress['subtopic_id'] == subtopicId &&
        progress['activity_type'] == 'quiz');

    // Check if any material is not completed
    final hasIncompleteMaterial = subtopicMaterials.any(
            (material) => material['status'] != 'completed');

    // Check if any quiz is not completed
    final hasIncompleteQuiz = subtopicQuizzes.any(
            (quiz) => quiz['status'] != 'completed');

    return !hasIncompleteMaterial && !hasIncompleteQuiz;
  }

  Future<void> fetchUserProgress() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) return;
    if (!mounted) return;

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/progress/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(responseBody);

        // Filter progress for current course and topic
        final progress = List<Map<String, dynamic>>.from(data['progress'])
            .where((progress) =>
        progress['course_id'] == widget.courseId &&
            progress['topic_id'] == widget.topicId)
            .toList();

        // Calculate completed subtopics
        final Set<String> completedSubIds = {};
        for (final p in progress) {
          if (p['status'] == 'completed' &&
              p['subtopic_id'] != null &&
              _isSubtopicCompleted(p['subtopic_id'])) {
            completedSubIds.add(p['subtopic_id']);
            // Mark subtopic as completed
            _markSubtopicCompleted(widget.courseId, widget.topicId, p['subtopic_id']);
          }
        }

        setState(() {
          userProgress = progress;
          completedSubtopics = completedSubIds.length;
          progressPercentage = totalSubtopics > 0
              ? completedSubtopics / totalSubtopics
              : 0.0;
        });

        // Save topic progress
        _saveTopicProgress(widget.courseId, widget.topicId, progressPercentage);

        // Save course progress if topic is completed
        if (progressPercentage == 1.0) {
          _saveCourseProgress(widget.courseId);
        }
      }
    } catch (e) {
      log("❌ Error fetching progress: $e");
    }
  }

  // Mark subtopic as completed
  Future<void> _markSubtopicCompleted(String courseId, String topicId, String subtopicId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'completed_subtopics_${courseId}_${topicId}';
    List<String> completed = prefs.getStringList(key) ?? [];
    if (!completed.contains(subtopicId)) {
      completed.add(subtopicId);
      await prefs.setStringList(key, completed);
    }
  }

  // Save course progress to shared preferences
  Future<void> _saveCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final completedCourses = prefs.getStringList('completed_courses') ?? [];

    if (!completedCourses.contains(courseId)) {
      completedCourses.add(courseId);
      await prefs.setStringList('completed_courses', completedCourses);
      log("✅ Saved course progress: $courseId");
    }
  }

  // Save topic progress to shared preferences
  Future<void> _saveTopicProgress(String courseId, String topicId, double progress) async {
    final prefs = await SharedPreferences.getInstance();

    // Save progress percentage
    await prefs.setDouble('progress_${courseId}_${topicId}', progress);

    // Save as completed if progress is 100%
    if (progress == 1.0) {
      final completedTopics = prefs.getStringList('completed_topics') ?? [];
      final topicKey = '$courseId|$topicId';

      if (!completedTopics.contains(topicKey)) {
        completedTopics.add(topicKey);
        await prefs.setStringList('completed_topics', completedTopics);
        log("✅ Saved topic progress: $topicKey");
      }
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    setState(() {
      topicTitle = data["title"]?.toString() ?? "Untitled Topic";
      topicDescription =
          data["description"]?.toString() ?? "No description available.";
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: height * 0.38,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF967EF6), Color(0xFFE8DAF9)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.05,
                    vertical: height * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              L10n.getTranslatedText(context, 'Topic details'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: const Icon(Icons.bookmark_border,
                                  color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding:
                          EdgeInsets.symmetric(horizontal: width * 0.03),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: height * 0.02),
                              Text(
                                isLoading ? "${L10n.getTranslatedText(context, 'Loading')}..." : topicTitle,
                                style: TextStyle(
                                  fontSize: width * 0.08,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: height * 0.01),
                              Text(
                                isLoading
                                    ? "${L10n.getTranslatedText(context, 'Fetching topic details')}..."
                                    : topicDescription,
                                style: TextStyle(
                                  fontSize: width * 0.04,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverToBoxAdapter(
                        child: Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(width * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                L10n.getTranslatedText(
                                    context, 'Your Progress'),
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: height * 0.005),
                              Text(
                                  "$completedSubtopics/$totalSubtopics ${L10n.getTranslatedText(context, 'Modules')}"),
                              SizedBox(height: height * 0.01),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progressPercentage,
                                  color: AcademeTheme.appColor,
                                  backgroundColor: const Color(0xFFE8E5FB),
                                  minHeight: height * 0.012,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              const Divider(color: Colors.grey, thickness: 0.5),
                              SizedBox(height: height * 0.005),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AcademeTheme.appColor,
                            unselectedLabelColor: Colors.black,
                            indicatorColor: AcademeTheme.appColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(fontSize: width * 0.045),
                            tabs: [
                              Tab(
                                  text: L10n.getTranslatedText(
                                      context, 'Overview')),
                              Tab(text: L10n.getTranslatedText(context, 'Q&A')),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      hasSubtopicData
                          ? LessonsSection(
                        courseId: widget.courseId,
                        topicId: widget.topicId,
                        userProgress: userProgress,

                      )
                          : Center(child: CircularProgressIndicator()),
                      QSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _StickyTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}