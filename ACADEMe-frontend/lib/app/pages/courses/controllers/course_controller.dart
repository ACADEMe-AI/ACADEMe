import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api_endpoints.dart';
import '../models/course_model.dart';

class CourseController extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final CourseDataCache _cache = CourseDataCache();

  List<Course> _courses = [];
  bool _isLoading = false;
  bool _hasInitialized = false;
  static bool _hasEverFetched = false;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  bool get hasInitialized => _hasInitialized;

  List<Course> get ongoingCourses =>
      _courses.where((course) => course.progress < 1.0 && course.progress > 0.0).toList();
  List<Course> get completedCourses =>
      _courses.where((course) => course.progress >= 1.0).toList();

  Future<void> initializeCourses(BuildContext context) async {
    String currentLanguage =
        Provider.of<LanguageProvider>(context, listen: false)
            .locale
            .languageCode;

    // Check if language changed and invalidate cache if needed
    _cache.invalidateIfLanguageChanged(currentLanguage);

    // Try to get cached data first
    List<Course>? cachedCourses = _cache.getCachedCourses(currentLanguage);

    if (cachedCourses != null) {
      // Use cached data
      _courses = cachedCourses;
      _hasInitialized = true;
      notifyListeners();

      // Update progress for cached courses in background
      _updateCourseProgressInBackground();
      return;
    }

    // Only fetch from backend if:
    // 1. No cache available, OR
    // 2. This is the first time opening in this app session
    if (!_hasEverFetched || !_cache.isCacheValid) {
      await fetchCourses(context);
      _hasEverFetched = true;
    }
  }

  Future<void> fetchCourses(BuildContext context,
      {bool forceRefresh = false}) async {
    String currentLanguage =
        Provider.of<LanguageProvider>(context, listen: false)
            .locale
            .languageCode;

    // If not forcing refresh and we have valid cached data, use it
    if (!forceRefresh) {
      List<Course>? cachedCourses = _cache.getCachedCourses(currentLanguage);
      if (cachedCourses != null) {
        _courses = cachedCourses;
        _hasInitialized = true;
        notifyListeners();
        return;
      }
    }

    _isLoading = true;
    notifyListeners();

    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      log("No access token found");
      _isLoading = false;
      _hasInitialized = true;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.courses(currentLanguage)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));

        List<Course> newCourses =
            data.map((courseJson) => Course.fromJson(courseJson)).toList();

        // Cache the new data
        _cache.setCachedCourses(newCourses, currentLanguage);

        _courses = newCourses;
        notifyListeners();

        // Update progress in background
        _updateCourseProgressInBackground();
      } else {
        log("Failed to fetch courses: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching courses: $e");
    } finally {
      _isLoading = false;
      _hasInitialized = true;
      notifyListeners();
    }
  }

  // Background task to update course progress
  Future<void> _updateCourseProgressInBackground() async {
    for (int i = 0; i < _courses.length; i++) {
      try {
        double progress = await _getLocalCourseProgress(_courses[i].id);
        _courses[i] = _courses[i].copyWith(progress: progress);

        // Update cache with new progress
        String? cachedLanguage = _cache.cachedLanguage;
        if (cachedLanguage != null) {
          _cache.setCachedCourses(_courses, cachedLanguage);
        }
      } catch (e) {
        log("Error updating progress for course ${_courses[i].id}: $e");
      }
    }
    notifyListeners();
  }

  // Calculate course progress locally
  Future<double> _getLocalCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
    if (totalTopics == 0) return 0.0;

    List<String> completedTopics =
        prefs.getStringList('completed_topics') ?? [];
    int count =
        completedTopics.where((key) => key.startsWith('$courseId|')).length;

    return count / totalTopics;
  }

// Add this method to CourseController
  Future<void> refreshCourseProgress(String courseId) async {
    try {
      double progress = await _getLocalCourseProgress(courseId);
      final index = _courses.indexWhere((c) => c.id == courseId);

      if (index != -1) {
        _courses[index] = _courses[index].copyWith(progress: progress);

        // Update cache if exists
        String? cachedLanguage = _cache.cachedLanguage;
        if (cachedLanguage != null) {
          _cache.setCachedCourses(_courses, cachedLanguage);
        }

        notifyListeners();
      }
    } catch (e) {
      log("Error refreshing course progress: $e");
    }
  }

  Future<String> getModuleProgressText(
      String courseId, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
    List<String> completedTopics =
        prefs.getStringList('completed_topics') ?? [];
    int completedCount =
        completedTopics.where((key) => key.startsWith('$courseId|')).length;

    // You'll need to import L10n or pass the translated text
    return "$completedCount/$totalTopics Modules"; // Replace with proper localization
  }

  // Method to manually refresh data
  Future<void> refreshCourses(BuildContext context) async {
    await fetchCourses(context, forceRefresh: true);
  }

  Future<void> selectCourse(String courseId) async {
    try {
      await _storage.write(key: 'course_id', value: courseId);
      log("Selected Course ID: $courseId");
    } catch (error) {
      log("Error storing course ID: $error");
      rethrow;
    }
  }
}
