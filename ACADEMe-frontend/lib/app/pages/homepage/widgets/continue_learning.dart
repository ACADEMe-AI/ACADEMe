import 'package:flutter/material.dart';
import 'learning_card.dart';
import '../../../../localization/l10n.dart';
import '../../topics/screens/topic_view_screen.dart';

class ContinueLearningSection extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final Future<void> Function() refreshCourses;
  final VoidCallback onSeeAllTap;

  static const _cardColors = [
    Colors.pink,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];
  static const _cardColorOpacity = 0.2;
  static const _sectionTitleFontSize = 20.0;
  static const _seeAllFontSize = 16.0;
  static const _verticalSpacing = 16.0;
  static const _cardSpacing = 12.0;

  const ContinueLearningSection({
    super.key,
    required this.courses,
    required this.refreshCourses,
    required this.onSeeAllTap,
  });

  List<Map<String, dynamic>> get ongoingCourses => courses
      .where((course) => course["progress"] > 0 && course["progress"] < 1)
      .toList();

  @override
  Widget build(BuildContext context) {
    if (ongoingCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context),
        const SizedBox(height: _verticalSpacing),
        ...ongoingCourses.take(2).map((course) => Padding(
              padding: const EdgeInsets.only(bottom: _cardSpacing),
              child: _buildLearningCard(
                context: context,
                course: course,
                color: _cardColors[
                        ongoingCourses.indexOf(course) % _cardColors.length]
                    .withOpacity(_cardColorOpacity),
              ),
            )),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          L10n.getTranslatedText(context, 'Continue Learning'),
          style: const TextStyle(
            fontSize: _sectionTitleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(
          onPressed: onSeeAllTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
          ),
          child: Text(
            L10n.getTranslatedText(context, 'See All'),
            style: const TextStyle(
              fontSize: _seeAllFontSize,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningCard({
    required BuildContext context,
    required Map<String, dynamic> course,
    required Color color,
  }) {
    return LearningCard(
      title: course["title"],
      completed: course["completedModules"],
      total: course["totalModules"],
      percentage: (course["progress"] * 100).toInt(),
      color: color,
      onTap: () async {
        if (Navigator.canPop(context)) {
          Navigator.pop(context); // Close dialog if open
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TopicViewScreen(
              courseId: course["id"],
              courseTitle: course["title"],
            ),
          ),
        );
        await refreshCourses();
      },
    );
  }
}
