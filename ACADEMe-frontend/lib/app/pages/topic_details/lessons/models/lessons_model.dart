class LessonsSectionParams {
  final String courseId;
  final String topicId;
  final List<Map<String, dynamic>> userProgress;

  const LessonsSectionParams({
    required this.courseId,
    required this.topicId,
    required this.userProgress,
  });
}

class SubtopicContent {
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> quizzes;

  const SubtopicContent({
    this.materials = const [],
    this.quizzes = const [],
  });
}

class SubtopicState {
  final Map<String, bool> isExpanded;
  final Map<String, String> subtopicIds;
  final Map<String, List<Map<String, dynamic>>> subtopicMaterials;
  final Map<String, List<Map<String, dynamic>>> subtopicQuizzes;
  final Map<String, bool> subtopicLoading;
  final bool isLoading;
  final bool isNavigating;
  final String? resumeSubtopicId;
  final bool showResume;

  const SubtopicState({
    this.isExpanded = const {},
    this.subtopicIds = const {},
    this.subtopicMaterials = const {},
    this.subtopicQuizzes = const {},
    this.subtopicLoading = const {},
    this.isLoading = true,
    this.isNavigating = false,
    this.resumeSubtopicId,
    this.showResume = false,
  });

  SubtopicState copyWith({
    Map<String, bool>? isExpanded,
    Map<String, String>? subtopicIds,
    Map<String, List<Map<String, dynamic>>>? subtopicMaterials,
    Map<String, List<Map<String, dynamic>>>? subtopicQuizzes,
    Map<String, bool>? subtopicLoading,
    bool? isLoading,
    bool? isNavigating,
    String? resumeSubtopicId,
    bool? showResume,
  }) {
    return SubtopicState(
      isExpanded: isExpanded ?? this.isExpanded,
      subtopicIds: subtopicIds ?? this.subtopicIds,
      subtopicMaterials: subtopicMaterials ?? this.subtopicMaterials,
      subtopicQuizzes: subtopicQuizzes ?? this.subtopicQuizzes,
      subtopicLoading: subtopicLoading ?? this.subtopicLoading,
      isLoading: isLoading ?? this.isLoading,
      isNavigating: isNavigating ?? this.isNavigating,
      resumeSubtopicId: resumeSubtopicId ?? this.resumeSubtopicId,
      showResume: showResume ?? this.showResume,
    );
  }
}
