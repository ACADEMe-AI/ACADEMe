import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  static const String _baseUrl = 'BACKEND_URL'; // Will be replaced at runtime
  static String get baseUrl =>
      dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';

  // Auth Endpoints
  static String get sendOtp => '$baseUrl/api/users/send-otp';
  static String get sendForgotPasswordOtp =>
      '$baseUrl/api/users/forgot-password';
  static String get resetPassword => '$baseUrl/api/users/reset-password';
  static String get signup => '$baseUrl/api/users/signup';
  static String get login => '$baseUrl/api/users/login';
  static String userExists(String email) =>
      '$baseUrl/api/users/exists?email=$email';
  static String get userDetails => '$baseUrl/api/users/me';
  static String get updateClass => '$baseUrl/api/users/update_class/';
  static String get adminEmails => '$baseUrl/api/users/admins';

  // Course Endpoints with Language Parameters
  static String courses(String language) =>
      '$baseUrl/api/courses/?target_language=$language';
  static String courseTopics(String courseId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/?target_language=$language';
  static String topicSubtopics(
          String courseId, String topicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/?target_language=$language';
  static String subtopicMaterials(String courseId, String topicId,
          String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/materials/?target_language=$language';
  static String subtopicQuizzes(String courseId, String topicId,
          String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/?target_language=$language';
  static String subtopicQuizQuestions(String courseId, String topicId,
          String subtopicId, String quizId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$language';
  static String topicMaterials(
          String courseId, String topicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/materials/?target_language=$language';
  static String topicQuizzes(
          String courseId, String topicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/quizzes/?target_language=$language';
  static String topicQuizQuestions(
          String courseId, String topicId, String quizId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/quizzes/$quizId/questions/?target_language=$language';

  // Course Endoints with No Language Parameters
  static String get coursesNoLang => '$baseUrl/api/courses/';
  static String courseTopicsNoLang(String courseId) =>
      '$baseUrl/api/courses/$courseId/topics/';
  static String topicSubtopicsNoLang(String courseId, String topicId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/';
  static String subtopicMaterialsNoLang(
          String courseId, String topicId, String subtopicId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/materials/';
  static String subtopicQuizzesNoLang(
          String courseId, String topicId, String subtopicId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/';
  static String subtopicQuizQuestionsNoLang(
          String courseId, String topicId, String subtopicId, String quizId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/$quizId/questions/';
  static String topicMaterialsNoLang(String courseId, String topicId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/materials/';
  static String topicQuizzesNoLang(String courseId, String topicId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/quizzes/';
  static String topicQuizQuestionsNoLang(
          String courseId, String topicId, String quizId) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/quizzes/$quizId/questions/';

  // Added order_by parameter
  static String topicSubtopicsOrdered(
          String courseId, String topicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/?target_language=$language&order_by=created_at';
  static String subtopicMaterialsOrdered(String courseId, String topicId,
          String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/materials/?target_language=$language&order_by=created_at';
  static String subtopicQuizzesOrdered(String courseId, String topicId,
          String subtopicId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/?target_language=$language&order_by=created_at';
  static String subtopicQuizQuestionsOrdered(String courseId, String topicId,
          String subtopicId, String quizId, String language) =>
      '$baseUrl/api/courses/$courseId/topics/$topicId/subtopics/$subtopicId/quizzes/$quizId/questions/?target_language=$language&order_by=created_at';

  // Progress Endpoints
  static String get progressNoLang => '$baseUrl/api/progress/';
  // static String progress(String? language) => '$baseUrl/api/progress/?target_language=$language';
  static String progressRecord(String progressId) =>
      '$baseUrl/api/progress/$progressId';
  static String get progressVisuals => '$baseUrl/api/progress-visuals/';

  // AI Processing Endpoints
  static String processFile(String fileType) =>
      '$baseUrl/api/process_${fileType.toLowerCase()}';
  static String get processStt => '$baseUrl/api/process_stt';
  static String get processText => '$baseUrl/api/process_text';

  // Recommendation Endpoint
  static String recommendations(String language) =>
      '$baseUrl/api/recommendations/?target_language=$language';

  // Helper to get full URL
  static Uri getUri(String endpoint) => Uri.parse(endpoint);

  // Teachers
  static String teacherEmails = '$baseUrl/api/auth/teacher-emails';
  static String teacherAllottedClasses = '$baseUrl/api/teacher/allotted-classes';
  static String studentsByClass(String className) => '$baseUrl/api/teacher/students/$className';
  static String classAnalytics(String className) => '$baseUrl/api/teacher/analytics/$className';
  static String teacherCourses = '$baseUrl/api/teacher/courses';
  static String teacherCoursesCreate = '$baseUrl/api/teacher/courses/create';
  static String teacherCourseTopics(String courseId) => '$baseUrl/api/teacher/courses/$courseId/topics';
  static String teacherCourseTopicsCreate(String courseId) => '$baseUrl/api/teacher/courses/$courseId/topics/create';
  static String teacherTopicMaterials(String courseId, String topicId) => '$baseUrl/api/teacher/courses/$courseId/topics/$topicId/materials';
  static String teacherTopicMaterialsCreate(String courseId, String topicId) => '$baseUrl/api/teacher/courses/$courseId/topics/$topicId/materials/create';
  static String teacherUpcomingClasses = '$baseUrl/api/teacher/classes/upcoming';
  static String teacherRecordedClasses = '$baseUrl/api/teacher/classes/recorded';
  static String scheduleClass = '$baseUrl/api/teacher/classes/schedule';
  static String startClass(String classId) => '$baseUrl/api/teacher/classes/$classId/start';
  static String shareRecording = '$baseUrl/api/teacher/recordings/share';
  static String teacherProfile = '$baseUrl/api/teacher/profile';
  static String updateTeacherProfile = '$baseUrl/api/teacher/profile/update';
  static String updateTeacherPreferences = '$baseUrl/api/teacher/preferences/update';

  static String teacherClassProgress(String className) => '$baseUrl/api/teacher/progress/$className';
  static String teacherClassProgressSummary(String className) => '$baseUrl/api/teacher/classes/$className/students/progress-summary';
}
