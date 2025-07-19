import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class TestReportController {
  final String courseId;
  final String topicId;
  final VoidCallback? onStateChanged;

  TestReportController({
    required this.courseId,
    required this.topicId,
    this.onStateChanged,
  });

  // State variables
  Map<String, dynamic> visualData = {};
  Map<String, dynamic>? topicResults;
  bool isLoading = true;
  double overallAverage = 0;
  double topicScore = 0;

  // Constants
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Initialize data loading
  Future<void> initialize() async {
    await Future.wait([
      fetchProgressData(),
      _loadTopicResults(),
    ]);
    _notifyStateChanged();
  }

  // Load quiz results from local storage
  Future<void> _loadTopicResults() async {
    final String storageKey = 'quiz_results_${courseId}_$topicId';
    String? resultsJson = await _secureStorage.read(key: storageKey);

    if (resultsJson != null) {
      topicResults = json.decode(resultsJson);
      if (topicResults != null) {
        final int correct = topicResults!['correctAnswers'] ?? 0;
        final int total = topicResults!['totalQuestions'] ?? 1;
        topicScore = total > 0 ? (correct / total) * 100 : 0;

        // Initialize quizData if it doesn't exist
        if (!topicResults!.containsKey('quizData')) {
          topicResults!['quizData'] = [];
        }
      }
    }
  }

  // Fetch progress data from API
  Future<void> fetchProgressData() async {
    isLoading = true;
    _notifyStateChanged();

    try {
      final String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token - Please login again');
      }

      final response = await http.get(
        Uri.parse('$backendUrl/api/progress-visuals/'),
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

  // Calculate overall average score
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

  // Get progress color based on score
  Color getProgressColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  // Get quiz data for chart
  List<dynamic> getQuizData() {
    return topicResults?['quizData'] ?? [];
  }

  // Get performance metrics
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

  // Notify state changes
  void _notifyStateChanged() {
    if (onStateChanged != null) {
      onStateChanged!();
    }
  }

  // Dispose resources if needed
  void dispose() {
    // Clean up any resources if needed
  }
}