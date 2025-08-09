class Course {
  final String id;
  final String title;
  final double progress;

  Course({
    required this.id,
    required this.title,
    this.progress = 0.0,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      title: json['title'],
      progress: 0.0, // Will be updated separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'progress': progress,
    };
  }

  Course copyWith({
    String? id,
    String? title,
    double? progress,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      progress: progress ?? this.progress,
    );
  }
}

class CourseDataCache {
  static final CourseDataCache _instance = CourseDataCache._internal();
  factory CourseDataCache() => _instance;
  CourseDataCache._internal();

  List<Course>? _cachedCourses;
  String? _cachedLanguage;
  DateTime? _lastFetchTime;

  // Cache validity duration (30 minutes)
  static const Duration _cacheValidDuration = Duration(minutes: 30);

  // Getter for cached language
  String? get cachedLanguage => _cachedLanguage;

  bool get isCacheValid {
    if (_lastFetchTime == null || _cachedCourses == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  List<Course>? getCachedCourses(String language) {
    if (_cachedLanguage == language && isCacheValid) {
      return _cachedCourses;
    }
    return null;
  }

  void setCachedCourses(List<Course> courses, String language) {
    _cachedCourses = courses;
    _cachedLanguage = language;
    _lastFetchTime = DateTime.now();
  }

  void clearCache() {
    _cachedCourses = null;
    _cachedLanguage = null;
    _lastFetchTime = null;
  }

  void invalidateIfLanguageChanged(String newLanguage) {
    if (_cachedLanguage != null && _cachedLanguage != newLanguage) {
      clearCache();
    }
  }
}
