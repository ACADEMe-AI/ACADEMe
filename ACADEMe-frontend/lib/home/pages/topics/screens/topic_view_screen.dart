import 'dart:developer';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import '../../topic_details/overview/screens/overview_screen.dart';
import '../controllers/topic_cache_controller.dart';
import '../controllers/app_lifecycle_controller.dart';
import '../controllers/topic_api_controller.dart';
import '../widgets/topic_card.dart';

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

  Future<void> _initializeTopics() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final targetLanguage = languageProvider.locale.languageCode;

    // Try to get cached data first
    final cachedTopics = _cacheController.getCachedTopics(widget.courseId, targetLanguage);

    if (cachedTopics != null && !_lifecycleController.isAppJustOpened) {
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

      // Cache the fresh data
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
              content: Text("Error loading topics: ${e.toString()}"),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () => _fetchTopicsFromBackend(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to refresh. Showing cached data."),
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
                ),
              ),
            ).then((_) {
              // Refresh data when coming back from overviews
              final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
              final cachedTopics = _cacheController.getCachedTopics(widget.courseId, languageProvider.locale.languageCode);
              if (cachedTopics != null) {
                _fetchTopicsFromBackend(showRefreshIndicator: true);
              }
            });
          },
        );
      },
    );
  }
}