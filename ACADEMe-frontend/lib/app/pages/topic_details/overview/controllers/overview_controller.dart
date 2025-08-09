import 'dart:convert';
import 'dart:developer';
import 'package:ACADEMe/api_endpoints.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';

import '../../../../../providers/progress_provider.dart';
import '../../../topics/controllers/topic_cache_controller.dart';

class OverviewController {
  final String courseId;
  final String topicId;
  final BuildContext context;

  final FlutterSecureStorage storage = const FlutterSecureStorage();

  OverviewController({
    required this.courseId,
    required this.topicId,
    required this.context,
  });

  Future<Map<String, dynamic>> fetchTopicDetails() async {
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Try to get from cache first
    final cacheController = TopicCacheController();
    final cached = cacheController.getCachedTopicDetails(
        courseId, topicId, targetLanguage);

    if (cached != null) {
      log("✅ Using cached topic details");
      return cached;
    }

    // If not cached, fall back to API call
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return {'error': 'Missing access token'};
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(
            ApiEndpoints.courseTopics(courseId, targetLanguage)),
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
            (topic) => topic['id'] == topicId,
            orElse: () => null,
          );
          if (topic != null) {
            final details = {
              'title': topic["title"]?.toString() ?? "Untitled Topic",
              'description': topic["description"]?.toString() ??
                  "No description available.",
            };

            // Cache for future use
            cacheController.cacheTopicDetails(
                courseId, topicId, targetLanguage, details);
            return details;
          }
        }
      }
      return {'error': 'Failed to load topic details'};
    } catch (e) {
      log("❌ Error fetching topic details: $e");
      return {'error': 'Error fetching topic details'};
    }
  }

  Future<Map<String, dynamic>> fetchSubtopicData() async {
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Try cache first
    final cacheController = TopicCacheController();
    final cached =
        cacheController.getCachedSubtopics(courseId, topicId, targetLanguage);

    if (cached != null) {
      log("✅ Using cached subtopics data");
      await _storeTopicTotalSubtopics(courseId, topicId, cached.length);
      return {
        'hasSubtopicData': true,
        'totalSubtopics': cached.length,
      };
    }

    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return {'error': 'Missing access token'};
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(
            ApiEndpoints.topicSubtopics(courseId, topicId, targetLanguage)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> subtopics = jsonDecode(responseBody);

        // Cache subtopics
        cacheController.cacheSubtopics(courseId, topicId, targetLanguage,
            subtopics.map((s) => Map<String, dynamic>.from(s)).toList());

        await _storeTopicTotalSubtopics(courseId, topicId, subtopics.length);

        return {
          'hasSubtopicData': true,
          'totalSubtopics': subtopics.length,
        };
      }
      return {'error': 'Failed to load subtopic data'};
    } catch (e) {
      log("❌ Error fetching subtopic data: $e");
      return {'error': 'Error fetching subtopic data'};
    }
  }

  Future<Map<String, dynamic>> fetchUserProgress() async {
    // Use ProgressProvider instead of direct API call
    final progressProvider = ProgressProvider();

    // Preload progress data (will use cache if valid)
    await progressProvider.preloadProgress(
        courseId: courseId, topicId: topicId);

    // Get progress summary from cached data
    final summary = progressProvider.getProgressSummary(courseId, topicId);

    // Get total subtopics from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final totalSubtopics =
        prefs.getInt('total_subtopics_${courseId}_${topicId}') ?? 0;
    final completedCount = summary['completedSubtopics'] as int;
    final progressPercentage =
        totalSubtopics > 0 ? completedCount / totalSubtopics : 0.0;

    // Save topic progress
    await _saveTopicProgress(courseId, topicId, progressPercentage);

    // Save course progress if topic is completed
    if (progressPercentage == 1.0) {
      await _saveCourseProgress(courseId);
    }

    return {
      'userProgress': summary['userProgress'],
      'completedSubtopics': completedCount,
      'progressPercentage': progressPercentage,
    };
  }

  // Add this method to OverviewController class
  Future<void> updateTopicCacheProgress() async {
    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    // Get current progress from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final progress = prefs.getDouble('progress_${courseId}_$topicId') ?? 0.0;

    // Update cached topic data
    final cacheController = TopicCacheController();
    cacheController.updateCachedTopicProgress(
        courseId, topicId, targetLanguage, progress);

    log("✅ Updated topic cache progress: $progress");
  }

  bool _isSubtopicCompleted(
      List<Map<String, dynamic>> progress, String subtopicId) {
    final subtopicMaterials = progress.where((p) =>
        p['subtopic_id'] == subtopicId && p['activity_type'] == 'reading');
    final subtopicQuizzes = progress.where(
        (p) => p['subtopic_id'] == subtopicId && p['activity_type'] == 'quiz');

    final hasIncompleteMaterial =
        subtopicMaterials.any((material) => material['status'] != 'completed');
    final hasIncompleteQuiz =
        subtopicQuizzes.any((quiz) => quiz['status'] != 'completed');

    return !hasIncompleteMaterial && !hasIncompleteQuiz;
  }

  Future<void> _storeTopicTotalSubtopics(
      String courseId, String topicId, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_subtopics_${courseId}_${topicId}', total);
  }

  Future<void> _markSubtopicCompleted(
      String courseId, String topicId, String subtopicId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'completed_subtopics_${courseId}_${topicId}';
    List<String> completed = prefs.getStringList(key) ?? [];
    if (!completed.contains(subtopicId)) {
      completed.add(subtopicId);
      await prefs.setStringList(key, completed);
    }
  }

  Future<void> _saveCourseProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final completedCourses = prefs.getStringList('completed_courses') ?? [];

    if (!completedCourses.contains(courseId)) {
      completedCourses.add(courseId);
      await prefs.setStringList('completed_courses', completedCourses);
      log("✅ Saved course progress: $courseId");
    }
  }

  Future<void> _saveTopicProgress(
      String courseId, String topicId, double progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('progress_${courseId}_${topicId}', progress);

    if (progress == 1.0) {
      final completedTopics = prefs.getStringList('completed_topics') ?? [];
      final topicKey = '$courseId|$topicId';

      if (!completedTopics.contains(topicKey)) {
        completedTopics.add(topicKey);
        await prefs.setStringList('completed_topics', completedTopics);
        log("✅ Saved topic progress: $topicKey");
      }
    }

    // Update topic cache with new progress
    await updateTopicCacheProgress();
  }
}
