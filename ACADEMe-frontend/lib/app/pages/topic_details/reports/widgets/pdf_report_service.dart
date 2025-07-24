import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import '../controllers/test_report_controller.dart';

class PdfReportService {
  final TestReportController controller;
  final Uint8List logoImageBytes;

  PdfReportService({
    required this.controller,
    required this.logoImageBytes,
  });

  static Future<Uint8List> _loadImageBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  static Future<PdfReportService> create({
    required TestReportController controller,
    required String logoAssetPath,
  }) async {
    final logoBytes = await _loadImageBytes(logoAssetPath);
    return PdfReportService(
      controller: controller,
      logoImageBytes: logoBytes,
    );
  }

  Future<void> generateAndDownloadReport() async {
    try {
      await controller.initialize();
      final pdf = pw.Document(
        title: 'Quiz Report - ${controller.courseTitle}',
        author: 'ACADEMe App',
      );

      pdf.addPage(await _buildComprehensivePage());
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  Future<pw.Page> _buildComprehensivePage() async {
    final topicScore = controller.topicScore;
    final metrics = controller.getPerformanceMetrics();
    final correct = metrics['correct'] ?? 0;
    final incorrect = metrics['incorrect'] ?? 0;
    final skipped = metrics['skipped'] ?? 0;
    final total = metrics['total'] ?? 1;
    final allQuizAttempts = await _getAllQuizAttempts();
    final logoImage = pw.MemoryImage(logoImageBytes);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) => pw.Padding(
        padding: const pw.EdgeInsets.all(30),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(logoImage, topicScore, correct, total),
            pw.SizedBox(height: 30),
            _buildPerformanceMetricsSection(
                topicScore, correct, incorrect, skipped, total),
            pw.SizedBox(height: 30),
            _buildQuizAttemptsSection(allQuizAttempts),
            pw.SizedBox(height: 20),
            pw.Divider(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildHeaderSection(
      pw.ImageProvider logoImage, double topicScore, int correct, int total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Image(
          logoImage,
          width: 500, // Increased width
          height: 120, // Increased height
          fit: pw.BoxFit.contain,
        ),
        pw.SizedBox(height: 15),
        pw.Text(
          'Quiz Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          controller.courseTitle,
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(
          controller.topicTitle,
          style: const pw.TextStyle(fontSize: 16),
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            _buildScoreCircle(topicScore),
            pw.SizedBox(width: 20),
            _buildScoreDetails(correct, total, topicScore),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildScoreCircle(double score) {
    return pw.Container(
      width: 100,
      height: 100,
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        color: _getScoreColor(score),
      ),
      child: pw.Center(
        child: pw.Text(
          '${score.toStringAsFixed(0)}%',
          style: pw.TextStyle(
            fontSize: 24,
            color: PdfColors.white,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildScoreDetails(int correct, int total, double score) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Overall Performance',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          '$correct/$total correct answers',
          style: const pw.TextStyle(fontSize: 14),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          _getPerformanceDescription(score),
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildPerformanceMetricsSection(
      double topicScore, int correct, int incorrect, int skipped, int total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Performance Metrics',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _buildMiniMetricCard('Score', '${topicScore.toStringAsFixed(1)}%',
                _getScoreColor(topicScore)),
            _buildMiniMetricCard('Correct', '$correct', PdfColors.green),
            _buildMiniMetricCard('Incorrect', '$incorrect', PdfColors.red),
            if (skipped > 0)
              _buildMiniMetricCard('Skipped', '$skipped', PdfColors.orange),
          ],
        ),
        pw.SizedBox(height: 15),
        _buildPerformanceTable(correct, incorrect, skipped, total),
      ],
    );
  }

  pw.Widget _buildPerformanceTable(
      int correct, int incorrect, int skipped, int total) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeaderCell('Metric'),
            _buildTableHeaderCell('Count'),
            _buildTableHeaderCell('Percentage'),
          ],
        ),
        _buildPerformanceRow(
          'Correct Answers',
          '$correct',
          '${(correct / total * 100).toStringAsFixed(1)}%',
          PdfColors.green,
        ),
        _buildPerformanceRow(
          'Incorrect Answers',
          '$incorrect',
          '${(incorrect / total * 100).toStringAsFixed(1)}%',
          PdfColors.red,
        ),
        if (skipped > 0)
          _buildPerformanceRow(
            'Skipped Questions',
            '$skipped',
            '${(skipped / total * 100).toStringAsFixed(1)}%',
            PdfColors.orange,
          ),
      ],
    );
  }

  pw.Widget _buildQuizAttemptsSection(
      List<Map<String, dynamic>> allQuizAttempts) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Quiz Attempts',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        allQuizAttempts.isNotEmpty
            ? _buildQuizAttemptsTable(allQuizAttempts)
            : _buildNoAttemptsMessage(),
      ],
    );
  }

  pw.Widget _buildQuizAttemptsTable(List<Map<String, dynamic>> attempts) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeaderCell('Subtopic'),
            _buildTableHeaderCell('Quiz'),
            _buildTableHeaderCell('Score'),
            _buildTableHeaderCell('Correct'),
            _buildTableHeaderCell('Date'),
          ],
        ),
        ...attempts
            .map((attempt) => pw.TableRow(
                  children: [
                    _buildTableCell(attempt['subtopic']),
                    _buildTableCell(attempt['quiz']),
                    _buildScoreCell(attempt['score']),
                    _buildTableCell(
                        '${attempt['correct']}/${attempt['total']}'),
                    _buildTableCell(attempt['date']),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildNoAttemptsMessage() {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        'No quiz attempts available',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Generated on ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
      ),
    );
  }

  pw.Widget _buildMiniMetricCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 80,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.TableRow _buildPerformanceRow(
      String label, String count, String percentage, PdfColor color) {
    return pw.TableRow(
      children: [
        _buildTableCell(label),
        _buildTableCell(count),
        _buildPercentageCell(percentage, color),
      ],
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  pw.Widget _buildScoreCell(double score) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: _getScoreColor(score),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          '${score.toStringAsFixed(0)}%',
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  pw.Widget _buildPercentageCell(String percentage, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Container(
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          percentage,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 12,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAllQuizAttempts() async {
    final subtopics = controller.subtopicsWithQuizzes;
    final List<Map<String, dynamic>> allQuizAttempts = [];

    for (var subtopic in subtopics) {
      final quizzes = subtopic['quizzes'] as List<dynamic>? ?? [];

      for (var quiz in quizzes) {
        final quizId = quiz['id'].toString();
        final results = await controller.getLocalQuizResults(quizId);

        if (results != null && results['attempts'] != null) {
          for (var attempt in results['attempts']) {
            allQuizAttempts
                .add(_createAttemptRecord(subtopic, quiz, attempt, quizId));
          }
        } else if (results != null) {
          allQuizAttempts
              .add(_createAttemptRecord(subtopic, quiz, results, quizId));
        }
      }
    }
    return allQuizAttempts;
  }

  Map<String, dynamic> _createAttemptRecord(
      dynamic subtopic, dynamic quiz, dynamic results, String quizId) {
    final correct = results['correctAnswers'] ?? 0;
    final total = results['totalQuestions'] ?? 1;
    final score = (correct / total) * 100;

    return {
      'subtopic': subtopic['title'] ?? 'Untitled Subtopic',
      'quiz': quiz['title'] ?? 'Untitled Quiz',
      'score': score,
      'correct': correct,
      'total': total,
      'date': _formatDate(results['completedAt']),
      'quizId': quizId,
    };
  }

  String _formatDate(dynamic date) {
    try {
      if (date is String) {
        return DateFormat('MMM dd, yyyy').format(DateTime.parse(date));
      }
      return 'N/A';
    } catch (e) {
      return 'N/A';
    }
  }

  PdfColor _getScoreColor(double score) {
    if (score >= 80) return PdfColors.green;
    if (score >= 60) return PdfColors.orange;
    return PdfColors.red;
  }

  String _getPerformanceDescription(double score) {
    if (score >= 80) return 'Excellent performance!';
    if (score >= 60) return 'Good performance';
    return 'Needs improvement';
  }

  Future<void> shareScore({required Function(String) getTranslatedText}) async {
    try {
      final metrics = controller.getPerformanceMetrics();
      final topicScore = controller.topicScore;
      final correct = metrics['correct'] ?? 0;
      final total = metrics['total'] ?? 1;
      final logoImage = pw.MemoryImage(logoImageBytes);

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Center(
                  child: pw.Image(
                    logoImage,
                    width: 150,
                    height: 50,
                    fit: pw.BoxFit.contain,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Text(
                  'Quiz Results',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  controller.courseTitle,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  controller.topicTitle,
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 30),
                _buildScoreCircle(topicScore),
                pw.SizedBox(height: 20),
                pw.Text(
                  '$correct/$total ${getTranslatedText('correct answers')}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/quiz_results_share.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${getTranslatedText('I scored')} ${topicScore.toStringAsFixed(1)}% '
            '${getTranslatedText('on')} ${controller.topicTitle} ${getTranslatedText('in')} ${controller.courseTitle} '
            '($correct/$total ${getTranslatedText('correct answers')})',
      );
    } catch (e) {
      throw Exception('${getTranslatedText('Failed to share score')}: $e');
    }
  }
}
