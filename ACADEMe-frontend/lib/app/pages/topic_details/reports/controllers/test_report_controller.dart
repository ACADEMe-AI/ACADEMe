import 'dart:convert';
import 'dart:async';
import 'package:ACADEMe/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class TestReportController {
  final String courseId;
  final String topicId;
  final String courseTitle;
  final String topicTitle;
  final String language;
  final VoidCallback? onStateChanged;

  TestReportController({
    required this.courseId,
    required this.topicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.language,
    this.onStateChanged,
  });

  // State variables
  Map<String, dynamic> visualData = {};
  Map<String, dynamic>? topicResults;
  List<Map<String, dynamic>> subtopicsWithQuizzes = [];
  bool isLoading = true;
  double overallAverage = 0;
  double topicScore = 0;

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> initialize() async {
    await Future.wait([
      fetchProgressData(),
      _loadTopicResults(),
      _fetchSubtopicsWithQuizzes(),
    ]);
    _notifyStateChanged();
  }

  Future<void> _loadTopicResults() async {
    final String storageKey = 'quiz_results_${courseId}_$topicId';
    String? resultsJson = await _secureStorage.read(key: storageKey);

    if (resultsJson != null) {
      topicResults = json.decode(resultsJson);
      if (topicResults != null) {
        final int correct = topicResults!['correctAnswers'] ?? 0;
        final int total = topicResults!['totalQuestions'] ?? 1;
        topicScore = total > 0 ? (correct / total) * 100 : 0;

        if (!topicResults!.containsKey('quizData')) {
          topicResults!['quizData'] = [];
        }
      }
    }
  }

  Future<void> _fetchSubtopicsWithQuizzes() async {
    try {
      final String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token');
      }

      // Fetch subtopics for the topic
      final subtopicsResponse = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.topicSubtopics(courseId, topicId, language)),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (subtopicsResponse.statusCode == 200) {
        final String subtopicsBody = utf8.decode(subtopicsResponse.bodyBytes);
        final List<dynamic> subtopicsJson = jsonDecode(subtopicsBody);
        
        // Fetch quizzes for each subtopic
        for (var subtopic in subtopicsJson) {
          final subtopicId = subtopic['id'].toString();
          final quizzesResponse = await http.get(
            ApiEndpoints.getUri(ApiEndpoints.subtopicQuizzes(courseId, topicId, subtopicId, language)),
            headers: {
              'Authorization': 'Bearer $token',
              'accept': 'application/json',
            },
          );

          if (quizzesResponse.statusCode == 200) {
            final String quizzesBody = utf8.decode(quizzesResponse.bodyBytes);
            final List<dynamic> quizzesJson = jsonDecode(quizzesBody);
            
            // For each quiz, we'll include it but local results will be fetched separately
            subtopicsWithQuizzes.add({
              ...subtopic,
              'quizzes': quizzesJson,
            });
          }
        }
      } else {
        throw Exception('Failed to load subtopics: ${subtopicsResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching subtopics with quizzes: $e');
      subtopicsWithQuizzes = [];
    }
  }

  // Get local quiz results for a specific quiz
  Future<Map<String, dynamic>?> getLocalQuizResults(String quizId) async {
    try {
      final String storageKey = 'quiz_results_${courseId}_${topicId}_$quizId';
      String? resultsJson = await _secureStorage.read(key: storageKey);
      
      if (resultsJson != null) {
        return json.decode(resultsJson);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching local quiz results: $e');
      return null;
    }
  }

  // Calculate subtopic score from local storage
  Future<double> calculateSubtopicScoreFromLocal(List<dynamic> quizzes) async {
    if (quizzes.isEmpty) return 0;
    
    double totalScore = 0;
    int completedQuizzes = 0;
    
    for (var quiz in quizzes) {
      final quizId = quiz['id'].toString();
      final localResults = await getLocalQuizResults(quizId);
      
      if (localResults != null) {
        final correct = localResults['correctAnswers'] ?? 0;
        final total = localResults['totalQuestions'] ?? 1;
        if (total > 0) {
          totalScore += (correct / total) * 100;
          completedQuizzes++;
        }
      }
    }
    
    return completedQuizzes > 0 ? totalScore / completedQuizzes : 0;
  }

  // Calculate overall metrics from local storage
  Future<Map<String, dynamic>> calculateMetricsFromLocal() async {
    int completedSubtopics = 0;
    int totalSubtopics = subtopicsWithQuizzes.length;
    int quizzesTaken = 0;
    double totalScore = 0;
    int scoredQuizzes = 0;
    
    for (var subtopic in subtopicsWithQuizzes) {
      final quizzes = subtopic['quizzes'] as List<dynamic>? ?? [];
      bool hasCompletedQuiz = false;
      
      for (var quiz in quizzes) {
        final quizId = quiz['id'].toString();
        final localResults = await getLocalQuizResults(quizId);
        
        if (localResults != null) {
          hasCompletedQuiz = true;
          quizzesTaken++;
          
          final correct = localResults['correctAnswers'] ?? 0;
          final total = localResults['totalQuestions'] ?? 1;
          if (total > 0) {
            totalScore += (correct / total) * 100;
            scoredQuizzes++;
          }
        }
      }
      
      if (hasCompletedQuiz) completedSubtopics++;
    }
    
    return {
      'completedSubtopics': completedSubtopics,
      'totalSubtopics': totalSubtopics,
      'quizzesTaken': quizzesTaken,
      'averageScore': scoredQuizzes > 0 ? totalScore / scoredQuizzes : 0,
    };
  }

  // Calculate overall score from local storage
  Future<double> calculateOverallScoreFromLocal() async {
    if (subtopicsWithQuizzes.isEmpty) return 0;
    
    double totalScore = 0;
    int totalQuizzes = 0;
    
    for (var subtopic in subtopicsWithQuizzes) {
      final quizzes = subtopic['quizzes'] as List<dynamic>? ?? [];
      for (var quiz in quizzes) {
        final quizId = quiz['id'].toString();
        final localResults = await getLocalQuizResults(quizId);
        
        if (localResults != null) {
          final correct = localResults['correctAnswers'] ?? 0;
          final total = localResults['totalQuestions'] ?? 1;
          if (total > 0) {
            totalScore += (correct / total) * 100;
            totalQuizzes++;
          }
        }
      }
    }
    
    return totalQuizzes > 0 ? totalScore / totalQuizzes : 0;
  }

  Future<void> fetchProgressData() async {
    isLoading = true;
    _notifyStateChanged();

    try {
      final String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token - Please login again');
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.progressVisuals),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);

        visualData = jsonData;
        overallAverage = calculateOverallAverage(jsonData['visual_data']);
      } else {
        throw Exception('Failed to load progress data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching progress data: $e');
      rethrow;
    } finally {
      isLoading = false;
      _notifyStateChanged();
    }
  }

  double calculateOverallAverage(Map<String, dynamic> visualData) {
    double totalScore = 0;
    int totalQuizzes = 0;

    visualData.forEach((key, userData) {
      if (userData['quizzes'] > 0) {
        totalScore += (userData['avg_score'] as num).toDouble() *
            (userData['quizzes'] as num).toInt();
        totalQuizzes += (userData['quizzes'] as num).toInt();
      }
    });

    return totalQuizzes > 0 ? totalScore / totalQuizzes : 0;
  }

  Color getProgressColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  List<dynamic> getQuizData() {
    return topicResults?['quizData'] ?? [];
  }

  Map<String, int> getPerformanceMetrics() {
    final int correct = topicResults?['correctAnswers'] ?? 0;
    final int total = topicResults?['totalQuestions'] ?? 1;
    final int incorrect = total - correct;
    final int skipped = topicResults?['skipped'] ?? 0;

    return {
      'correct': correct,
      'total': total,
      'incorrect': incorrect,
      'skipped': skipped,
    };
  }

  void _notifyStateChanged() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  void dispose() {
    // Clean up resources if needed
  }
}