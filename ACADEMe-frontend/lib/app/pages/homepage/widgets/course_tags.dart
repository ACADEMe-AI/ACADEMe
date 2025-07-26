import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../topics/screens/topic_view_screen.dart';
import '../controllers/home_controller.dart';

class CourseTagsGrid extends StatelessWidget {
  const CourseTagsGrid({super.key});

  void _onCourseTagTap(BuildContext context, int index) async {
    final controller = Provider.of<HomeController>(context, listen: false);
    final courses = controller.courses;

    if (index < courses.length) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TopicViewScreen(
            courseId: courses[index]["id"],
            courseTitle: courses[index]["title"] ?? 'Untitled Course',
          ),
        ),
      );
      // No need to refresh as progress updates will be handled automatically
    }
  }

  Widget _buildCourseTag({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final courses = controller.courses;
        if (courses.isEmpty) {
          return const Center(child: Text("No courses found"));
        }

        List<Widget> rows = [];
        for (int i = 0; i < courses.length; i += 2) {
          final first = courses[i];
          final second = (i + 1 < courses.length) ? courses[i + 1] : null;

          rows.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  _buildCourseTag(
                    text: first['title'] ?? '',
                    icon: Icons.school,
                    color: Colors.primaries[i % Colors.primaries.length],
                    onTap: () => _onCourseTagTap(context, i),
                  ),
                  if (second != null)
                    _buildCourseTag(
                      text: second['title'] ?? '',
                      icon: Icons.school,
                      color: Colors.primaries[(i + 1) % Colors.primaries.length],
                      onTap: () => _onCourseTagTap(context, i + 1),
                    )
                  else
                    const Expanded(child: SizedBox()), // filler if odd
                ],
              ),
            ),
          );
        }

        return Column(children: rows);
      },
    );
  }
}
