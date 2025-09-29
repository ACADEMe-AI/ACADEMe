import 'package:ACADEMe/app/admin_panel/widgets/edit_teacher_dialogbox.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../academe_theme.dart';
import '../../api_endpoints.dart';
import 'controllers/teacher_operations.dart';
import 'manage_teachers.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;

  const TeacherDetailsScreen({Key? key, required this.teacher}) : super(key: key);

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;

  // Teacher statistics with static data
  List<Map<String, dynamic>> attendanceData = [
    {'month': 'Jan', 'percentage': 85.0},
    {'month': 'Feb', 'percentage': 88.0},
    {'month': 'Mar', 'percentage': 90.0},
    {'month': 'Apr', 'percentage': 87.0},
    {'month': 'May', 'percentage': 89.0},
    {'month': 'Jun', 'percentage': 91.0},
  ];

  List<Map<String, dynamic>> performanceData = [
    {'class': '9A', 'score': 85.0},
    {'class': '9B', 'score': 78.0},
    {'class': '10A', 'score': 88.0},
    {'class': '10B', 'score': 82.0},
  ];

  Map<String, int> subjectDistribution = {
    'Mathematics': 8,
    'Physics': 6,
    'Chemistry': 5,
    'Biology': 5,
  };

  List<String> allottedClasses = [];
  int totalStudents = 0;
  int activeStudents = 0;
  int avgCompletion = 0;
  int avgQuizPerformance = 0;

  @override
  void initState() {
    super.initState();
    _loadTeacherDetails();
  }

  Future<void> _loadTeacherDetails() async {
    setState(() => _isLoading = true);

    String? token = await _storage.read(key: "access_token");
    if (token == null) {
      debugPrint("No token found");
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/api/admin/teachers/${widget.teacher['email']}/detailed'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
          "accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));

        setState(() {
          /// Extract allotted_classes
          allottedClasses = List<String>.from(data['basic_info']?['allotted_classes'] ?? []);

          /// Extract total_students from overall_performance
          totalStudents = data['overall_performance']?['total_students'] ?? 0;

          /// Extract more stats
          activeStudents = data['overall_performance']?['active_students'] ?? 0;
          avgCompletion = data['overall_performance']?['average_class_completion'] ?? 0;
          avgQuizPerformance = data['overall_performance']?['average_class_quiz_performance'] ?? 0;

          _isLoading = false;
        });
      } else {
        debugPrint("Failed to fetch teacher details: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error loading teacher details: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Details'),
        backgroundColor: AcademeTheme.appColor,
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.edit),
        //     onPressed: () {
        //       showDialog(
        //         context: context,
        //         builder: (context) {
        //           return EditTeacherDialog(
        //             teacher: widget.teacher,   // ✅ pass current teacher
        //             onUpdate: (email, name, subject, bio, classes) async {
        //               await ManageTeachersTabState.updateTeacher(
        //                 context,
        //                 email,
        //                 name,
        //                 subject,
        //                 bio,
        //                 classes,
        //               );
        //               // you can also call setState() here if you want to refresh details
        //               await _loadTeacherDetails();
        //             },
        //           );
        //         },
        //       );
        //     },
        //   ),
        // ],

      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadTeacherDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildAttendanceChart(),
              const SizedBox(height: 16),
              _buildPerformanceChart(),
              const SizedBox(height: 16),
              _buildSubjectDistributionPie(),
              const SizedBox(height: 16),
              _buildClassesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AcademeTheme.appColor,
              child: Text(
                (widget.teacher['name'] ?? 'T').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.teacher['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.teacher['email'] ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.teacher['is_active'] == true
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.teacher['is_active'] == true ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: widget.teacher['is_active'] == true
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Allotted Classes',
          allottedClasses.length.toString(),
          Icons.class_,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Students',
          totalStudents.toString(),
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Active Students',
          activeStudents.toString(),
          Icons.check_circle,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Performance',
          '$avgQuizPerformance%',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceChart() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attendance Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < attendanceData.length) {
                            return Text(
                              attendanceData[value.toInt()]['month'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: attendanceData
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                          e.key.toDouble(), e.value['percentage'].toDouble()))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.2),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Class Performance',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}%',
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < performanceData.length) {
                            return Text(
                              performanceData[value.toInt()]['class'],
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: performanceData
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['score'].toDouble(),
                        color: Colors.green,
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ))
                      .toList(),
                  minY: 0,
                  maxY: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectDistributionPie() {
    List<PieChartSectionData> sections = [];
    List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    int colorIndex = 0;
    subjectDistribution.forEach((subject, count) {
      sections.add(
        PieChartSectionData(
          value: count.toDouble(),
          title: '$count',
          color: colors[colorIndex % colors.length],
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
      colorIndex++;
    });

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: PieChart(
                      PieChartData(
                        sections: sections,
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: subjectDistribution.entries.map((entry) {
                        int index = subjectDistribution.keys.toList().indexOf(entry.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassesList() {
    List<dynamic> classes = widget.teacher['allotted_classes'] ?? [];

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Allotted Classes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: classes.map((className) {
                return Chip(
                  label: Text(className.toString()),
                  backgroundColor: AcademeTheme.appColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: AcademeTheme.appColor),
                );
              }).toList(),
            ),
            if (widget.teacher['bio'] != null && widget.teacher['bio'].isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Bio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.teacher['bio'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}