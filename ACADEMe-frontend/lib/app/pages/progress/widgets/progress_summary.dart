import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/app/pages/progress/widgets/motivation_popup.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../homepage/controllers/home_controller.dart';
import '../controllers/progress_controller.dart';
import '../models/progress_models.dart';

class SummarySection extends StatelessWidget {
  final ProgressController controller;

  const SummarySection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: controller.fetchOverallGrade(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("❌ Error: ${snapshot.error}"));
        }

        double overallGrade = snapshot.data ?? 0.0;
        String letterGrade =
            ProgressHelpers.getLetterGrade(context, overallGrade);
        double progressValue = overallGrade / 100;

        return Consumer<HomeController>(
          builder: (context, homeController, child) {
            List<Map<String, dynamic>> courses = homeController.courses;
            int totalCourses = courses.length;

            return FutureBuilder<int>(
              future: _getCompletedCoursesCount(courses),
              builder: (context, completedSnapshot) {
                if (completedSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                int completedCourses = completedSnapshot.data ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          27, 158, 158, 158)),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _buildSummaryItem(
                                    L10n.getTranslatedText(
                                        context, 'Total Courses'),
                                    totalCourses.toString()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          27, 158, 158, 158)),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _buildSummaryItem(
                                    L10n.getTranslatedText(
                                        context, 'Completed'),
                                    completedCourses.toString()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color.fromARGB(27, 158, 158, 158)),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildSummaryItem(
                            L10n.getTranslatedText(context, 'Overall Grade'),
                            overallGrade.toStringAsFixed(2),
                            isCircular: true,
                            letterGrade: letterGrade,
                            progressValue: progressValue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMotivationCard(context, overallGrade),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<int> _getCompletedCoursesCount(
      List<Map<String, dynamic>> courses) async {
    final prefs = await SharedPreferences.getInstance();
    int completedCount = 0;

    for (var course in courses) {
      String courseId = course["id"];
      int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
      if (totalTopics == 0) continue;

      List<String> completedTopics =
          prefs.getStringList('completed_topics') ?? [];
      int completedTopicsCount =
          completedTopics.where((key) => key.startsWith('$courseId|')).length;

      if (completedTopicsCount >= totalTopics) {
        completedCount++;
      }
    }

    return completedCount;
  }

  Widget _buildSummaryItem(String title, String value,
      {bool isCircular = false,
      String letterGrade = "",
      double progressValue = 0.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          isCircular
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        color: AcademeTheme.appColor,
                      ),
                    ),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 90,
                          height: 90,
                          child: CircularProgressIndicator(
                            value: progressValue,
                            backgroundColor: Colors.grey[300],
                            color: AcademeTheme.appColor,
                            strokeWidth: 8,
                          ),
                        ),
                        Text(
                          letterGrade,
                          style: TextStyle(
                            fontSize: letterGrade.length == 1 ? 28 : 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Text(value,
                  style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor)),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context, double score) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const MotivationPopup(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProgressHelpers.getMotivationMessage(context, score),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      L10n.getTranslatedText(
                          context, 'Learn about your weak points'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
