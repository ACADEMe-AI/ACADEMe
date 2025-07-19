import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/test_report_controller.dart';

class TopicScoreCard extends StatelessWidget {
  final TestReportController controller;

  const TopicScoreCard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final int correct = controller.topicResults?['correctAnswers'] ?? 0;
    final int total = controller.topicResults?['totalQuestions'] ?? 1;
    final String scoreText = total > 0
        ? "${controller.topicScore.toStringAsFixed(0)}%"
        : L10n.getTranslatedText(context, 'No data');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AcademeTheme.appColor,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Topic Performance'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scoreText,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "$correct/$total ${L10n.getTranslatedText(context, 'correct')}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                if (total > 0)
                  CircularProgressIndicator(
                    value: controller.topicScore / 100,
                    color: controller.getProgressColor(controller.topicScore),
                    backgroundColor: Colors.white30,
                    strokeWidth: 6,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}