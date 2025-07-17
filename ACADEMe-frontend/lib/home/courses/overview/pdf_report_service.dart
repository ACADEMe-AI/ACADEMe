import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:ACADEMe/home/courses/report.dart';

class PdfReportService {
  final String courseId;
  final String topicId;
  final Map<String, dynamic>? topicResults;
  final Function(String) getTranslatedText;

  PdfReportService({
    required this.courseId,
    required this.topicId,
    required this.topicResults,
    required this.getTranslatedText,
  });

  Future<void> generateAndDownloadReport() async {
    try {
      if (topicResults == null) {
        throw Exception(getTranslatedText('No report data available'));
      }

      final pdf = pw.Document(
        title: 'ACADEMe Quiz Report',
        author: 'ACADEMe App',
      );

      // Add pages to PDF
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => _buildCoverPage(),
      ));

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => _buildSummaryPage(),
      ));

      if (topicResults!['quizData'] != null &&
          (topicResults!['quizData'] as List).isNotEmpty) {
        pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildDetailedResultsPage(),
        ));
      }

      // Save and open the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('${getTranslatedText('Failed to generate report')}: $e');
    }
  }

  Future<void> shareScore() async {
    try {
      if (topicResults == null) {
        throw Exception(getTranslatedText('No score data available'));
      }

      final correct = topicResults?['correctAnswers'] ?? 0;
      final total = topicResults?['totalQuestions'] ?? 1;
      final score =
          total > 0 ? (correct / total * 100).toStringAsFixed(1) : '0';

      // Generate a simple PDF for sharing
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('ACADEMe Quiz Results',
                  style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Text('Score: $score%'),
              pw.Text('Correct: $correct/$total'),
              pw.SizedBox(height: 20),
              pw.Text('Course: $courseId'),
              pw.Text('Topic: $topicId'),
            ],
          );
        },
      ));

      // Save temporarily
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/quiz_results_share.pdf');
      await file.writeAsBytes(await pdf.save());

      // Share both text and PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${getTranslatedText('I scored')} $score% ${getTranslatedText('on')} $topicId '
            '${getTranslatedText('quiz in ACADEMe! Correct answers')}: $correct/$total',
      );
    } catch (e) {
      throw Exception('${getTranslatedText('Failed to share score')}: $e');
    }
  }

  // PDF building methods
  pw.Widget _buildCoverPage() {
    final correct = topicResults?['correctAnswers'] ?? 0;
    final total = topicResults?['totalQuestions'] ?? 1;
    final score = total > 0 ? (correct / total * 100) : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'ACADEMe',
            style: pw.TextStyle(
              fontSize: 36,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            '${getTranslatedText('Quiz Performance Report')}',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Container(
            width: 150,
            height: 150,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: _getScoreColor(score),
            ),
            child: pw.Center(
              child: pw.Text(
                '${score.toStringAsFixed(0)}%',
                style: pw.TextStyle(
                  fontSize: 36,
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Text(
            '${getTranslatedText('Course')}: $courseId',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.Text(
            '${getTranslatedText('Topic')}: $topicId',
            style: const pw.TextStyle(fontSize: 16),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            '${getTranslatedText('Date')}: ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryPage() {
    final correct = topicResults?['correctAnswers'] ?? 0;
    final total = topicResults?['totalQuestions'] ?? 1;
    final incorrect = total - correct;
    final score = total > 0 ? (correct / total * 100) : 0;
    final lastUpdated = topicResults?['lastUpdated'] != null
        ? DateFormat('MMMM dd, yyyy - HH:mm')
            .format(DateTime.parse(topicResults!['lastUpdated']))
        : 'N/A';

    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(
            level: 0,
            child: pw.Text(
              getTranslatedText('Performance Summary'),
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(
                      getTranslatedText('Overall Score'),
                      '${score.toStringAsFixed(1)}%',
                      _getScoreColor(score),
                    ),
                    pw.SizedBox(height: 20),
                    _buildSummaryCard(
                      getTranslatedText('Correct Answers'),
                      '$correct',
                      PdfColors.green,
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(
                      getTranslatedText('Total Questions'),
                      '$total',
                      PdfColors.blue,
                    ),
                    pw.SizedBox(height: 20),
                    _buildSummaryCard(
                      getTranslatedText('Incorrect Answers'),
                      '$incorrect',
                      PdfColors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),
          pw.Text(
            getTranslatedText('Performance Analysis'),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            _getPerformanceAnalysis(score),
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            '${getTranslatedText('Last Updated')}: $lastUpdated',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDetailedResultsPage() {
    final quizData = topicResults?['quizData'] ?? [];

    return pw.Container(
      padding: const pw.EdgeInsets.all(40),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Header(
            level: 0,
            child: pw.Text(
              getTranslatedText('Detailed Quiz Results'),
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              getTranslatedText('Quiz Title'),
              getTranslatedText('Result'),
              getTranslatedText('Date'),
            ],
            data: quizData.map((quiz) {
              final title = quiz['title'] ?? getTranslatedText('Untitled Quiz');
              final result = quiz['isCorrect'] == true
                  ? getTranslatedText('Correct')
                  : getTranslatedText('Incorrect');
              final date = quiz['timestamp'] != null
                  ? DateFormat('MMM dd, yyyy')
                      .format(DateTime.parse(quiz['timestamp']))
                  : 'N/A';
              return [title, result, date];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.blue700,
            ),
            cellAlignment: pw.Alignment.centerLeft,
            cellStyle: const pw.TextStyle(fontSize: 12),
            rowDecoration: pw.BoxDecoration(
              color: PdfColors.grey100,
            ),
            border: pw.TableBorder.all(
              color: PdfColors.grey300,
              width: 1,
            ),
          )
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  PdfColor _getScoreColor(double score) {
    if (score >= 80) return PdfColors.green;
    if (score >= 60) return PdfColors.orange;
    return PdfColors.red;
  }

  String _getPerformanceAnalysis(double score) {
    if (score >= 90) {
      return getTranslatedText(
          'Excellent performance! You have demonstrated a thorough understanding of this topic. Keep up the great work!');
    } else if (score >= 75) {
      return getTranslatedText(
          'Good performance! You have a solid understanding of most concepts in this topic. Review the incorrect answers to improve further.');
    } else if (score >= 50) {
      return getTranslatedText(
          'Average performance. You understand some concepts but should review the material and try the quiz again to improve your score.');
    } else {
      return getTranslatedText(
          'Below average performance. We recommend reviewing the learning materials and retaking the quiz to reinforce your understanding.');
    }
  }
}
