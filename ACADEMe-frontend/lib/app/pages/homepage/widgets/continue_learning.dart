import 'package:flutter/material.dart';
import 'learning_card.dart';
import '../../../../localization/l10n.dart';
import '../../topics/screens/topic_view_screen.dart';

class ContinueLearningSection extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final Future<void> Function() refreshCourses;

  const ContinueLearningSection({
    super.key,
    required this.courses,
    required this.refreshCourses,
  });

  List<Map<String, dynamic>> get ongoingCourses => courses.where((course) =>
      course["progress"] > 0 && course["progress"] < 1).toList();

  @override
  Widget build(BuildContext context) {
    if (ongoingCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<Color?> predefinedColors = [
      Colors.pink[100],
      Colors.blue[100],
      Colors.green[100]
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Continue Learning'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                L10n.getTranslatedText(context, 'See All'),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: ongoingCourses.map((course) {
            return Column(
              children: [
                LearningCard(
                  title: course["title"],
                  completed: course["completedModules"],
                  total: course["totalModules"],
                  percentage: (course["progress"] * 100).toInt(),
                  color: predefinedColors.length > ongoingCourses.indexOf(course)
                      ? predefinedColors[ongoingCourses.indexOf(course)]!
                      : Colors.primaries[ongoingCourses.indexOf(course) %
                          Colors.primaries.length][100]!,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopicViewScreen(
                          courseId: course["id"],
                        ),
                      ),
                    );
                    await refreshCourses();
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}