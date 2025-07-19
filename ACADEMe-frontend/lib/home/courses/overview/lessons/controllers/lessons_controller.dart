import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/lessons_model.dart';

class LessonsController {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

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
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/$topicId/subtopics/?target_language=$targetLanguage&order_by=created_at'),
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
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/materials/?target_language=$targetLanguage&order_by=created_at'),
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
        Uri.parse(
            '$backendUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/?target_language=$targetLanguage&order_by=created_at'),
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
            Uri.parse(
                '$backendUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$targetLanguage&order_by=created_at'),
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

  Map<String, dynamic>? determineResumePoint(List<Map<String, dynamic>> userProgress, String courseId, String topicId) {
    // Find last in-progress activity
    Map<String, dynamic>? lastProgress = userProgress.firstWhere(
      (progress) => progress['course_id'] == courseId && 
                   progress['topic_id'] == topicId && 
                   progress['status'] == 'in-progress',
      orElse: () => {},
    );

    // If no in-progress, find last completed activity
    if (lastProgress.isEmpty) {
      lastProgress = userProgress.lastWhere(
        (progress) => progress['course_id'] == courseId && 
                     progress['topic_id'] == topicId && 
                     progress['status'] == 'completed',
        orElse: () => {},
      );
    }

    return lastProgress.isEmpty ? null : lastProgress;
  }

  bool isActivityCompleted({
    required List<Map<String, dynamic>> userProgress,
    required String courseId,
    required String topicId,
    required String activityId,
    required String activityType,
    String? questionId,
  }) {
    if (activityType == 'quiz' && questionId != null) {
      return userProgress.any((progress) =>
          progress['course_id'] == courseId &&
          progress['topic_id'] == topicId &&
          progress['quiz_id']?.toString() == activityId &&
          progress['question_id']?.toString() == questionId &&
          progress['status'] == 'completed');
    } else if (activityType == 'quiz') {
      // Check if all questions are completed
      return false; // Implementation depends on having access to quiz questions
    } else {
      return userProgress.any((progress) =>
          progress['course_id'] == courseId &&
          progress['topic_id'] == topicId &&
          progress['material_id'] == activityId &&
          progress['status'] == 'completed');
    }
  }

  bool isSubtopicCompleted({
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> quizzes,
    required List<Map<String, dynamic>> userProgress,
    required String courseId,
    required String topicId,
  }) {
    final hasIncompleteMaterial = materials.any((material) => 
        !isActivityCompleted(
          userProgress: userProgress,
          courseId: courseId,
          topicId: topicId,
          activityId: material['id'],
          activityType: 'material',
        ));

    final hasIncompleteQuiz = quizzes.any((quiz) => 
        !isActivityCompleted(
          userProgress: userProgress,
          courseId: courseId,
          topicId: topicId,
          activityId: quiz['id'],
          activityType: 'quiz',
          questionId: quiz['question_id'],
        ));

    return !hasIncompleteMaterial && !hasIncompleteQuiz;
  }
}