import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../api_endpoints.dart';

class HomeCourseDataCache {
  static final HomeCourseDataCache _instance = HomeCourseDataCache._internal();
  factory HomeCourseDataCache() => _instance;
  HomeCourseDataCache._internal();

  List<Map<String, dynamic>>? _cachedCourses;
  String? _cachedLanguage;
  DateTime? _lastFetchTime;

  static const Duration _cacheValidDuration = Duration(minutes: 30);

  bool isCacheValid(String language) {
    if (_lastFetchTime == null ||
        _cachedCourses == null ||
        _cachedLanguage != language) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  List<Map<String, dynamic>>? getCachedCourses(String language) {
    if (isCacheValid(language)) {
      return _cachedCourses;
    }
    return null;
  }

  void setCachedCourses(List<Map<String, dynamic>> courses, String language) {
    _cachedCourses = courses;
    _cachedLanguage = language;
    _lastFetchTime = DateTime.now();
  }

  void clearCache() {
    _cachedCourses = null;
    _cachedLanguage = null;
    _lastFetchTime = null;
  }
}

class HomeController extends ChangeNotifier {
  static final HomeController _instance = HomeController._internal();
  factory HomeController() => _instance;
  HomeController._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final HomeCourseDataCache _cache = HomeCourseDataCache();

  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  String? _currentLanguage;
  Map<String, String?> _userDetails = {};
  bool _userDetailsFetched = false;

  // Getters
  List<Map<String, dynamic>> get courses => _courses;
  bool get isLoading => _isLoading;
  Map<String, String?> get userDetails => _userDetails;

  // Ongoing courses getter
  List<Map<String, dynamic>> get ongoingCourses => _courses
      .where((course) => course["progress"] > 0 && course["progress"] < 1)
      .toList();

  Future<void> initializeData(String language) async {
    // Check if student has selected a valid class
    String? studentClass = await getStudentClass();

    if (studentClass == null) {
      debugPrint("⚠️ Cannot initialize data: No valid student class selected");
      _courses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (_currentLanguage == language && _courses.isNotEmpty && !_isLoading) {
      return; // Data already loaded for this language
    }

    await Future.wait([
      fetchCourses(language),
      if (!_userDetailsFetched) fetchAndStoreUserDetails(),
    ]);
  }

  Future<void> fetchCourses(String language, {bool forceRefresh = false}) async {
    if (_isLoading) return;

    // Validate student class BEFORE making request
    String? studentClass = await getStudentClass();
    if (studentClass == null) {
      debugPrint("❌ Cannot fetch courses: No valid student class");
      _courses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Check cache first if not forcing refresh
    if (!forceRefresh) {
      List<Map<String, dynamic>>? cachedCourses = _cache.getCachedCourses(language);
      if (cachedCourses != null && _currentLanguage == language) {
        _courses = cachedCourses;
        return;
      }
    }

    _isLoading = true;
    _currentLanguage = language;
    notifyListeners();

    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      debugPrint("❌ No access token found");
      _courses = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      debugPrint("🔄 Fetching courses for language: $language, class: $studentClass");

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.courses(language)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint("📡 Courses API response: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint("✅ Received ${data.length} courses from backend");

        List<Map<String, dynamic>> coursesWithProgress = [];

        for (var course in data) {
          String courseId = course["id"].toString();
          int totalTopics = await _getTotalTopics(courseId);
          int completedCount = await _getCompletedTopicsCount(courseId);
          double progress = totalTopics > 0 ? completedCount / totalTopics : 0.0;

          coursesWithProgress.add({
            "id": courseId,
            "title": course["title"],
            "progress": progress,
            "completedModules": completedCount,
            "totalModules": totalTopics,
          });
        }

        _courses = coursesWithProgress;
        _cache.setCachedCourses(coursesWithProgress, language);
        debugPrint("✅ Successfully processed ${_courses.length} courses");
      } else {
        debugPrint("❌ Failed to fetch courses: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        _courses = [];
      }
    } catch (e) {
      debugPrint("❌ Error fetching courses: $e");
      _courses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<int> _getTotalTopics(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('total_topics_$courseId') ?? 0;
    } catch (e) {
      debugPrint("Error getting total topics: $e");
      return 0;
    }
  }

  Future<int> _getCompletedTopicsCount(String courseId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> completedTopics =
          prefs.getStringList('completed_topics') ?? [];
      return completedTopics
          .where((key) => key.startsWith('$courseId|'))
          .length;
    } catch (e) {
      debugPrint("Error getting completed topics count: $e");
      return 0;
    }
  }

  Future<void> fetchAndStoreUserDetails() async {
    if (_userDetailsFetched) return;

    try {
      final String? token = await _secureStorage.read(key: 'access_token');

      if (token == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userDetails),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes));
        await _secureStorage.write(key: 'name', value: data['name']);
        await _secureStorage.write(key: 'email', value: data['email']);
        await _secureStorage.write(
            key: 'student_class', value: data['student_class']);
        await _secureStorage.write(key: 'photo_url', value: data['photo_url']);

        _userDetails = {
          'name': data['name'],
          'photo_url': data['photo_url'],
        };
        _userDetailsFetched = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<Map<String, String?>> getUserDetails() async {
    try {
      final String? name = await _secureStorage.read(key: 'name');
      final String? photoUrl = await _secureStorage.read(key: 'photo_url');

      // Read class from SharedPreferences for immediate updates
      final prefs = await SharedPreferences.getInstance();
      final String? studentClass = prefs.getString('student_class');

      debugPrint("getUserDetails from storage: class=$studentClass");

      return {
        'name': name,
        'photo_url': photoUrl,
        'student_class': studentClass,
      };
    } catch (e) {
      debugPrint("Error getting user details: $e");
      return {
        'name': null,
        'photo_url': null,
        'student_class': null,
      };
    }
  }

  Future<String?> getStudentClass() async {
    try {
      // Read from SharedPreferences (same as getUserDetails)
      final prefs = await SharedPreferences.getInstance();
      String? studentClass = prefs.getString("student_class");

      debugPrint("Student class for courses: $studentClass");

      // Validate the class
      if (studentClass == null || studentClass.isEmpty || studentClass == "SELECT") {
        debugPrint("Invalid or missing student class");
        return null;
      }

      return studentClass;
    } catch (e) {
      debugPrint("Error getting student class: $e");
      return null;
    }
  }

  void clearCache() {
    _cache.clearCache();
    _courses.clear();
    _userDetails.clear();
    _userDetailsFetched = false;
    _currentLanguage = null;
    _isLoading = false;
    debugPrint("✅ HomeController: Complete cache cleared");
    notifyListeners();
  }

  void clearUserCache() {
    _userDetails = {};
    _userDetailsFetched = false;
    notifyListeners();
  }

// Add this method to force refresh user details
  Future<void> forceRefreshUserDetails() async {
    _userDetails = {};
    _userDetailsFetched = false;
    await fetchAndStoreUserDetails();
  }

  Future<void> refreshData(String language) async {
    clearCache();
    await fetchCourses(language, forceRefresh: true);
  }

  // Method to update progress without full refresh
  void updateCourseProgress(
      String courseId, double newProgress, int completedModules) {
    final courseIndex =
        _courses.indexWhere((course) => course['id'] == courseId);
    if (courseIndex != -1) {
      _courses[courseIndex]['progress'] = newProgress;
      _courses[courseIndex]['completedModules'] = completedModules;

      // Update cache
      if (_currentLanguage != null) {
        _cache.setCachedCourses(_courses, _currentLanguage!);
      }

      notifyListeners();
    }
  }
}
