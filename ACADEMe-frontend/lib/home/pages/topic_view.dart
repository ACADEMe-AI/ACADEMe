import 'dart:convert';
import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ACADEMe/home/courses/overview/overview.dart';

// Singleton cache manager for topics
class TopicCacheManager {
  static final TopicCacheManager _instance = TopicCacheManager._internal();
  factory TopicCacheManager() => _instance;
  TopicCacheManager._internal();

  final Map<String, TopicCacheData> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  void cacheTopics(String courseId, String languageCode, List<Map<String, dynamic>> topics) {
    final key = _getCacheKey(courseId, languageCode);
    _cache[key] = TopicCacheData(
      topics: List.from(topics),
      timestamp: DateTime.now(),
    );
  }

  List<Map<String, dynamic>>? getCachedTopics(String courseId, String languageCode) {
    final key = _getCacheKey(courseId, languageCode);
    final cacheData = _cache[key];

    if (cacheData == null) return null;

    // Check if cache is expired
    if (DateTime.now().difference(cacheData.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      return null;
    }

    return List.from(cacheData.topics);
  }

  bool hasCachedTopics(String courseId, String languageCode) {
    return getCachedTopics(courseId, languageCode) != null;
  }

  void clearCache() {
    _cache.clear();
  }

  void clearCacheForCourse(String courseId) {
    _cache.removeWhere((key, value) => key.startsWith('${courseId}_'));
  }

  String _getCacheKey(String courseId, String languageCode) {
    return '${courseId}_$languageCode';
  }
}

class TopicCacheData {
  final List<Map<String, dynamic>> topics;
  final DateTime timestamp;

  TopicCacheData({required this.topics, required this.timestamp});
}

// App lifecycle manager to track app state
class AppLifecycleManager extends WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  bool _isAppJustOpened = true;
  DateTime? _lastPausedTime;

  bool get isAppJustOpened => _isAppJustOpened;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _lastPausedTime = DateTime.now();
        break;
      case AppLifecycleState.resumed:
        if (_lastPausedTime != null &&
            DateTime.now().difference(_lastPausedTime!) > const Duration(minutes: 5)) {
          _isAppJustOpened = true;
        }
        break;
      default:
        break;
    }
  }

  void markAsUsed() {
    _isAppJustOpened = false;
  }
}

class TopicViewScreen extends StatefulWidget {
  final String courseId;

  const TopicViewScreen({super.key, required this.courseId});

  @override
  State<TopicViewScreen> createState() => _TopicViewScreenState();
}

class _TopicViewScreenState extends State<TopicViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> topics = [];
  List<Map<String, dynamic>> ongoingTopics = [];
  List<Map<String, dynamic>> completedTopics = [];
  bool isLoading = true;
  bool isRefreshing = false;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();
  final TopicCacheManager _cacheManager = TopicCacheManager();
  final AppLifecycleManager _lifecycleManager = AppLifecycleManager();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _lifecycleManager.initialize();
    _initializeTopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lifecycleManager.dispose();
    super.dispose();
  }

  Future<void> _initializeTopics() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    // Try to get cached data first
    final cachedTopics = _cacheManager.getCachedTopics(widget.courseId, targetLanguage);

    if (cachedTopics != null && !_lifecycleManager.isAppJustOpened) {
      // Use cached data
      setState(() {
        _updateTopicsData(cachedTopics);
        isLoading = false;
      });
      return;
    }

    // Load cached data immediately if available
    if (cachedTopics != null) {
      setState(() {
        _updateTopicsData(cachedTopics);
        isLoading = false;
      });
    }

    // Fetch fresh data from backend
    await _fetchTopicsFromBackend(showRefreshIndicator: cachedTopics != null);
    _lifecycleManager.markAsUsed();
  }

  Future<void> _fetchTopicsFromBackend({bool showRefreshIndicator = false}) async {
    if (!mounted) return;

    setState(() {
      if (showRefreshIndicator) {
        isRefreshing = true;
      } else {
        isLoading = true;
      }
    });

    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) throw Exception("No access token found");
      if (!mounted) return;

      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = languageProvider.locale.languageCode;

      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/${widget.courseId}/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;

        // Store total topics for course
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('total_topics_${widget.courseId}', data.length);

        // Calculate progress for each topic
        List<Map<String, dynamic>> allTopics = [];
        for (var topic in data) {
          String topicId = topic["id"].toString();
          double progress = await _getTopicProgress(topicId);
          allTopics.add({
            "id": topicId,
            "title": topic["title"].toString(),
            "progress": progress * 100, // as percentage
          });
        }

        // Cache the fresh data
        _cacheManager.cacheTopics(widget.courseId, targetLanguage, allTopics);

        setState(() {
          _updateTopicsData(allTopics);
        });
      } else {
        throw Exception("Failed to fetch topics: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching topics: $e");
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final cachedTopics = _cacheManager.getCachedTopics(widget.courseId, languageProvider.locale.languageCode);

        if (cachedTopics == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error loading topics: ${e.toString()}"),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _fetchTopicsFromBackend(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Failed to refresh. Showing cached data."),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  // Get topic progress from SharedPreferences
  Future<double> _getTopicProgress(String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('progress_${widget.courseId}_${topicId}') ?? 0.0;
  }

  Future<String> _getModuleProgressText(String topicId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get total subtopics for this topic (using the same key as overview.dart)
    int totalSubtopics = prefs.getInt('total_subtopics_${widget.courseId}_$topicId') ?? 0;

    // Get completed subtopics for this topic (using the same key as overview.dart)
    List<String> completedSubtopics = prefs.getStringList('completed_subtopics_${widget.courseId}_$topicId') ?? [];
    int completedCount = completedSubtopics.length;

    return "$completedCount/$totalSubtopics ${L10n.getTranslatedText(context, 'Modules')}";
  }

  void _updateTopicsData(List<Map<String, dynamic>> allTopics) {
    topics = allTopics;
    ongoingTopics = topics.where((t) => t["progress"] > 0 && t["progress"] < 100).toList();
    completedTopics = topics.where((t) => t["progress"] == 100).toList();
  }

  Future<void> _onRefresh() async {
    await _fetchTopicsFromBackend(showRefreshIndicator: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          L10n.getTranslatedText(context, 'Topics'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: isLoading ? null : _onRefresh,
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
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(width: 2, color: Colors.blue),
              ),
              tabs: [
                _buildSynchronizedTab(context, 'ALL'),
                _buildSynchronizedTab(context, 'ON GOING'),
                _buildSynchronizedTab(context, 'COMPLETED'),
              ],
            ),
          ),
          if (isRefreshing)
            const LinearProgressIndicator(
              backgroundColor: Colors.grey,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTopicList(topics),
                  _buildTopicList(ongoingTopics),
                  _buildTopicList(completedTopics),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynchronizedTab(BuildContext context, String labelKey) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: _tabTextGroup,
        style: const TextStyle(fontSize: 16),
        minFontSize: 12,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTopicList(List<Map<String, dynamic>> topicList) {
    if (isLoading && topics.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    if (topicList.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.topic_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              L10n.getTranslatedText(context, 'No topics available'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _onRefresh,
              child: Text(L10n.getTranslatedText(context, 'Refresh')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: topicList.length,
      itemBuilder: (context, index) {
        return _buildTopicCard(topicList[index]);
      },
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OverviewScreen(
              courseId: widget.courseId,
              topicId: topic["id"],
            ),
          ),
        ).then((_) {
          // Refresh data when coming back from overview
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          final cachedTopics = _cacheManager.getCachedTopics(widget.courseId, languageProvider.locale.languageCode);
          if (cachedTopics != null) {
            _fetchTopicsFromBackend(showRefreshIndicator: true);
          }
        });
      },
      child: Container(
        height: 100,
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
                    topic["title"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (topic["progress"] / 100).clamp(0.0, 1.0),
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: _getModuleProgressText(topic["id"]),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? "0/0 ${L10n.getTranslatedText(context, 'Modules')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(topic["progress"].clamp(0.0, 100.0).toInt())}%",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
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