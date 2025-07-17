import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ACADEMe/home/courses/overview/pdf_report_service.dart';

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
  Map<String, dynamic> visualData = {};
  Map<String, dynamic>? topicResults;
  bool isLoading = true;
  double overallAverage = 0;
  double topicScore = 0;
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _initStorage();
  }

  Future<void> _initStorage() async {
    await Future.wait([
      fetchProgressData(), // This loads from API
      _loadTopicResults(), // This loads our local quiz results
    ]);
  }

  Future<void> _loadTopicResults() async {
    final String storageKey =
        'quiz_results_${widget.courseId}_${widget.topicId}';
    String? resultsJson = await _secureStorage.read(key: storageKey);

    if (resultsJson != null) {
      setState(() {
        topicResults = json.decode(resultsJson);
        if (topicResults != null) {
          final int correct = topicResults!['correctAnswers'] ?? 0;
          final int total = topicResults!['totalQuestions'] ?? 1;
          topicScore = total > 0 ? (correct / total) * 100 : 0;

          // Initialize quizData if it doesn't exist
          if (!topicResults!.containsKey('quizData')) {
            topicResults!['quizData'] = [];
          }
        }
      });
    }
  }

  Future<void> fetchProgressData() async {
    setState(() => isLoading = true);

    try {
      final String? token = await _secureStorage.read(key: 'access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Missing access token - Please login again');
      }

      final response = await http.get(
        Uri.parse('$backendUrl/api/progress-visuals/'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> jsonData = jsonDecode(responseBody);

        setState(() {
          visualData = jsonData;
          overallAverage = calculateOverallAverage(jsonData['visual_data']);
        });
      } else {
        throw Exception('Failed to load progress data: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error fetching progress data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  double calculateOverallAverage(Map<String, dynamic> visualData) {
    double totalScore = 0;
    int totalQuizzes = 0;

    visualData.forEach((key, userData) {
      if (userData['quizzes'] > 0) {
        totalScore += (userData['avg_score'] as num).toDouble() *
            (userData['quizzes'] as num).toInt();
        totalQuizzes += (userData['quizzes'] as num).toInt();
      }
    });

    return totalQuizzes > 0 ? totalScore / totalQuizzes : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.getTranslatedText(context, 'Test Report'),
            style: GoogleFonts.poppins(fontSize: 22, color: Colors.white)),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopicScoreCard(),
                  SizedBox(height: 16),
                  _buildPerformanceGraph(),
                  SizedBox(height: 16),
                  _buildDetailedAnalysis(),
                  SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildTopicScoreCard() {
    final int correct = topicResults?['correctAnswers'] ?? 0;
    final int total = topicResults?['totalQuestions'] ?? 1;
    final String scoreText = total > 0
        ? "${topicScore.toStringAsFixed(0)}%"
        : L10n.getTranslatedText(context, 'No data');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AcademeTheme.appColor,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.getTranslatedText(context, 'Topic Performance'),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scoreText,
                        style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    Text(
                        "$correct/$total ${L10n.getTranslatedText(context, 'correct')}",
                        style: GoogleFonts.poppins(
                            fontSize: 14, color: Colors.white70)),
                  ],
                ),
                if (total > 0)
                  CircularProgressIndicator(
                    value: topicScore / 100,
                    color: _getProgressColor(topicScore),
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

  //Card For Overall score that shows score from API
  // Widget _buildOverallScoreCard() {
  //   return Card(
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //     color: AcademeTheme.appColor,
  //     elevation: 5,
  //     child: Padding(
  //       padding: EdgeInsets.all(20),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(L10n.getTranslatedText(context, 'Overall Score'),
  //               style: GoogleFonts.poppins(
  //                   fontSize: 18,
  //                   fontWeight: FontWeight.w500,
  //                   color: Colors.white70)),
  //           SizedBox(height: 8),
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             children: [
  //               Text("${overallAverage.toStringAsFixed(0)}/100",
  //                   style: GoogleFonts.poppins(
  //                       fontSize: 28,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.white)),
  //               CircularProgressIndicator(
  //                 value: overallAverage / 100,
  //                 color: _getProgressColor(overallAverage),
  //                 backgroundColor: Colors.white30,
  //                 strokeWidth: 6,
  //               ),
  //             ],
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

 Widget _buildPerformanceGraph() {
  final List<dynamic> quizData = topicResults?['quizData'] ?? [];

  // Limit to last 7 or more depending on your choice
  final displayData = quizData;

  return Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: displayData.isEmpty
        ? Center(
            child: Text(
              L10n.getTranslatedText(context, 'No quiz data available'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: displayData.length * 80, // More space per bar
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: List.generate(displayData.length, (index) {
                    final quiz = displayData[index];
                    final isCorrect = quiz['isCorrect'] == true;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: isCorrect ? 100 : 5,
                          width: 20,
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            colors: isCorrect
                                ? [Colors.greenAccent, Colors.teal]
                                : [Colors.redAccent, Colors.red.shade900],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ],
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < displayData.length) {
                            String title = displayData[index]['title'] ?? '';
                            return Container(
                              width: 60,
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 48,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.black87,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final title = displayData[groupIndex]['title'] ?? '';
                        final correct = displayData[groupIndex]['isCorrect'] == true;
                        return BarTooltipItem(
                          '$title\n${correct ? 'Correct' : 'Incorrect'}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}



  BarChartGroupData _buildBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [BarChartRodData(toY: y, color: Colors.blueAccent, width: 16)],
    );
  }

  SideTitles _bottomTitles(List<String> topics) {
    return SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        return Text(topics[value.toInt()],
            style: TextStyle(color: Colors.black, fontSize: 12));
      },
    );
  }

  Widget _buildDetailedAnalysis() {
    final int correct = topicResults?['correctAnswers'] ?? 0;
    final int total = topicResults?['totalQuestions'] ?? 1;
    final int incorrect = total - correct;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      elevation: 5,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.getTranslatedText(context, 'Detailed Performance'),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
            SizedBox(height: 10),
            _buildPerformanceRow(
                L10n.getTranslatedText(context, 'Correct Answers'),
                "$correct/$total",
                Colors.green),
            _buildPerformanceRow(
                L10n.getTranslatedText(context, 'Incorrect Answers'),
                "$incorrect/$total",
                Colors.redAccent),
            if (topicResults?['skipped'] != null)
              _buildPerformanceRow(
                  L10n.getTranslatedText(context, 'Skipped Questions'),
                  "${topicResults!['skipped']}",
                  Colors.orangeAccent),
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
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _buildActionButton(
        Icons.picture_as_pdf,
        L10n.getTranslatedText(context, 'Download Report'), 
        Colors.white,
        () => _handlePdfAction(
          () => PdfReportService(
            courseId: widget.courseId,
            topicId: widget.topicId,
            topicResults: topicResults,
            getTranslatedText: (text) => L10n.getTranslatedText(context, text),
          ).generateAndDownloadReport(),
        ),
      ),
      _buildActionButton(
        Icons.share,
        L10n.getTranslatedText(context, 'Share Score'), 
        Colors.white,
        () => _handlePdfAction(
          () => PdfReportService(
            courseId: widget.courseId,
            topicId: widget.topicId,
            topicResults: topicResults,
            getTranslatedText: (text) => L10n.getTranslatedText(context, text),
          ).shareScore(),
        ),
      ),
    ],
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
  Widget _buildActionButton(
  IconData icon, 
  String label, 
  Color color, 
  VoidCallback onPressed,
) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: Colors.black),
    label: Text(label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}


  Color _getProgressColor(double score) {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
