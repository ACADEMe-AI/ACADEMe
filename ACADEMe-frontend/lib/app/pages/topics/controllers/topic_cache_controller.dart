import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/topic_cache_data.dart';

class TopicCacheController {
  static final TopicCacheController _instance = TopicCacheController._internal();
  factory TopicCacheController() => _instance;
  TopicCacheController._internal();

  final Map<String, TopicCacheData> _cache = {};
  final Map<String, List<Map<String, dynamic>>> _subtopicsCache = {};
  final Map<String, Map<String, dynamic>> _topicDetailsCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);

  // Existing methods...
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

    if (DateTime.now().difference(cacheData.timestamp) > _cacheExpiry) {
      _cache.remove(key);
      return null;
    }

    return List.from(cacheData.topics);
  }

  // NEW: Cache topic details
  void cacheTopicDetails(String courseId, String topicId, String languageCode, Map<String, dynamic> details) {
    final key = '${courseId}_${topicId}_$languageCode';
    _topicDetailsCache[key] = {
      ...details,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  Map<String, dynamic>? getCachedTopicDetails(String courseId, String topicId, String languageCode) {
    final key = '${courseId}_${topicId}_$languageCode';
    final cached = _topicDetailsCache[key];

    if (cached == null) return null;

    final timestamp = DateTime.fromMillisecondsSinceEpoch(cached['timestamp']);
    if (DateTime.now().difference(timestamp) > _cacheExpiry) {
      _topicDetailsCache.remove(key);
      return null;
    }

    return Map.from(cached)..remove('timestamp');
  }

  // NEW: Cache subtopics
  void cacheSubtopics(String courseId, String topicId, String languageCode, List<Map<String, dynamic>> subtopics) {
    final key = '${courseId}_${topicId}_$languageCode';
    _subtopicsCache[key] = List.from(subtopics);
  }

  List<Map<String, dynamic>>? getCachedSubtopics(String courseId, String topicId, String languageCode) {
    final key = '${courseId}_${topicId}_$languageCode';
    return _subtopicsCache[key] != null ? List.from(_subtopicsCache[key]!) : null;
  }

  // Add this method to update cached topic progress without API calls
  void updateCachedTopicProgress(String courseId, String topicId, String languageCode, double progressPercentage) {
    final key = _getCacheKey(courseId, languageCode);
    final cacheData = _cache[key];

    if (cacheData != null) {
      // Find and update the specific topic in cached data
      final topics = cacheData.topics;
      final topicIndex = topics.indexWhere((topic) => topic['id'] == topicId);

      if (topicIndex != -1) {
        topics[topicIndex]['progress'] = progressPercentage * 100; // Convert to percentage

        // Update the cache with new data and refresh timestamp
        _cache[key] = TopicCacheData(
          topics: topics,
          timestamp: DateTime.now(),
        );

        log("✅ Updated cached topic progress for $topicId: ${progressPercentage * 100}%");
      }
    }
  }

// Add this method to refresh cached data with latest progress from SharedPreferences
  Future<void> refreshCachedTopicsProgress(String courseId, String languageCode) async {
    final key = _getCacheKey(courseId, languageCode);
    final cacheData = _cache[key];

    if (cacheData != null) {
      final prefs = await SharedPreferences.getInstance();

      // Update progress for all cached topics
      for (var topic in cacheData.topics) {
        final topicId = topic['id'].toString();
        final progress = prefs.getDouble('progress_${courseId}_$topicId') ?? 0.0;
        topic['progress'] = progress * 100; // Convert to percentage
      }

      // Update cache timestamp
      _cache[key] = TopicCacheData(
        topics: cacheData.topics,
        timestamp: DateTime.now(),
      );

      log("✅ Refreshed all cached topics progress for course $courseId");
    }
  }

// Add this method to check if we need to refresh progress
  bool shouldRefreshProgress(String courseId, String languageCode) {
    final key = _getCacheKey(courseId, languageCode);
    final cacheData = _cache[key];

    if (cacheData == null) return true;

    // Check if cache is older than 2 minutes (shorter interval for progress updates)
    return DateTime.now().difference(cacheData.timestamp) > const Duration(minutes: 2);
  }

  String _getCacheKey(String courseId, String languageCode) {
    return '${courseId}_$languageCode';
  }

  bool hasCachedTopics(String courseId, String languageCode) {
    return getCachedTopics(courseId, languageCode) != null;
  }

  void clearCache() {
    _cache.clear();
    _subtopicsCache.clear();
    _topicDetailsCache.clear();
  }

  void clearCacheForCourse(String courseId) {
    _cache.removeWhere((key, value) => key.startsWith('${courseId}_'));
    _subtopicsCache.removeWhere((key, value) => key.startsWith('${courseId}_'));
    _topicDetailsCache.removeWhere((key, value) => key.startsWith('${courseId}_'));
  }
}