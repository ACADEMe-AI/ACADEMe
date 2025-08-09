class OverviewModel {
  String topicTitle;
  String topicDescription;
  bool isLoading;
  bool hasSubtopicData;
  List<Map<String, dynamic>> userProgress;
  double progressPercentage;
  int completedSubtopics;
  int totalSubtopics;

  OverviewModel({
    this.topicTitle = "Loading...",
    this.topicDescription = "Fetching topic details...",
    this.isLoading = true,
    this.hasSubtopicData = false,
    this.userProgress = const [],
    this.progressPercentage = 0.0,
    this.completedSubtopics = 0,
    this.totalSubtopics = 0,
  });

  void updateFromController(Map<String, dynamic> data) {
    if (data.containsKey('title')) topicTitle = data['title'];
    if (data.containsKey('description')) topicDescription = data['description'];
    if (data.containsKey('isLoading')) isLoading = data['isLoading'];
    if (data.containsKey('hasSubtopicData'))
      hasSubtopicData = data['hasSubtopicData'];
    if (data.containsKey('userProgress'))
      userProgress = List<Map<String, dynamic>>.from(data['userProgress']);
    if (data.containsKey('progressPercentage'))
      progressPercentage = data['progressPercentage'];
    if (data.containsKey('completedSubtopics'))
      completedSubtopics = data['completedSubtopics'];
    if (data.containsKey('totalSubtopics'))
      totalSubtopics = data['totalSubtopics'];
  }

  // Add the missing toMap method
  Map<String, dynamic> toMap() {
    return {
      'title': topicTitle,
      'description': topicDescription,
      'isLoading': isLoading,
      'hasSubtopicData': hasSubtopicData,
      'userProgress': userProgress,
      'progressPercentage': progressPercentage,
      'completedSubtopics': completedSubtopics,
      'totalSubtopics': totalSubtopics,
    };
  }
}
