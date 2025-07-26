import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'learning_card.dart';
import '../../../../localization/l10n.dart';
import '../../topics/screens/topic_view_screen.dart';
import '../controllers/home_controller.dart';

class ContinueLearningSection extends StatelessWidget {
  const ContinueLearningSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final ongoingCourses = controller.ongoingCourses;

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
                final index = ongoingCourses.indexOf(course);
                return Column(
                  children: [
                    LearningCard(
                      title: course["title"],
                      completed: course["completedModules"],
                      total: course["totalModules"],
                      percentage: (course["progress"] * 100).toInt(),
                      color: predefinedColors.length > index
                          ? predefinedColors[index]!
                          : Colors.primaries[index % Colors.primaries.length][100]!,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicViewScreen(
                              courseId: course["id"],
                              courseTitle: course["title"],
                            ),
                          ),
                        );
                        // No need to call refresh here as progress will be updated automatically
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
