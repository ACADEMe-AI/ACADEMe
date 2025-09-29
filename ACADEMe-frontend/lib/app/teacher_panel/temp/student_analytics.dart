import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../../../localization/l10n.dart';

class StudentAnalytics extends StatefulWidget {
  const StudentAnalytics({super.key});

  @override
  StudentAnalyticsState createState() => StudentAnalyticsState();
}

class StudentAnalyticsState extends State<StudentAnalytics> {
  final _storage = FlutterSecureStorage();
  bool isLoading = true;
  List<Map<String, dynamic>> allottedClasses = [];
  String? selectedClass;
  List<Map<String, dynamic>> students = [];
  Map<String, dynamic>? analyticsData;

  @override
  void initState() {
    super.initState();
    _fetchAllottedClasses();
  }

  Future<void> _fetchAllottedClasses() async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherAllottedClasses),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          allottedClasses = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch allotted classes: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching allotted classes: $e");
    }
  }

  Future<void> _fetchStudentsByClass(String className) async {
    setState(() => isLoading = true);
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.studentsByClass(className)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          students = data.cast<Map<String, dynamic>>();
        });
        await _fetchAnalyticsData(className);
      } else {
        _showError("Failed to fetch students: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching students: $e");
    }
  }

  Future<void> _fetchAnalyticsData(String className) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.classAnalytics(className)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          analyticsData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching analytics: $e");
    }
    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  Widget _buildClassSelector() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Select Class'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedClass,
              hint: Text(L10n.getTranslatedText(context, 'Choose a class')),
              items: allottedClasses.map((classData) {
                return DropdownMenuItem<String>(
                  value: classData['class_name'],
                  child: Text('Class ${classData['class_name']}'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClass = value;
                  students.clear();
                  analyticsData = null;
                });
                if (value != null) {
                  _fetchStudentsByClass(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    if (analyticsData == null) return SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.people, color: Colors.blue, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '${students.length}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(L10n.getTranslatedText(context, 'Total Students')),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.trending_up, color: Colors.green, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '${analyticsData?['average_score']?.toStringAsFixed(1) ?? '0.0'}%',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(L10n.getTranslatedText(context, 'Avg Score')),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange, size: 32),
                    SizedBox(height: 8),
                    Text(
                      '${analyticsData?['active_students'] ?? 0}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(L10n.getTranslatedText(context, 'Active This Week')),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart() {
    if (analyticsData == null || analyticsData!['performance_data'] == null) {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Class Performance'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: (analyticsData!['performance_data'] as List)
                          .asMap()
                          .entries
                          .map((entry) => FlSpot(
                          entry.key.toDouble(), entry.value.toDouble()))
                          .toList(),
                      isCurved: true,
                      color: AcademeTheme.appColor,
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (students.isEmpty) return SizedBox.shrink();

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Students List'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: students.length,
              itemBuilder: (context, index) {
                final student = students[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      student['photo_url'] ??
                          'https://www.w3schools.com/w3images/avatar2.png',
                    ),
                  ),
                  title: Text(student['name'] ?? 'Unknown'),
                  subtitle: Text(student['email'] ?? ''),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${student['progress']?.toStringAsFixed(0) ?? '0'}%',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        L10n.getTranslatedText(context, 'Progress'),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () => _showStudentDetails(student),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStudentDetails(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(student['name'] ?? 'Student Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${student['email'] ?? 'N/A'}'),
            SizedBox(height: 8),
            Text('Progress: ${student['progress']?.toStringAsFixed(1) ?? '0'}%'),
            SizedBox(height: 8),
            Text('Quizzes Completed: ${student['quizzes_completed'] ?? 0}'),
            SizedBox(height: 8),
            Text('Average Score: ${student['average_score']?.toStringAsFixed(1) ?? '0'}%'),
            SizedBox(height: 8),
            Text('Last Activity: ${student['last_activity'] ?? 'Never'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(L10n.getTranslatedText(context, 'Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildClassSelector(),
            if (selectedClass != null) ...[
              _buildOverviewCards(),
              _buildPerformanceChart(),
              _buildStudentsList(),
            ],
          ],
        ),
      ),
    );
  }
}
