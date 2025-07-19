import 'dart:convert';
import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TopicApiController {
  static final TopicApiController _instance = TopicApiController._internal();
  factory TopicApiController() => _instance;
  TopicApiController._internal();

  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> fetchTopicsFromBackend(
    String courseId,
    String targetLanguage,
  ) async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) throw Exception("No access token found");

      final response = await http.get(
        Uri.parse('$backendUrl/api/courses/$courseId/topics/?target_language=$targetLanguage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as List;

        // Store total topics for course
        final prefs = await SharedPreferences.getInstance();
        prefs.setInt('total_topics_$courseId', data.length);

        // Calculate progress for each topic
        List<Map<String, dynamic>> allTopics = [];
        for (var topic in data) {
          String topicId = topic["id"].toString();
          double progress = await _getTopicProgress(courseId, topicId);
          allTopics.add({
            "id": topicId,
            "title": topic["title"].toString(),
            "progress": progress * 100, // as percentage
          });
        }

        return allTopics;
      } else {
        throw Exception("Failed to fetch topics: ${response.statusCode}");
      }
    } catch (e) {
      log("Error fetching topics: $e");
      rethrow;
    }
  }

  // Get topic progress from SharedPreferences
  Future<double> _getTopicProgress(String courseId, String topicId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('progress_${courseId}_$topicId') ?? 0.0;
  }

  Future<String> getModuleProgressText(String courseId, String topicId) async {
    final prefs = await SharedPreferences.getInstance();

    // Get total subtopics for this topic (using the same key as overviews.dart)
    int totalSubtopics = prefs.getInt('total_subtopics_${courseId}_$topicId') ?? 0;

    // Get completed subtopics for this topic (using the same key as overviews.dart)
    List<String> completedSubtopics = prefs.getStringList('completed_subtopics_${courseId}_$topicId') ?? [];
    int completedCount = completedSubtopics.length;

    return "$completedCount/$totalSubtopics";
  }
}