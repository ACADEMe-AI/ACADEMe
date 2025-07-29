import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopicCard extends StatelessWidget {
  final Map<String, dynamic> topic;
  final String courseId;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.topic,
    required this.courseId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    topic["title"],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  LinearProgressIndicator(
                    value: (topic["progress"] / 100).clamp(0.0, 1.0),
                    color: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: _getModuleProgressText(context),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ?? "0/0 ${L10n.getTranslatedText(context, 'Modules')}",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(topic["progress"].clamp(0.0, 100.0).toInt())}%",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getModuleProgressText(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final topicId = topic["id"].toString();

    // Get total subtopics for this topic
    int totalSubtopics = prefs.getInt('total_subtopics_${courseId}_$topicId') ?? 0;

    // Get completed subtopics for this topic
    List<String> completedSubtopics = prefs.getStringList('completed_subtopics_${courseId}_$topicId') ?? [];
    int completedCount = completedSubtopics.length;

    // Alternative method: Calculate completed modules based on progress percentage
    // If you don't have subtopic completion data, estimate from progress
    if (totalSubtopics > 0 && completedCount == 0) {
      double progressDecimal = (topic["progress"] / 100).clamp(0.0, 1.0);
      completedCount = (totalSubtopics * progressDecimal).round();
    }

    return "$completedCount/$totalSubtopics ${L10n.getTranslatedText(context, 'Modules')}";
  }
}