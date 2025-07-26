import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'course_card.dart';
import '../../topics/screens/topic_view_screen.dart';
import '../../../../localization/l10n.dart';
import '../controllers/home_controller.dart';

class CoursesGrid extends StatelessWidget {
  final List<Color?> repeatingColors = [Colors.green[100], Colors.pink[100]];

  CoursesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        final courses = controller.courses;

        if (courses.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.2,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return CourseCard(
              course["title"] ?? 'Untitled Course',
              "${course["totalModules"] ?? 0} ${L10n.getTranslatedText(context, 'Lessons')}",
              repeatingColors[index % repeatingColors.length]!,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TopicViewScreen(
                      courseId: course["id"],
                      courseTitle: course["title"] ?? 'Untitled Course',
                    ),
                  ),
                );
                // No need to refresh as the controller will handle progress updates automatically
              },
            );
          },
        );
      },
    );
  }
}
