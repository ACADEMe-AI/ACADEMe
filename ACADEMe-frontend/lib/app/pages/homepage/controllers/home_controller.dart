import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api_endpoints.dart';

class HomeCourseDataCache {
  static final HomeCourseDataCache _instance = HomeCourseDataCache._internal();
  factory HomeCourseDataCache() => _instance;
  HomeCourseDataCache._internal();

  List<Map<String, dynamic>>? _cachedCourses;
  String? _cachedLanguage;
  DateTime? _lastFetchTime;

  static const Duration _cacheValidDuration = Duration(minutes: 30);

  bool isCacheValid(String language) {
    if (_lastFetchTime == null || _cachedCourses == null || _cachedLanguage != language) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  List<Map<String, dynamic>>? getCachedCourses(String language) {
    if (isCacheValid(language)) {
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
}

class HomeController {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final HomeCourseDataCache _cache = HomeCourseDataCache();

  Future<List<Map<String, dynamic>>> fetchCourses(String language) async {
    List<Map<String, dynamic>>? cachedCourses = _cache.getCachedCourses(language);
    if (cachedCourses != null) {
      return cachedCourses;
    }

    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.courses(language)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        List<Map<String, dynamic>> coursesWithProgress = [];

        for (var course in data) {
          String courseId = course["id"].toString();
          int totalTopics = await _getTotalTopics(courseId);
          int completedCount = await _getCompletedTopicsCount(courseId);
          double progress = totalTopics > 0 ? completedCount / totalTopics : 0.0;

          coursesWithProgress.add({
            "id": courseId,
            "title": course["title"],
            "progress": progress,
            "completedModules": completedCount,
            "totalModules": totalTopics,
          });
        }

        _cache.setCachedCourses(coursesWithProgress, language);
        return coursesWithProgress;
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching courses: $e");
      return [];
    }
  }

  Future<int> _getTotalTopics(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('total_topics_$courseId') ?? 0;
    } catch (e) {
      debugPrint("Error getting total topics: $e");
      return 0;
    }
  }

  Future<int> _getCompletedTopicsCount(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> completedTopics = prefs.getStringList('completed_topics') ?? [];
      return completedTopics.where((key) => key.startsWith('$courseId|')).length;
    } catch (e) {
      debugPrint("Error getting completed topics count: $e");
      return 0;
    }
  }

  Future<Map<String, String?>> getUserDetails() async {
    try {
      final String? name = await _secureStorage.read(key: 'name');
      final String? photoUrl = await _secureStorage.read(key: 'photo_url');
      return {
        'name': name,
        'photo_url': photoUrl,
      };
    } catch (e) {
      debugPrint("Error getting user details: $e");
      return {
        'name': null,
        'photo_url': null,
      };
    }
  }

  

  Future<void> fetchAndStoreUserDetails() async {
    try {
      final String? token = await _secureStorage.read(key: 'access_token');

      if (token == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userDetails),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        await _secureStorage.write(key: 'name', value: data['name']);
        await _secureStorage.write(key: 'email', value: data['email']);
        await _secureStorage.write(key: 'student_class', value: data['student_class']);
        await _secureStorage.write(key: 'photo_url', value: data['photo_url']);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  void clearCache() {
    _cache.clearCache();
  }
}