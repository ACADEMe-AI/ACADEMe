class Course {
  final String id;
  final String title;
  final double progress;
  final int completedModules;
  final int totalModules;

  Course({
    required this.id,
    required this.title,
    required this.progress,
    required this.completedModules,
    required this.totalModules,
  });

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map["id"],
      title: map["title"],
      progress: map["progress"],
      completedModules: map["completedModules"],
      totalModules: map["totalModules"],
    );
  }
}