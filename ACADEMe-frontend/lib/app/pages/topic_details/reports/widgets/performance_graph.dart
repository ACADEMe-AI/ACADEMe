import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/test_report_controller.dart';

class PerformanceGraph extends StatelessWidget {
  final TestReportController controller;

  const PerformanceGraph({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> quizData = controller.getQuizData();
    final displayData = quizData;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
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
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: displayData.length * 80.0, // More space per bar
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
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        tooltipBgColor: Colors.black87,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final title = displayData[groupIndex]['title'] ?? '';
                          final correct =
                              displayData[groupIndex]['isCorrect'] == true;
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
}
