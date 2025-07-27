import 'dart:convert';
import 'dart:developer';
import 'package:ACADEMe/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import '../../../../../providers/progress_provider.dart';
import '../models/lessons_model.dart';

class LessonsController {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  Future<List<Map<String, dynamic>>> fetchSubtopics({
    required BuildContext context,
    required String courseId,
    required String topicId,
  }) async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) {
      log("❌ Missing access token");
      return [];
    }

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.topicSubtopicsOrdered(courseId, topicId, targetLanguage)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        return List<Map<String, dynamic>>.from(jsonDecode(responseBody));
      } else {
        log("❌ Failed to fetch subtopics: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("❌ Error fetching subtopics: $e");
      return [];
    }
  }

  Future<SubtopicContent> fetchMaterialsAndQuizzes({
    required BuildContext context,
    required String courseId,
    required String topicId,
    required String subtopicId,
  }) async {
    String? token = await storage.read(key: 'access_token');
    if (token == null) return SubtopicContent();

    final targetLanguage = Provider.of<LanguageProvider>(context, listen: false)
        .locale
        .languageCode;

    try {
      // Fetch materials
      final materialsResponse = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.subtopicMaterialsOrdered(courseId, topicId, subtopicId, targetLanguage)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      List<Map<String, dynamic>> materialsList = [];
      if (materialsResponse.statusCode == 200) {
        final String materialsBody = utf8.decode(materialsResponse.bodyBytes);
        materialsList = List<Map<String, dynamic>>.from(jsonDecode(materialsBody));
      }

      // Fetch quizzes
      List<Map<String, dynamic>> quizzesList = [];
      final quizzesResponse = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.subtopicQuizzesOrdered(courseId, topicId, subtopicId, targetLanguage)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (quizzesResponse.statusCode == 200) {
        final String quizzesBody = utf8.decode(quizzesResponse.bodyBytes);
        List<dynamic> quizzesData = jsonDecode(quizzesBody);

        for (var quiz in quizzesData) {
          final quizId = quiz["id"]?.toString() ?? "N/A";
          final questionsResponse = await http.get(
            ApiEndpoints.getUri(ApiEndpoints.subtopicQuizQuestionsOrdered(courseId, topicId, subtopicId, quizId, targetLanguage)),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
          );

          if (questionsResponse.statusCode == 200) {
            final String questionsBody = utf8.decode(questionsResponse.bodyBytes);
            List<dynamic> questionsData = jsonDecode(questionsBody);
            for (var question in questionsData) {
              quizzesList.add({
                "id": quizId,
                "question_id": question["id"]?.toString() ?? "N/A",
                "title": quiz["title"] ?? "Untitled Quiz",
                "difficulty": quiz["difficulty"] ?? "Unknown",
                "question_count": questionsData.length.toString(),
                "question_text": question["question_text"] ?? "No question text available",
                "options": (question["options"] as List<dynamic>?)?.cast<String>() ?? ["No options available"],
                "correct_option": question["correct_option"] ?? 0,
                "created_at": quiz["created_at"] ?? "",
              });
            }
          }
        }
      }

      return SubtopicContent(
        materials: materialsList,
        quizzes: quizzesList,
      );
    } catch (e) {
      log("❌ Error fetching materials/quizzes: $e");
      return SubtopicContent();
    }
  }

  // Updated methods to use ProgressProvider instead of direct API calls
  Map<String, dynamic>? determineResumePoint(String courseId, String topicId) {
    final progressProvider = ProgressProvider();
    return progressProvider.determineResumePoint(courseId, topicId);
  }

  bool isActivityCompleted({
    required String courseId,
    required String topicId,
    required String activityId,
    required String activityType,
    String? questionId,
  }) {
    final progressProvider = ProgressProvider();
    return progressProvider.isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: activityId,
      activityType: activityType,
      questionId: questionId,
    );
  }

  bool isSubtopicCompleted({
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> quizzes,
    required String courseId,
    required String topicId,
  }) {
    final progressProvider = ProgressProvider();
    return progressProvider.isSubtopicCompleted(
      materials: materials,
      quizzes: quizzes,
      courseId: courseId,
      topicId: topicId,
    );
  }
}
