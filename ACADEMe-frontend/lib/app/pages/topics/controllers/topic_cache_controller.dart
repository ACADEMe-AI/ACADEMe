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