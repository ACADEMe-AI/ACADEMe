import 'dart:convert';
import 'dart:developer';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/localization/language_provider.dart';

class OverviewController {
  final String courseId;
  final String topicId;
  final BuildContext context;
  
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://127.0.0.1:8000';

  OverviewController({
    required this.courseId,
    required this.topicId,
    required this.context,
  });

  Future<Map<String, dynamic>> fetchTopicDetails() async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return {'error': 'Missing access token'};
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/?target_language=$targetLanguage'),
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
            return {
              'title': topic["title"]?.toString() ?? "Untitled Topic",
              'description': topic["description"]?.toString() ?? "No description available.",
            };
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
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return {'error': 'Missing access token'};
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/$topicId/subtopics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final List<dynamic> subtopics = jsonDecode(responseBody);

        // Store total subtopics for progress calculation
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
    String? token = await storage.read(key: 'access_token');
    if (token == null) return {'error': 'Missing access token'};

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
                progress['course_id'] == courseId &&
                progress['topic_id'] == topicId)
            .toList();

        // Calculate completed subtopics
        final Set<String> completedSubIds = {};
        for (final p in progress) {
          if (p['status'] == 'completed' &&
              p['subtopic_id'] != null &&
              _isSubtopicCompleted(progress, p['subtopic_id'])) {
            completedSubIds.add(p['subtopic_id']);
            await _markSubtopicCompleted(courseId, topicId, p['subtopic_id']);
          }
        }

        // Get total subtopics from shared preferences
        final prefs = await SharedPreferences.getInstance();
        final totalSubtopics = prefs.getInt('total_subtopics_${courseId}_${topicId}') ?? 0;
        final progressPercentage = totalSubtopics > 0
            ? completedSubIds.length / totalSubtopics
            : 0.0;

        // Save topic progress
        await _saveTopicProgress(courseId, topicId, progressPercentage);

        // Save course progress if topic is completed
        if (progressPercentage == 1.0) {
          await _saveCourseProgress(courseId);
        }

        return {
          'userProgress': progress,
          'completedSubtopics': completedSubIds.length,
          'progressPercentage': progressPercentage,
        };
      }
      return {'error': 'Failed to load user progress'};
    } catch (e) {
      log("❌ Error fetching progress: $e");
      return {'error': 'Error fetching progress'};
    }
  }

  bool _isSubtopicCompleted(List<Map<String, dynamic>> progress, String subtopicId) {
    final subtopicMaterials = progress.where((p) =>
        p['subtopic_id'] == subtopicId && p['activity_type'] == 'reading');
    final subtopicQuizzes = progress.where((p) =>
        p['subtopic_id'] == subtopicId && p['activity_type'] == 'quiz');

    final hasIncompleteMaterial = subtopicMaterials.any(
        (material) => material['status'] != 'completed');
    final hasIncompleteQuiz = subtopicQuizzes.any(
        (quiz) => quiz['status'] != 'completed');

    return !hasIncompleteMaterial && !hasIncompleteQuiz;
  }

  Future<void> _storeTopicTotalSubtopics(String courseId, String topicId, int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_subtopics_${courseId}_${topicId}', total);
  }

  Future<void> _markSubtopicCompleted(String courseId, String topicId, String subtopicId) async {
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

  Future<void> _saveTopicProgress(String courseId, String topicId, double progress) async {
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
  }
}