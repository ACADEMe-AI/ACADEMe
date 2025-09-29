import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../auth/auth_service.dart';

class TeacherLiveClassesScreen extends StatefulWidget {
  const TeacherLiveClassesScreen({super.key});

  @override
  State<TeacherLiveClassesScreen> createState() => _TeacherLiveClassesScreenState();
}

class _TeacherLiveClassesScreenState extends State<TeacherLiveClassesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> upcomingClasses = [];
  List<dynamic> recordedClasses = [];
  List<String> allottedClasses = [];
  bool isLoading = true;
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _loadUpcomingClasses(),
        _loadRecordedClasses(),
        _loadAllottedClasses(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingClasses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherUpcomingClasses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          upcomingClasses = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading upcoming classes: $e');
    }
  }

  Future<void> _loadRecordedClasses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherRecordedClasses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          recordedClasses = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error loading recorded classes: $e');
    }
  }

  Future<void> _loadAllottedClasses() async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherAllottedClasses),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          allottedClasses = List<String>.from(json.decode(response.body));
        });
      }
    } catch (e) {
      print('Error loading allotted classes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Live Classes & Recordings'),
          backgroundColor: AcademeTheme.appColor,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: "Schedule Classes"),
              Tab(text: "Recordings"),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadData,
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildScheduleClassesTab(),
            _buildRecordingsTab(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
            ? FloatingActionButton.extended(
                onPressed: _showScheduleClassDialog,
                backgroundColor: AcademeTheme.appColor,
                icon: Icon(Icons.add),
                label: Text('Schedule Class'),
              )
            : null,
      ),
    );
  }

  Widget _buildScheduleClassesTab() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUpcomingClasses,
      child: upcomingClasses.isEmpty
          ? _buildEmptyUpcomingState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: upcomingClasses.length,
              itemBuilder: (context, index) {
                final classData = upcomingClasses[index];
                return _buildUpcomingClassCard(classData);
              },
            ),
    );
  }

  Widget _buildEmptyUpcomingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Scheduled Classes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Schedule your first live class to get started',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showScheduleClassDialog,
            icon: Icon(Icons.add),
            label: Text('Schedule Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassCard(Map<String, dynamic> classData) {
    final status = classData['status'] ?? 'scheduled';
    final Color statusColor = status == 'live' ? Colors.green : 
                             status == 'completed' ? Colors.blue : 
                             AcademeTheme.appColor;

    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['title'] ?? 'Untitled Class',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AcademeTheme.appColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Class: ${classData['class_name'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (classData['description'] != null && classData['description'].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  classData['description'],
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  _formatDateTime(classData['scheduled_time']),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  'Duration: ${classData['duration'] ?? '45 minutes'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  'Platform: ${classData['platform'] ?? 'Zoom'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                if (status == 'scheduled')
                  ElevatedButton.icon(
                    onPressed: () => _startClass(classData['id']),
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: Text('Start Class'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (status == 'live')
                  ElevatedButton.icon(
                    onPressed: () => _joinClass(classData['meeting_url']),
                    icon: Icon(Icons.video_call, size: 16),
                    label: Text('Join Class'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _editClass(classData),
                  icon: Icon(Icons.edit, size: 16),
                  label: Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AcademeTheme.appColor,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => _deleteClass(classData['id']),
                  icon: Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingsTab() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AcademeTheme.appColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecordedClasses,
      child: recordedClasses.isEmpty
          ? _buildEmptyRecordingsState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: recordedClasses.length,
              itemBuilder: (context, index) {
                final recording = recordedClasses[index];
                return _buildRecordingCard(recording);
              },
            ),
    );
  }

  Widget _buildEmptyRecordingsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            'No Recorded Classes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Your completed live classes will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingCard(Map<String, dynamic> recording) {
    final hasRecording = recording['recording_url'] != null && recording['recording_url'].isNotEmpty;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasRecording ? Icons.video_library : Icons.video_library_outlined,
                  color: hasRecording ? AcademeTheme.appColor : Colors.grey,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recording['title'] ?? 'Untitled Recording',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasRecording)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AVAILABLE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Class: ${recording['class_name'] ?? 'N/A'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              'Recorded: ${_formatDateTime(recording['scheduled_time'])}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (recording['description'] != null && recording['description'].isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  recording['description'],
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            SizedBox(height: 12),
            Row(
              children: [
                if (hasRecording) ...[
                  ElevatedButton.icon(
                    onPressed: () => _playRecording(recording['recording_url']),
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcademeTheme.appColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _shareRecording(recording),
                    icon: Icon(Icons.share, size: 16),
                    label: Text('Share'),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () => _uploadRecording(recording),
                    icon: Icon(Icons.upload, size: 16),
                    label: Text('Upload Recording'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'download' && hasRecording) {
                      _downloadRecording(recording['recording_url']);
                    } else if (value == 'delete') {
                      _deleteRecording(recording['id']);
                    }
                  },
                  itemBuilder: (context) => [
                    if (hasRecording)
                      PopupMenuItem(
                        value: 'download',
                        child: Row(
                          children: [
                            Icon(Icons.download),
                            SizedBox(width: 8),
                            Text('Download'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleClassDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final meetingUrlController = TextEditingController();
    String selectedClass = allottedClasses.isNotEmpty ? allottedClasses.first : '';
    String selectedPlatform = 'Zoom';
    String selectedDuration = '45 minutes';
    DateTime selectedDateTime = DateTime.now().add(Duration(hours: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Schedule New Class'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Class Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClass.isNotEmpty ? selectedClass : null,
                  decoration: InputDecoration(
                    labelText: 'Select Class',
                    border: OutlineInputBorder(),
                  ),
                  items: allottedClasses.map((className) {
                    return DropdownMenuItem(
                      value: className,
                      child: Text(className),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClass = value ?? '';
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPlatform,
                  decoration: InputDecoration(
                    labelText: 'Platform',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Zoom', 'Google Meet', 'Microsoft Teams'].map((platform) {
                    return DropdownMenuItem(
                      value: platform,
                      child: Text(platform),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedPlatform = value ?? 'Zoom';
                    });
                  },
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedDuration,
                  decoration: InputDecoration(
                    labelText: 'Duration',
                    border: OutlineInputBorder(),
                  ),
                  items: ['30 minutes', '45 minutes', '60 minutes', '90 minutes', '120 minutes'].map((duration) {
                    return DropdownMenuItem(
                      value: duration,
                      child: Text(duration),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedDuration = value ?? '45 minutes';
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: meetingUrlController,
                  decoration: InputDecoration(
                    labelText: 'Meeting URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Date & Time'),
                  subtitle: Text(_formatDateTime(selectedDateTime.toIso8601String())),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _scheduleClass({
                'title': titleController.text,
                'description': descriptionController.text,
                'class_name': selectedClass,
                'platform': selectedPlatform,
                'scheduled_time': selectedDateTime.toIso8601String(),
                'meeting_url': meetingUrlController.text,
                'duration': selectedDuration,
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: AcademeTheme.appColor,
              ),
              child: Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scheduleClass(Map<String, dynamic> classData) async {
    if (classData['title'].trim().isEmpty || classData['class_name'].isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in required fields')),
      );
      return;
    }

    try {
      final token = await authService.getAccessToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.scheduleClass),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(classData),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class scheduled successfully!')),
        );
        _loadUpcomingClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to schedule class')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _startClass(String classId) async {
    try {
      final token = await authService.getAccessToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.startClass(classId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class started successfully!')),
        );
        _loadUpcomingClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start class')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _joinClass(String? meetingUrl) {
    if (meetingUrl != null && meetingUrl.isNotEmpty) {
      // Launch URL or navigate to meeting
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Opening meeting URL: $meetingUrl')),
      );
    }
  }

  void _editClass(Map<String, dynamic> classData) {
    // Implementation for editing class
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit class feature coming soon!')),
    );
  }

  void _deleteClass(String classId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Class'),
        content: Text('Are you sure you want to delete this scheduled class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for deleting class
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete class feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _playRecording(String recordingUrl) {
    // Implementation for playing recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Playing recording: $recordingUrl')),
    );
  }

  void _shareRecording(Map<String, dynamic> recording) {
    // Implementation for sharing recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share recording feature coming soon!')),
    );
  }

  void _uploadRecording(Map<String, dynamic> recording) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload Recording'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide the recording URL for: ${recording['title']}'),
            SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: InputDecoration(
                labelText: 'Recording URL',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitRecordingUrl(recording['id'], urlController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AcademeTheme.appColor),
            child: Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRecordingUrl(String classId, String recordingUrl) async {
    if (recordingUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid URL')),
      );
      return;
    }

    try {
      final token = await authService.getAccessToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.shareRecording),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'class_id': classId,
          'recording_url': recordingUrl.trim(),
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording uploaded successfully!')),
        );
        _loadRecordedClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload recording')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _downloadRecording(String recordingUrl) {
    // Implementation for downloading recording
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Download recording feature coming soon!')),
    );
  }

  void _deleteRecording(String recordingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Recording'),
        content: Text('Are you sure you want to delete this recording? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implementation for deleting recording
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Delete recording feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}