// This file can be used for any data models related to flash cards
// Currently empty as all models are handled within the controller
// Can be expanded as needed

class FlashCardMaterial {
  final String id;
  final String type;
  final String content;
  final String? title;

  FlashCardMaterial({
    required this.id,
    required this.type,
    required this.content,
    this.title,
  });

  factory FlashCardMaterial.fromMap(Map<String, dynamic> map) {
    return FlashCardMaterial(
      id: map['id'] ?? '',
      type: map['type'] ?? 'text',
      content: map['content'] ?? '',
      title: map['title'],
    );
  }
}

class FlashCardQuiz {
  final String id;
  final String title;
  final List<dynamic> questions;

  FlashCardQuiz({
    required this.id,
    required this.title,
    required this.questions,
  });

  factory FlashCardQuiz.fromMap(Map<String, dynamic> map) {
    return FlashCardQuiz(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Untitled Quiz',
      questions: map['questions'] ?? [],
    );
  }
}
