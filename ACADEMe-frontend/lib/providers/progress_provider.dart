import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_endpoints.dart';

class ProgressProvider with ChangeNotifier {
  static final ProgressProvider _instance = ProgressProvider._internal();
  factory ProgressProvider() => _instance;
  ProgressProvider._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Cache for progress data
  List<Map<String, dynamic>> _progressList = [];
  Map<String, List<Map<String, dynamic>>> _courseProgressCache = {};
  DateTime? _lastFetchTime;
  bool _isLoading = false;

  // Cache expiry time (5 minutes)
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Pending progress updates to batch
  final List<Map<String, dynamic>> _pendingUpdates = [];
  bool _isBatchProcessing = false;

  List<Map<String, dynamic>> get progressList => List.unmodifiable(_progressList);
  bool get isLoading => _isLoading;

  // Get cached progress for specific course/topic
  List<Map<String, dynamic>> getCourseProgress(String courseId, String topicId) {
    final key = '${courseId}_$topicId';
    return _courseProgressCache[key] ?? [];
  }

  // Check if cache is valid
  bool get _isCacheValid {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheExpiry;
  }

  // Fetch progress with intelligent caching
  Future<List<Map<String, dynamic>>> fetchProgress({
    String? courseId,
    String? topicId,
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid && _progressList.isNotEmpty) {
      if (courseId != null && topicId != null) {
        return getCourseProgress(courseId, topicId);
      }
      return _progressList;
    }

    // Prevent multiple simultaneous requests
    if (_isLoading) {
      // Wait for current request to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (courseId != null && topicId != null) {
        return getCourseProgress(courseId, topicId);
      }
      return _progressList;
    }

    _isLoading = true;
    notifyListeners();

    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) {
        log("❌ Missing access token");
        _isLoading = false;
        notifyListeners();
        return [];
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.progressNoLang),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _progressList = List<Map<String, dynamic>>.from(data["progress"] ?? []);
        _lastFetchTime = DateTime.now();

        // Update course-specific cache
        _updateCourseCache();

        log("✅ Progress fetched successfully: ${_progressList.length} records");
      } else if (response.statusCode == 404) {
        _progressList = [];
        _lastFetchTime = DateTime.now();
        _updateCourseCache();
        log("ℹ️ No progress records found");
      } else {
        log("❌ Failed to fetch progress: ${response.statusCode}");
      }
    } catch (e) {
      log("❌ Error fetching progress: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (courseId != null && topicId != null) {
      return getCourseProgress(courseId, topicId);
    }
    return _progressList;
  }

  // Update course-specific cache
  void _updateCourseCache() {
    _courseProgressCache.clear();
    for (var progress in _progressList) {
      final courseId = progress['course_id']?.toString();
      final topicId = progress['topic_id']?.toString();
      if (courseId != null && topicId != null) {
        final key = '${courseId}_$topicId';
        _courseProgressCache.putIfAbsent(key, () => []).add(progress);
      }
    }
  }

  // Check if activity is completed (local cache lookup)
  bool isActivityCompleted({
    required String courseId,
    required String topicId,
    required String activityId,
    required String activityType,
    String? questionId,
  }) {
    final courseProgress = getCourseProgress(courseId, topicId);

    if (activityType == 'quiz' && questionId != null) {
      return courseProgress.any((progress) =>
      progress['course_id']?.toString() == courseId &&
          progress['topic_id']?.toString() == topicId &&
          progress['quiz_id']?.toString() == activityId &&
          progress['question_id']?.toString() == questionId &&
          progress['status'] == 'completed');
    } else if (activityType == 'material') {
      return courseProgress.any((progress) =>
      progress['course_id']?.toString() == courseId &&
          progress['topic_id']?.toString() == topicId &&
          progress['material_id']?.toString() == activityId &&
          progress['status'] == 'completed');
    }
    return false;
  }

  // Check if subtopic is completed (local cache lookup)
  bool isSubtopicCompleted({
    required List<Map<String, dynamic>> materials,
    required List<Map<String, dynamic>> quizzes,
    required String courseId,
    required String topicId,
  }) {
    final hasIncompleteMaterial = materials.any((material) =>
    !isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: material['id']?.toString() ?? '',
      activityType: 'material',
    ));

    final hasIncompleteQuiz = quizzes.any((quiz) =>
    !isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: quiz['id']?.toString() ?? '',
      activityType: 'quiz',
      questionId: quiz['question_id']?.toString(),
    ));

    return !hasIncompleteMaterial && !hasIncompleteQuiz;
  }

  // Add progress update to batch queue
  void queueProgressUpdate(Map<String, dynamic> progressData) {
    _pendingUpdates.add(progressData);

    // Process batch after a short delay to allow for more updates
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isBatchProcessing) {
        _processBatchUpdates();
      }
    });
  }

  // Process batched progress updates
  Future<void> _processBatchUpdates() async {
    if (_pendingUpdates.isEmpty || _isBatchProcessing) return;

    _isBatchProcessing = true;
    final updatesToProcess = List<Map<String, dynamic>>.from(_pendingUpdates);
    _pendingUpdates.clear();

    try {
      String? token = await _storage.read(key: 'access_token');
      if (token == null) return;

      // Group updates by type to optimize API calls
      final Map<String, List<Map<String, dynamic>>> groupedUpdates = {};
      for (var update in updatesToProcess) {
        final key = '${update['course_id']}_${update['topic_id']}_${update['activity_type']}';
        groupedUpdates.putIfAbsent(key, () => []).add(update);
      }

      // Process each group
      for (var updates in groupedUpdates.values) {
        await _sendBatchProgressUpdate(updates, token);
      }

      // Update local cache with successful updates
      for (var update in updatesToProcess) {
        _updateLocalProgress(update);
      }

      // Update course cache
      _updateCourseCache();
      notifyListeners();

    } catch (e) {
      log("❌ Error processing batch updates: $e");
      // Re-queue failed updates
      _pendingUpdates.addAll(updatesToProcess);
    } finally {
      _isBatchProcessing = false;
    }
  }

  // Send batch progress update
  Future<void> _sendBatchProgressUpdate(List<Map<String, dynamic>> updates, String token) async {
    for (var progressData in updates) {
      // Check if progress already exists in cache
      final existingProgress = _progressList.firstWhere(
            (progress) =>
            _isSameProgress(progress, progressData),
        orElse: () => {},
      );

      try {
        if (existingProgress.isEmpty) {
          // Create new progress (for both materials and quizzes)
          final response = await http.post(
            ApiEndpoints.getUri(ApiEndpoints.progressNoLang),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: json.encode(progressData),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            log("✅ Progress created successfully");
          }
        } else {
          // Handle existing progress
          final bool isMaterial = progressData["material_id"] != null;
          final bool isQuiz = progressData["quiz_id"] != null;

          if (isMaterial) {
            // For materials: No PUT needed, already exists and completed
            log("ℹ️ Material already completed, no update needed");
            continue; // Skip any updates for materials
          } else if (isQuiz) {
            // For quizzes: Always allow updates (retakes, score improvements, etc.)
            final progressId = existingProgress["progress_id"];
            final response = await http.put(
              ApiEndpoints.getUri(ApiEndpoints.progressRecord(progressId)),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: json.encode({
                "status": progressData["status"],
                "score": progressData["score"],
                "metadata": progressData["metadata"],
              }),
            );

            if (response.statusCode == 200) {
              log("✅ Quiz progress updated successfully");
            }
          }
        }
      } catch (e) {
        log("❌ Error updating progress: $e");
      }

      // Small delay between requests to avoid overwhelming the server
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // Check if two progress records are the same
  bool _isSameProgress(Map<String, dynamic> existing, Map<String, dynamic> new_) {
    if (new_['quiz_id'] != null && new_['question_id'] != null) {
      return existing['quiz_id']?.toString() == new_['quiz_id']?.toString() &&
          existing['question_id']?.toString() == new_['question_id']?.toString();
    } else if (new_['material_id'] != null) {
      return existing['material_id']?.toString() == new_['material_id']?.toString();
    }
    return false;
  }

  // Update local progress cache
  void _updateLocalProgress(Map<String, dynamic> progressData) {
    final index = _progressList.indexWhere((progress) => _isSameProgress(progress, progressData));

    if (index != -1) {
      // Update existing
      _progressList[index] = {..._progressList[index], ...progressData};
    } else {
      // Add new
      _progressList.add(progressData);
    }
  }

  // Determine resume point (local cache lookup)
  Map<String, dynamic>? determineResumePoint(String courseId, String topicId) {
    final courseProgress = getCourseProgress(courseId, topicId);

    // Find last in-progress activity
    Map<String, dynamic>? lastProgress = courseProgress.where((progress) =>
    progress['course_id'] == courseId &&
        progress['topic_id'] == topicId &&
        progress['status'] == 'in-progress').isNotEmpty
        ? courseProgress.lastWhere((progress) =>
    progress['course_id'] == courseId &&
        progress['topic_id'] == topicId &&
        progress['status'] == 'in-progress')
        : null;

    // If no in-progress, find last completed activity
    if (lastProgress == null) {
      final completedProgress = courseProgress.where((progress) =>
      progress['course_id'] == courseId &&
          progress['topic_id'] == topicId &&
          progress['status'] == 'completed').toList();

      if (completedProgress.isNotEmpty) {
        lastProgress = completedProgress.last;
      }
    }

    return lastProgress;
  }

  // Force refresh progress data
  Future<void> refreshProgress({String? courseId, String? topicId}) async {
    await fetchProgress(courseId: courseId, topicId: topicId, forceRefresh: true);
  }

  // Clear cache
  void clearCache() {
    _progressList.clear();
    _courseProgressCache.clear();
    _lastFetchTime = null;
    _pendingUpdates.clear();
    notifyListeners();
  }
}
