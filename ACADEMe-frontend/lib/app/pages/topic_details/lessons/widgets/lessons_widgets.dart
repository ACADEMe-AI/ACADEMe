import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../controllers/lessons_controller.dart';

class LessonsAndQuizzesWidget extends StatelessWidget {
  final String subtopicId;
  final List<Map<String, dynamic>> materials;
  final List<Map<String, dynamic>> quizzes;
  final String courseId;
  final String topicId;
  final Function(int) onTap;

  const LessonsAndQuizzesWidget({
    super.key,
    required this.subtopicId,
    required this.materials,
    required this.quizzes,
    required this.courseId,
    required this.topicId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final controller = LessonsController();
    final isSubtopicComplete = controller.isSubtopicCompleted(
      materials: materials,
      quizzes: quizzes,
      courseId: courseId,
      topicId: topicId,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        children: [
          if (materials.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...materials.map(
                      (m) => _buildMaterialTile(
                    m,
                    subtopicId,
                    isSubtopicComplete,
                    context,
                  ),
                ),
              ],
            ),
          if (quizzes.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...quizzes.map((q) => _buildQuizTile(
                  q,
                  subtopicId,
                  isSubtopicComplete,
                  context,
                )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialTile(
      Map<String, dynamic> material,
      String subtopicId,
      bool isSubtopicComplete,
      BuildContext context,
      ) {
    final controller = LessonsController();
    final isCompleted = controller.isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: material['id'].toString(),
      activityType: 'material',
    );

    return _buildTile(
      material["type"],
      material["category"],
      _getIconForContentType(material["type"]),
          () => onTap(materials.indexOf(material)),
      isCompleted,
      isSubtopicComplete,
      context,
    );
  }

  Widget _buildQuizTile(
      Map<String, dynamic> quiz,
      String subtopicId,
      bool isSubtopicComplete,
      BuildContext context,
      ) {
    final controller = LessonsController();
    final isCompleted = controller.isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: quiz['id'].toString(),
      activityType: 'quiz',
      questionId: quiz['question_id']?.toString(),
    );

    return _buildTile(
      quiz["title"],
      "${quiz["difficulty"]} • ${quiz["question_count"]} Questions",
      Icons.quiz,
          () => onTap(materials.length + quizzes.indexOf(quiz)),
      isCompleted,
      isSubtopicComplete,
      context,
    );
  }

  Widget _buildTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap,
      bool isCompleted,
      bool isSubtopicComplete,
      BuildContext context,
      ) {
    String localizedTitle = title;
    if (title.toLowerCase() == 'video') {
      localizedTitle = L10n.getTranslatedText(context, 'Video');
    } else if (title.toLowerCase() == 'text') {
      localizedTitle = L10n.getTranslatedText(context, 'Text');
    } else if (title.toLowerCase() == 'quiz') {
      localizedTitle = L10n.getTranslatedText(context, 'Quiz');
    } else if (title.toLowerCase() == 'document') {
      localizedTitle = L10n.getTranslatedText(context, 'Document');
    }

    final bool showCompleted = isSubtopicComplete || isCompleted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: showCompleted ? Colors.green : Colors.deepPurple,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      localizedTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                Icon(icon, color: Colors.deepPurple),
                if (showCompleted)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForContentType(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.video_library;
      case 'text':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'document':
        return Icons.description;
      default:
        return Icons.article;
    }
  }
}