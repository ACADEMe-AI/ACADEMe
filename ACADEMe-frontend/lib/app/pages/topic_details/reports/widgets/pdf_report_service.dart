import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../controllers/test_report_controller.dart';

class PdfReportService {
  final TestReportController controller;
  final Uint8List logoImageBytes;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? userName;
  Map<String, String?> _userDetails = {};

  // Enhanced color scheme
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF1E3A8A);
  static const PdfColor secondaryBlue = PdfColor.fromInt(0xFF3B82F6);
  static const PdfColor lightBlue = PdfColor.fromInt(0xFFDBEAFE);
  static const PdfColor successGreen = PdfColor.fromInt(0xFF059669);
  static const PdfColor warningOrange = PdfColor.fromInt(0xFFD97706);
  static const PdfColor errorRed = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor neutralGray = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor lightGray = PdfColor.fromInt(0xFFF9FAFB);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFE5E7EB);

  PdfReportService({
    required this.controller,
    required this.logoImageBytes,
    this.userName,
  });

  static Future<Uint8List> _loadImageBytes(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  static Future<PdfReportService> create({
    required TestReportController controller,
    required String logoAssetPath,
    String? userName,
  }) async {
    final logoBytes = await _loadImageBytes(logoAssetPath);
    final service = PdfReportService(
      controller: controller,
      logoImageBytes: logoBytes,
      userName: userName,
    );
    
    if (service.userName == null) {
      await service._loadUserNameFromStorage();
    }
    
    return service;
  }

  Future<Map<String, String?>> getUserDetails() async {
    if (_userDetails.isNotEmpty) {
      return _userDetails;
    }

    try {
      final String? name = await _secureStorage.read(key: 'name');
      final String? photoUrl = await _secureStorage.read(key: 'photo_url');
      _userDetails = {
        'name': name,
        'photo_url': photoUrl,
      };
      return _userDetails;
    } catch (e) {
      debugPrint("Error getting user details: $e");
      return {
        'name': null,
        'photo_url': null,
      };
    }
  }

  Future<void> _loadUserNameFromStorage() async {
    try {
      final userDetails = await getUserDetails();
      userName = userDetails['name'];
      userName ??= 'Student';
    } catch (e) {
      debugPrint('Error loading username from secure storage: $e');
      userName = 'Student';
    }
  }

  Future<void> generateAndDownloadReport() async {
    try {
      if (userName == null) {
        await _loadUserNameFromStorage();
      }
      
      final pdf = await _generateReportDocument();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      throw Exception('Failed to generate report: $e');
    }
  }

  Future<void> shareScore({required Function(String) getTranslatedText}) async {
    try {
      if (userName == null) {
        await _loadUserNameFromStorage();
      }
      
      final pdf = await _generateReportDocument();
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/quiz_report_share.pdf');
      await file.writeAsBytes(await pdf.save());

      final topicScore = controller.topicScore;
      final metrics = controller.getPerformanceMetrics();
      final correct = metrics['correct'] ?? 0;
      final total = metrics['total'] ?? 1;

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            '${getTranslatedText('Here is my quiz report for')} ${controller.topicTitle} '
            '${getTranslatedText('in')} ${controller.courseTitle}. '
            '${getTranslatedText('I scored')} ${topicScore.toStringAsFixed(1)}% '
            '($correct/$total ${getTranslatedText('correct answers')})',
      );
    } catch (e) {
      throw Exception('${getTranslatedText('Failed to share score')}: $e');
    }
  }

  Future<pw.Document> _generateReportDocument() async {
    await controller.initialize();
    final pdf = pw.Document(
      title: 'Quiz Report - ${controller.courseTitle}',
      author: 'ACADEMe App',
    );
    pdf.addPage(await _buildEnhancedPage());
    return pdf;
  }

  Future<pw.Page> _buildEnhancedPage() async {
    final topicScore = controller.topicScore;
    final metrics = controller.getPerformanceMetrics();
    final correct = metrics['correct'] ?? 0;
    final incorrect = metrics['incorrect'] ?? 0;
    final skipped = metrics['skipped'] ?? 0;
    final total = metrics['total'] ?? 1;
    final logoImage = pw.MemoryImage(logoImageBytes);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(0),
      build: (pw.Context context) => pw.Column(
        children: [
          // Smaller header with gradient background
          _buildCompactHeader(logoImage),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(20), // Reduced padding
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildCompactUserInfoCard(),
                  pw.SizedBox(height: 16), // Reduced spacing
                  _buildCompactScoreOverviewCard(topicScore, correct, total),
                  pw.SizedBox(height: 16), // Reduced spacing
                  _buildCompactDetailedMetricsCard(correct, incorrect, skipped, total),
                  pw.SizedBox(height: 8), // Much smaller space before footer
                  _buildCompactFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactHeader(pw.ImageProvider logoImage) {
    return pw.Container(
      width: double.infinity,
      height: 80, // Reduced from 120 to 80
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryBlue, secondaryBlue],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12), // Reduced padding
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'QUIZ PERFORMANCE REPORT',
                  style: pw.TextStyle(
                    fontSize: 20, // Reduced from 24
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ACADEMe Assessment Platform',
                  style: pw.TextStyle(
                    fontSize: 10, // Reduced from 12
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ],
            ),
            pw.Container(
              height: 70, // Increased from 56
              width: 180, // Increased from 140
              child: pw.Image(
                logoImage,
                fit: pw.BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildCompactUserInfoCard() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16), // Reduced padding
      decoration: pw.BoxDecoration(
        color: lightBlue,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: borderGray, width: 1),
      ),
      child: pw.Row(
        children: [
          // Smaller User Avatar/Icon
          pw.Container(
            width: 48, // Reduced from 60
            height: 48,
            decoration: pw.BoxDecoration(
              color: primaryBlue,
              shape: pw.BoxShape.circle,
            ),
            child: pw.Center(
              child: pw.Text(
                userName != null && userName!.isNotEmpty 
                  ? userName!.substring(0, 1).toUpperCase()
                  : 'S',
                style: pw.TextStyle(
                  fontSize: 20, // Reduced from 24
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Student Information',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: neutralGray,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  userName ?? 'Student',
                  style: pw.TextStyle(
                    fontSize: 16, // Reduced from 20
                    fontWeight: pw.FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildInfoRow('Course:', controller.courseTitle),
                pw.SizedBox(height: 2),
                _buildInfoRow('Topic:', controller.topicTitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 11, // Reduced from 12
            color: neutralGray,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              color: primaryBlue,
              fontWeight: pw.FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactScoreOverviewCard(double score, int correct, int total) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18), // Reduced padding
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: borderGray, width: 2),
      ),
      child: pw.Row(
        children: [
          // Smaller Score Circle
          pw.Container(
            width: 90, // Reduced from 120
            height: 90,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              gradient: pw.LinearGradient(
                colors: [_getScoreColor(score), _getScoreColorLight(score)],
                begin: pw.Alignment.topLeft,
                end: pw.Alignment.bottomRight,
              ),
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '${score.toStringAsFixed(0)}%',
                    style: pw.TextStyle(
                      fontSize: 24, // Reduced from 32
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'SCORE',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 24), // Reduced spacing
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Overall Performance',
                  style: pw.TextStyle(
                    fontSize: 18, // Reduced from 24
                    fontWeight: pw.FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  _getPerformanceDescription(score),
                  style: pw.TextStyle(
                    fontSize: 14, // Reduced from 16
                    color: _getScoreColor(score),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                _buildScoreDetailRow('Correct Answers:', '$correct out of $total'),
                pw.SizedBox(height: 6),
                _buildScoreDetailRow('Accuracy Rate:', '${score.toStringAsFixed(1)}%'),
                pw.SizedBox(height: 6),
                _buildScoreDetailRow('Completion Date:', DateFormat('MMM dd, yyyy').format(DateTime.now())),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildScoreDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 12, // Reduced from 14
            color: neutralGray,
            fontWeight: pw.FontWeight.normal,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            color: primaryBlue,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactDetailedMetricsCard(int correct, int incorrect, int skipped, int total) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18), // Reduced padding
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: borderGray, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Detailed Performance Breakdown',
            style: pw.TextStyle(
              fontSize: 16, // Reduced from 20
              fontWeight: pw.FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          pw.SizedBox(height: 14), // Reduced spacing
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: [
              _buildCompactMetricCard('Correct', '$correct', successGreen, '${(correct / total * 100).toStringAsFixed(1)}%'),
              _buildCompactMetricCard('Incorrect', '$incorrect', errorRed, '${(incorrect / total * 100).toStringAsFixed(1)}%'),
              if (skipped > 0)
                _buildCompactMetricCard('Skipped', '$skipped', warningOrange, '${(skipped / total * 100).toStringAsFixed(1)}%'),
            ],
          ),
          pw.SizedBox(height: 14),
          _buildCompactProgressBar(correct, incorrect, skipped, total),
        ],
      ),
    );
  }

  pw.Widget _buildCompactMetricCard(String title, String value, PdfColor color, String percentage) {
    return pw.Container(
      width: 100, // Reduced from 120
      padding: const pw.EdgeInsets.all(12), // Reduced padding
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 10, // Reduced from 12
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20, // Reduced from 24
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            percentage,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCompactProgressBar(int correct, int incorrect, int skipped, int total) {
    final correctWidth = (correct / total) * 320; // Reduced bar width
    final incorrectWidth = (incorrect / total) * 320;
    final skippedWidth = (skipped / total) * 320;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Performance Distribution',
          style: pw.TextStyle(
            fontSize: 12, // Reduced from 14
            fontWeight: pw.FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 16, // Reduced from 20
          width: 320, // Reduced from 400
          decoration: pw.BoxDecoration(
            color: borderGray,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            children: [
              if (correctWidth > 0)
                pw.Container(
                  width: correctWidth,
                  height: 16,
                  decoration: pw.BoxDecoration(
                    color: successGreen,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: const pw.Radius.circular(8),
                      bottomLeft: const pw.Radius.circular(8),
                    ),
                  ),
                ),
              if (incorrectWidth > 0)
                pw.Container(
                  width: incorrectWidth,
                  height: 16,
                  color: errorRed,
                ),
              if (skippedWidth > 0)
                pw.Container(
                  width: skippedWidth,
                  height: 16,
                  decoration: pw.BoxDecoration(
                    color: warningOrange,
                    borderRadius: pw.BorderRadius.only(
                      topRight: const pw.Radius.circular(8),
                      bottomRight: const pw.Radius.circular(8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildCompactFooter() {
    return pw.Container(
      width: double.infinity,
      height: 48, // Reduced from 60
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderGray, width: 1),
      ),
      child: pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'Generated by ACADEMe Assessment Platform',
              style: pw.TextStyle(
                fontSize: 10, // Reduced from 12
                color: primaryBlue,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Report generated on ${DateFormat('EEEE, MMMM dd, yyyy \'at\' hh:mm a').format(DateTime.now())}',
              style: pw.TextStyle(
                fontSize: 8, // Reduced from 10
                color: neutralGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PdfColor _getScoreColor(double score) {
    if (score >= 80) return successGreen;
    if (score >= 60) return warningOrange;
    return errorRed;
  }

  PdfColor _getScoreColorLight(double score) {
    if (score >= 80) return PdfColor.fromInt(0xFF10B981);
    if (score >= 60) return PdfColor.fromInt(0xFFF59E0B);
    return PdfColor.fromInt(0xFFEF4444);
  }

  String _getPerformanceDescription(double score) {
    if (score >= 90) return 'Outstanding Performance!';
    if (score >= 80) return 'Excellent Work!';
    if (score >= 70) return 'Good Performance';
    if (score >= 60) return 'Fair Performance';
    return 'Needs Improvement';
  }
}