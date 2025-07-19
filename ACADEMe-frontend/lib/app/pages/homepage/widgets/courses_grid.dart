import 'package:flutter/material.dart';
import 'course_card.dart';
import '../../topics/screens/topic_view_screen.dart';
import '../../../../localization/l10n.dart';

class CoursesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final Future<void> Function() refreshCourses;
  final List<Color?> repeatingColors = [Colors.green[100], Colors.pink[100]];

   CoursesGrid({
    super.key,
    required this.courses,
    required this.refreshCourses,
  });

  @override
  Widget build(BuildContext context) {
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
        return CourseCard(
          courses[index]["title"],
          "${(index + 10) * 2} ${L10n.getTranslatedText(context, 'Lessons')}",
          repeatingColors[index % repeatingColors.length]!,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicViewScreen(
                  courseId: courses[index]["id"],
                ),
              ),
            );
            await refreshCourses();
          },
        );
      },
    );
  }
}