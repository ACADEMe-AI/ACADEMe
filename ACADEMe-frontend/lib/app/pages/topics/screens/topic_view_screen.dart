import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import '../../../../providers/progress_provider.dart';
import '../../courses/widgets/course_widgets.dart';
import '../../topic_details/overview/screens/overview_screen.dart';
import '../controllers/topic_cache_controller.dart';
import '../controllers/app_lifecycle_controller.dart';
import '../controllers/topic_api_controller.dart';
import '../widgets/topic_card.dart';

class TopicViewScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const TopicViewScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

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
  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();
  final TopicCacheController _cacheController = TopicCacheController();
  final AppLifecycleController _lifecycleController = AppLifecycleController();
  final TopicApiController _apiController = TopicApiController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _lifecycleController.initialize();
    _initializeTopics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lifecycleController.dispose();
    super.dispose();
  }

  // Replace the _initializeTopics method with:
  Future<void> _initializeTopics() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    // Preload progress data once at the beginning
    final progressProvider = ProgressProvider();
    await progressProvider.preloadProgress(courseId: widget.courseId);

    // Try to get cached data first
    final cachedTopics = _cacheController.getCachedTopics(widget.courseId, targetLanguage);

    if (cachedTopics != null) {
      // Always show cached data first for instant loading
      setState(() {
        _updateTopicsData(cachedTopics);
        isLoading = false;
      });

      // Only fetch from backend if:
      // 1. App just opened (cold start)
      // 2. Cache is older than 15 minutes
      // 3. User explicitly refreshes
      if (_lifecycleController.isAppJustOpened ||
          !_cacheController.hasCachedTopics(widget.courseId, targetLanguage)) {
        await _fetchTopicsFromBackend(showRefreshIndicator: true);
      } else {
        // Just refresh progress from SharedPreferences
        await _refreshTopicsProgressOnly();
      }
    } else {
      // No cache available, must fetch from backend
      await _fetchTopicsFromBackend(showRefreshIndicator: false);
    }

    _lifecycleController.markAsUsed();
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
      final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
      final targetLanguage = languageProvider.locale.languageCode;

      final allTopics = await _apiController.fetchTopicsFromBackend(
        widget.courseId,
        targetLanguage,
      );

      if (!mounted) return;

      _cacheController.cacheTopics(widget.courseId, targetLanguage, allTopics);

      setState(() {
        _updateTopicsData(allTopics);
      });
    } catch (e) {
      log("Error fetching topics: $e");
      if (mounted) {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        final cachedTopics = _cacheController.getCachedTopics(widget.courseId, languageProvider.locale.languageCode);

        if (cachedTopics == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              // content: Text("Error loading topics: ${e.toString()}"),
              content: Text(L10n.getTranslatedText(context, 'Error loading topics, try again')),
              action: SnackBarAction(
                label: L10n.getTranslatedText(context, 'Retry'),
                onPressed: () => _fetchTopicsFromBackend(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L10n.getTranslatedText(context, 'Failed to refresh. Showing cached data')),
              duration: Duration(seconds: 2),
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

  // Add this method to _TopicViewScreenState class
  Future<void> _refreshTopicsProgressOnly() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    // Check if we should refresh progress (based on time elapsed)
    if (_cacheController.shouldRefreshProgress(widget.courseId, targetLanguage)) {
      // Refresh cached progress without API call
      await _cacheController.refreshCachedTopicsProgress(widget.courseId, targetLanguage);

      // Update UI with refreshed cached data
      final updatedTopics = _cacheController.getCachedTopics(widget.courseId, targetLanguage);
      if (updatedTopics != null && mounted) {
        setState(() {
          _updateTopicsData(updatedTopics);
        });
      }
    } else {
      // Data is fresh enough, just update UI with existing cache
      final cachedTopics = _cacheController.getCachedTopics(widget.courseId, targetLanguage);
      if (cachedTopics != null && mounted) {
        setState(() {
          _updateTopicsData(cachedTopics);
        });
      }
    }
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
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final language = languageProvider.locale.languageCode;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          widget.courseTitle,
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
                  _buildTopicList(topics, language),
                  _buildTopicList(ongoingTopics, language),
                  _buildTopicList(completedTopics, language),
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

  Widget _buildTopicList(List<Map<String, dynamic>> topicList, String language) {
    if (isLoading && topics.isEmpty) {
      return _buildShimmerLoadingList();
    }

    if (topicList.isEmpty && !isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
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
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: topicList.length,
      itemBuilder: (context, index) {
        return TopicCard(
          topic: topicList[index],
          courseId: widget.courseId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OverviewScreen(
                  courseId: widget.courseId,
                  topicId: topicList[index]["id"],
                  courseTitle: widget.courseTitle,
                  topicTitle: topicList[index]["title"] ?? "Untitled Topic",
                  language: language,
                ),
              ),
            ).then((_) async {
              // Update both progress and module completion for the specific topic
              final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
              final targetLanguage = languageProvider.locale.languageCode;
              
              // Update module completion for the specific topic
              await _cacheController.updateTopicModuleCompletion(
                widget.courseId, 
                topicList[index]["id"], 
                targetLanguage
              );
              
              // Then refresh all topics progress
              await _refreshTopicsProgressOnly();
            });
          },
        );
      },
    );
  }

  Widget _buildShimmerLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 6, // Show 6 shimmer cards
      itemBuilder: (context, index) {
        return ShimmerEffect(
          child: _buildTopicCardShimmer(),
        );
      },
    );
  }

  Widget _buildTopicCardShimmer() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title shimmer
          Container(
            height: 18,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 16,
            width: MediaQuery.of(context).size.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar shimmer
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 8),
          // Bottom text shimmer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 14,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                height: 14,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Import the existing ShimmerEffect from your widgets file
// import 'path/to/your/shimmer_effect_widget.dart';