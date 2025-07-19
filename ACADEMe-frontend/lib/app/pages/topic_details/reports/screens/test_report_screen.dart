import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/pdf_report_service.dart';
import '../controllers/test_report_controller.dart';
import '../widgets/topic_score_card.dart';
import '../widgets/performance_graph.dart';
import '../widgets/detailed_analysis.dart';
import '../widgets/action_buttons.dart';

class TestReportScreen extends StatefulWidget {
  final String courseId;
  final String topicId;

  const TestReportScreen({
    super.key,
    required this.courseId,
    required this.topicId,
  });

  @override
  TestReportScreenState createState() => TestReportScreenState();
}

class TestReportScreenState extends State<TestReportScreen> {
  late TestReportController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TestReportController(
      courseId: widget.courseId,
      topicId: widget.topicId,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      await _controller.initialize();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.getTranslatedText(context, 'Test Report'),
          style: GoogleFonts.poppins(fontSize: 22, color: Colors.white),
        ),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopicScoreCard(controller: _controller),
                  const SizedBox(height: 16),
                  PerformanceGraph(controller: _controller),
                  const SizedBox(height: 16),
                  DetailedAnalysis(controller: _controller),
                  const SizedBox(height: 16),
                  ActionButtons(
                    onDownloadReport: () => _handlePdfAction(
                      () => PdfReportService(
                        courseId: widget.courseId,
                        topicId: widget.topicId,
                        topicResults: _controller.topicResults,
                        getTranslatedText: (text) => L10n.getTranslatedText(context, text),
                      ).generateAndDownloadReport(),
                    ),
                    onShareScore: () => _handlePdfAction(
                      () => PdfReportService(
                        courseId: widget.courseId,
                        topicId: widget.topicId,
                        topicResults: _controller.topicResults,
                        getTranslatedText: (text) => L10n.getTranslatedText(context, text),
                      ).shareScore(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handlePdfAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
}