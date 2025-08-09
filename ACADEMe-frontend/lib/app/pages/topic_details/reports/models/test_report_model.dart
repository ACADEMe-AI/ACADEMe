class TestReportModel {
  final String courseId;
  final String topicId;
  final Map<String, dynamic>? topicResults;
  final Map<String, dynamic> visualData;
  final double overallAverage;
  final double topicScore;
  final bool isLoading;

  TestReportModel({
    required this.courseId,
    required this.topicId,
    this.topicResults,
    this.visualData = const {},
    this.overallAverage = 0,
    this.topicScore = 0,
    this.isLoading = true,
  });

  TestReportModel copyWith({
    String? courseId,
    String? topicId,
    Map<String, dynamic>? topicResults,
    Map<String, dynamic>? visualData,
    double? overallAverage,
    double? topicScore,
    bool? isLoading,
  }) {
    return TestReportModel(
      courseId: courseId ?? this.courseId,
      topicId: topicId ?? this.topicId,
      topicResults: topicResults ?? this.topicResults,
      visualData: visualData ?? this.visualData,
      overallAverage: overallAverage ?? this.overallAverage,
      topicScore: topicScore ?? this.topicScore,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class QuizResult {
  final String title;
  final bool isCorrect;
  final DateTime? timestamp;

  QuizResult({
    required this.title,
    required this.isCorrect,
    this.timestamp,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      title: json['title'] ?? '',
      isCorrect: json['isCorrect'] == true,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isCorrect': isCorrect,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class PerformanceMetrics {
  final int correct;
  final int total;
  final int incorrect;
  final int skipped;

  PerformanceMetrics({
    required this.correct,
    required this.total,
    required this.incorrect,
    required this.skipped,
  });

  double get percentage => total > 0 ? (correct / total) * 100 : 0;

  factory PerformanceMetrics.fromMap(Map<String, int> map) {
    return PerformanceMetrics(
      correct: map['correct'] ?? 0,
      total: map['total'] ?? 1,
      incorrect: map['incorrect'] ?? 0,
      skipped: map['skipped'] ?? 0,
    );
  }
}

class VisualData {
  final Map<String, UserData> userData;

  VisualData({required this.userData});

  factory VisualData.fromJson(Map<String, dynamic> json) {
    final Map<String, UserData> userData = {};

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        userData[key] = UserData.fromJson(value);
      }
    });

    return VisualData(userData: userData);
  }
}

class UserData {
  final int quizzes;
  final double avgScore;

  UserData({
    required this.quizzes,
    required this.avgScore,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      quizzes: (json['quizzes'] as num?)?.toInt() ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
