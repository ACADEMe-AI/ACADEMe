import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static const String _baseUrl = 'BACKEND_URL'; // Will be replaced at runtime
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  // Auth Endpoints
  static String get sendOtp => '$baseUrl/api/users/send-otp';
  static String get sendForgotPasswordOtp => '$baseUrl/api/users/forgot-password';
  static String get resetPassword => '$baseUrl/api/users/reset-password';
  static String get signup => '$baseUrl/api/users/signup';
  static String get login => '$baseUrl/api/users/login';
  static String userExists(String email) => '$baseUrl/api/users/exists?email=$email';
  static String get userDetails => '$baseUrl/api/users/me';
  static String get updateClass => '$baseUrl/api/users/update_class/';
  static String get adminEmails => '$baseUrl/api/users/admins';

  // Course Endpoints
  static String courses(String? language) => '$baseUrl/api/courses/?target_language=$language';
  static String courseTopics(String courseId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/?target_language=$language';
  static String topicSubtopics(String courseId, String topicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/?target_language=$language';
  static String subtopicMaterials(String courseId, String topicId, String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/materials/?target_language=$language';
  static String subtopicQuizzes(String courseId, String topicId, String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/?target_language=$language';
  static String quizQuestions(String courseId, String topicId, String subtopicId, String quizId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$language';

  // Progress Endpoints
  static String get progress => '$baseUrl/api/progress/';
  static String progressRecord(String progressId) => '$baseUrl/api/progress/$progressId';
  static String get progressVisuals => '$baseUrl/api/progress-visuals/';

  // AI Processing Endpoints
  static String processFile(String fileType) => '$baseUrl/api/process_$fileType';
  static String get processStt => '$baseUrl/api/process_stt';
  static String get processText => '$baseUrl/api/process_text';

  // Recommendation Endpoint
  static String recommendations(String language) =>
      '$baseUrl/api/recommendations/?target_language=$language';

  // Helper to get full URL
  static Uri getUri(String endpoint) => Uri.parse(endpoint);
}
