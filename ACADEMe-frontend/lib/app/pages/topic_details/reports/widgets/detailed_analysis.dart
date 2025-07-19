import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/test_report_controller.dart';

class DetailedAnalysis extends StatelessWidget {
  final TestReportController controller;

  const DetailedAnalysis({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = controller.getPerformanceMetrics();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Detailed Performance'),
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            _buildPerformanceRow(
              L10n.getTranslatedText(context, 'Correct Answers'),
              "${metrics['correct']}/${metrics['total']}",
              Colors.green,
            ),
            _buildPerformanceRow(
              L10n.getTranslatedText(context, 'Incorrect Answers'),
              "${metrics['incorrect']}/${metrics['total']}",
              Colors.redAccent,
            ),
            if (metrics['skipped']! > 0)
              _buildPerformanceRow(
                L10n.getTranslatedText(context, 'Skipped Questions'),
                "${metrics['skipped']}",
                Colors.orangeAccent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}