import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../topics/screens/topic_view_screen.dart';
import '../controllers/home_controller.dart';
import 'package:ACADEMe/localization/language_provider.dart';

class CourseTagsGrid extends StatefulWidget {
  final Future<void> Function()? refreshCourses;

  const CourseTagsGrid({super.key, this.refreshCourses});

  @override
  State<CourseTagsGrid> createState() => _CourseTagsGridState();
}

class _CourseTagsGridState extends State<CourseTagsGrid> {
  final HomeController _controller = HomeController();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    setState(() => _isLoading = true);
    try {
      final courses = await _controller.fetchCourses(currentLanguage);
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint("Error fetching courses: $e");
    }
  }

  void _onCourseTagTap(int index) async {
    if (index < _courses.length) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TopicViewScreen(
            courseId: _courses[index]["id"],
            courseTitle: _courses[index]["title"] ?? 'Untitled Course', // Add required courseTitle
            
          ),
        ),
      );
      if (widget.refreshCourses != null) await widget.refreshCourses!();
      await _fetchCourses();
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
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_courses.isEmpty) return const Center(child: Text("No courses found"));

    List<Widget> rows = [];
    for (int i = 0; i < _courses.length; i += 2) {
      final first = _courses[i];
      final second = (i + 1 < _courses.length) ? _courses[i + 1] : null;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildCourseTag(
                text: first['title'] ?? '',
                icon: Icons.school,
                color: Colors.primaries[i % Colors.primaries.length],
                onTap: () => _onCourseTagTap(i),
              ),
              if (second != null)
                _buildCourseTag(
                  text: second['title'] ?? '',
                  icon: Icons.school,
                  color: Colors.primaries[(i + 1) % Colors.primaries.length],
                  onTap: () => _onCourseTagTap(i + 1),
                )
              else
                const Expanded(child: SizedBox()), // filler if odd
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }
}
