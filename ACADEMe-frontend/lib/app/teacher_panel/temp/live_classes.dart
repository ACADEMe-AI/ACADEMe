import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../academe_theme.dart';
import '../../../api_endpoints.dart';
import '../../../localization/l10n.dart';

class LiveClasses extends StatefulWidget {
  const LiveClasses({super.key});

  @override
  LiveClassesState createState() => LiveClassesState();
}

class LiveClassesState extends State<LiveClasses>
    with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  late TabController _tabController;
  bool isLoading = true;

  List<Map<String, dynamic>> upcomingClasses = [];
  List<Map<String, dynamic>> recordedClasses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchLiveClasses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLiveClasses() async {
    setState(() => isLoading = true);
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      // Fetch upcoming classes
      final upcomingResponse = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherUpcomingClasses),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      // Fetch recorded classes
      final recordedResponse = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherRecordedClasses),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (upcomingResponse.statusCode == 200 &&
          recordedResponse.statusCode == 200) {
        final upcomingData = json.decode(
            utf8.decode(upcomingResponse.bodyBytes));
        final recordedData = json.decode(
            utf8.decode(recordedResponse.bodyBytes));

        setState(() {
          upcomingClasses = List<Map<String, dynamic>>.from(upcomingData);
          recordedClasses = List<Map<String, dynamic>>.from(recordedData);
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch classes");
      }
    } catch (e) {
      _showError("Error fetching classes: $e");
    }
    setState(() => isLoading = false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  void _scheduleClass() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController titleController = TextEditingController();
        final TextEditingController descriptionController = TextEditingController();
        final TextEditingController classNameController = TextEditingController();
        DateTime? selectedDate;
        TimeOfDay? selectedTime;
        String? meetingPlatform = 'Zoom';

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  L10n.getTranslatedText(context, 'Schedule Live Class')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(
                            context, 'Class Title'),
                      ),
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(
                            context, 'Description'),
                      ),
                      maxLines: 3,
                    ),
                    TextField(
                      controller: classNameController,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(
                            context, 'Class Name'),
                      ),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: meetingPlatform,
                      decoration: InputDecoration(
                        labelText: L10n.getTranslatedText(context, 'Platform'),
                      ),
                      items: ['Zoom', 'Google Meet', 'Microsoft Teams']
                          .map((platform) =>
                          DropdownMenuItem(
                            value: platform,
                            child: Text(platform),
                          ))
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => meetingPlatform = value),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.calendar_today),
                      title: Text(selectedDate == null
                          ? L10n.getTranslatedText(context, 'Select Date')
                          : '${selectedDate!.day}/${selectedDate!
                          .month}/${selectedDate!.year}'),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.access_time),
                      title: Text(selectedTime == null
                          ? L10n.getTranslatedText(context, 'Select Time')
                          : '${selectedTime!.hour}:${selectedTime!.minute
                          .toString().padLeft(2, '0')}'),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() => selectedTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(L10n.getTranslatedText(context, 'Cancel')),
                ),
                ElevatedButton(
                  onPressed: (titleController.text.isNotEmpty &&
                      classNameController.text.isNotEmpty &&
                      selectedDate != null &&
                      selectedTime != null)
                      ? () async {
                    await _submitScheduleClass(
                      title: titleController.text,
                      description: descriptionController.text,
                      className: classNameController.text,
                      platform: meetingPlatform!,
                      date: selectedDate!,
                      time: selectedTime!,
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                      : null,
                  child: Text(L10n.getTranslatedText(context, 'Schedule')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitScheduleClass({
    required String title,
    required String description,
    required String className,
    required String platform,
    required DateTime date,
    required TimeOfDay time,
  }) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final DateTime scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.scheduleClass),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "title": title,
          "description": description,
          "class_name": className,
          "platform": platform,
          "scheduled_time": scheduledDateTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _fetchLiveClasses(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(
                context, 'Class scheduled successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("Failed to schedule class");
      }
    } catch (e) {
      _showError("Error scheduling class: $e");
    }
  }

  Future<void> _startClass(String classId) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.startClass(classId)),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(utf8.decode(response.bodyBytes));
        final meetingUrl = responseData['meeting_url'];

        if (meetingUrl != null) {
          await launchUrl(Uri.parse(meetingUrl));
        }
      } else {
        _showError("Failed to start class");
      }
    } catch (e) {
      _showError("Error starting class: $e");
    }
  }

  Future<void> _viewRecording(String recordingUrl) async {
    try {
      await launchUrl(Uri.parse(recordingUrl));
    } catch (e) {
      _showError("Cannot open recording");
    }
  }

  Widget _buildUpcomingTab() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _scheduleClass,
            icon: Icon(Icons.add),
            label: Text(L10n.getTranslatedText(context, 'Schedule New Class')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        Expanded(
          child: upcomingClasses.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  L10n.getTranslatedText(context, 'No upcoming classes'),
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          )
              : ListView.builder(
            itemCount: upcomingClasses.length,
            itemBuilder: (context, index) {
              final classData = upcomingClasses[index];
              final DateTime scheduledTime = DateTime.parse(
                  classData['scheduled_time']);
              final bool isToday = DateTime
                  .now()
                  .difference(scheduledTime)
                  .inDays == 0;
              final bool canStart = DateTime.now().isAfter(
                  scheduledTime.subtract(Duration(minutes: 15)));

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isToday ? Colors.green : AcademeTheme.appColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.video_call,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(classData['title'] ?? 'Unknown Class'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class: ${classData['class_name'] ?? 'N/A'}'),
                      Text('Time: ${scheduledTime.hour}:${scheduledTime.minute
                          .toString().padLeft(2, '0')}'),
                      Text('Platform: ${classData['platform'] ?? 'Unknown'}'),
                      if (classData['description']?.isNotEmpty ?? false)
                        Text('Description: ${classData['description']}'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (canStart)
                        ElevatedButton(
                          onPressed: () => _startClass(classData['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: Size(80, 32),
                          ),
                          child: Text('Start'),
                        )
                      else
                        Text(
                          'Starts in ${scheduledTime
                              .difference(DateTime.now())
                              .inMinutes}m',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecordedTab() {
    return recordedClasses.isEmpty
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            L10n.getTranslatedText(context, 'No recorded classes yet'),
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    )
        : ListView.builder(
      itemCount: recordedClasses.length,
      itemBuilder: (context, index) {
        final recording = recordedClasses[index];
        final DateTime recordedDate = DateTime.parse(
            recording['recorded_date']);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_circle,
                color: Colors.white,
              ),
            ),
            title: Text(recording['title'] ?? 'Unknown Recording'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Class: ${recording['class_name'] ?? 'N/A'}'),
                Text('Recorded: ${recordedDate.day}/${recordedDate
                    .month}/${recordedDate.year}'),
                Text('Duration: ${recording['duration'] ?? 'Unknown'}'),
                if (recording['description']?.isNotEmpty ?? false)
                  Text('Description: ${recording['description']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _viewRecording(recording['recording_url']),
                  icon: Icon(Icons.play_arrow),
                  tooltip: L10n.getTranslatedText(context, 'Play Recording'),
                ),
                IconButton(
                  onPressed: () => _shareRecording(recording),
                  icon: Icon(Icons.share),
                  tooltip: L10n.getTranslatedText(context, 'Share'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _shareRecording(Map<String, dynamic> recording) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(L10n.getTranslatedText(context, 'Share Recording')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Recording: ${recording['title']}'),
              SizedBox(height: 16),
              Text('Share with:'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Share with specific class
                  Navigator.pop(context);
                  _shareWithClass(recording['id'], recording['class_name']);
                },
                child: Text('Class ${recording['class_name']}'),
              ),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // Share with all students
                  Navigator.pop(context);
                  _shareWithAllStudents(recording['id']);
                },
                child: Text(L10n.getTranslatedText(context, 'All Students')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(L10n.getTranslatedText(context, 'Cancel')),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareWithClass(String recordingId, String className) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.shareRecording),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "recording_id": recordingId,
          "share_with": "class",
          "class_name": className,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(
                context, 'Recording shared successfully')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("Failed to share recording");
      }
    } catch (e) {
      _showError("Error sharing recording: $e");
    }
  }

  Future<void> _shareWithAllStudents(String recordingId) async {
    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) return;

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.shareRecording),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json; charset=UTF-8",
        },
        body: json.encode({
          "recording_id": recordingId,
          "share_with": "all_students",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(L10n.getTranslatedText(
                context, 'Recording shared with all students')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError("Failed to share recording");
      }
    } catch (e) {
      _showError("Error sharing recording: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        labelColor: AcademeTheme.appColor,
        unselectedLabelColor: Colors.grey,
        tabs: [
          Tab(
            text: L10n.getTranslatedText(context, 'Upcoming'),
            icon: Icon(Icons.schedule),
          ),
          Tab(
            text: L10n.getTranslatedText(context, 'Recorded'),
            icon: Icon(Icons.video_library),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildRecordedTab(),
        ],
      ),
    );
  }
}
