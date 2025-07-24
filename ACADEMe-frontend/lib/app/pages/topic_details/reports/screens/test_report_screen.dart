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
  final String courseTitle;
  final String topicTitle;
  final String language;

  const TestReportScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.language,
  });

  @override
  TestReportScreenState createState() => TestReportScreenState();
}

class TestReportScreenState extends State<TestReportScreen> {
  late TestReportController _controller;
  late PdfReportService _pdfService;
  bool _isDownloadingPdf = false;
  bool _isSharingPdf = false;

  @override
  void initState() {
    super.initState();
    _controller = TestReportController(
      courseId: widget.courseId,
      topicId: widget.topicId,
      courseTitle: widget.courseTitle,
      topicTitle: widget.topicTitle,
      language: widget.language,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _initializePdfService();
    _initializeData();
  }

  Future<void> _initializePdfService() async {
    _pdfService = await PdfReportService.create(
      controller: _controller,
      logoAssetPath: 'assets/academe/academe_logo.png',
    );
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

  Future<void> _handleDownloadAction() async {
    if (_isDownloadingPdf) return;
    
    setState(() => _isDownloadingPdf = true);
    try {
      await _pdfService.generateAndDownloadReport();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  Future<void> _handleShareAction() async {
    if (_isSharingPdf) return;
    
    setState(() => _isSharingPdf = true);
    try {
      await _pdfService.shareScore(
        getTranslatedText: (text) => L10n.getTranslatedText(context, text),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSharingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          L10n.getTranslatedText(context, 'Test Report'),
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AcademeTheme.appColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _controller.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AcademeTheme.appColor,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TopicScoreCard(controller: _controller),
                  const SizedBox(height: 20),
                  PerformanceGraph(controller: _controller),
                  const SizedBox(height: 20),
                  DetailedAnalysis(controller: _controller),
                  const SizedBox(height: 20),
                  ActionButtons(
                    onDownloadReport: _handleDownloadAction,
                    onShareScore: _handleShareAction,
                    isDownloading: _isDownloadingPdf,
                    isSharing: _isSharingPdf,
                  ),
                ],
              ),
            ),
    );
  }
}