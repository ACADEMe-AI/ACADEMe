import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../academe_theme.dart';
import '../../api_endpoints.dart';

class SubTopicQuizScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String quizId;
  final String courseTitle;
  final String topicTitle;
  final String subtopicTitle;
  final String targetLanguage;

  const SubTopicQuizScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.quizId,
    required this.courseTitle,
    required this.topicTitle,
    required this.subtopicTitle,
    required this.targetLanguage,
  });

  @override
  SubTopicQuizScreenState createState() => SubTopicQuizScreenState();
}

class SubTopicQuizScreenState extends State<SubTopicQuizScreen> {
  final _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> quizQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint("📌 Quiz ID: ${widget.quizId}");
    _fetchQuizQuestions();
  }

  Future<void> _fetchQuizQuestions() async {
    final url = ApiEndpoints.getUri(ApiEndpoints.subtopicQuizQuestions(widget.courseId, widget.topicId, widget.subtopicId, widget.quizId, widget.targetLanguage));

    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return;
      }

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":
              "application/json; charset=UTF-8", // Ensure UTF-8 encoding
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data =
            json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
        setState(() {
          quizQuestions = data.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        _showError("Failed to fetch quiz questions: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Error fetching quiz questions: $e");
    }
  }

  void _addQuizQuestion() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController questionController =
            TextEditingController();
        List<TextEditingController> optionControllers = [
          TextEditingController(),
          TextEditingController(),
        ];
        int correctOption = 0;

        void addOption(setDialogState) {
          if (optionControllers.length < 4) {
            setDialogState(() {
              optionControllers.add(TextEditingController());
            });
          }
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(L10n.getTranslatedText(context, 'Add Quiz Question')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(labelText: L10n.getTranslatedText(context, 'Question')),
                    ),
                    ...List.generate(optionControllers.length, (index) {
                      return TextField(
                        controller: optionControllers[index],
                        decoration:
                            InputDecoration(labelText: "${L10n.getTranslatedText(context, 'Option')} ${index + 1}"),
                      );
                    }),
                    if (optionControllers.length < 4)
                      TextButton(
                        onPressed: () => addOption(setDialogState),
                        child: Text(L10n.getTranslatedText(context, 'Add Another Option')),
                      ),
                    DropdownButtonFormField<int>(
                      value: correctOption,
                      items: List.generate(optionControllers.length, (index) {
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text("${L10n.getTranslatedText(context, 'Correct Option')}: ${index + 1}"),
                        );
                      }),
                      onChanged: (value) {
                        setDialogState(() {
                          correctOption = value!;
                        });
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
                  onPressed: () async {
                    if (questionController.text.isNotEmpty &&
                        optionControllers.every(
                            (controller) => controller.text.isNotEmpty)) {
                      final success = await _submitQuizQuestion(
                        question: questionController.text,
                        options: optionControllers
                            .map((controller) => controller.text)
                            .toList(),
                        correctOption: correctOption,
                      );
                      if (!context.mounted) {
                        return; // Now properly wrapped in a block
                      }
                      if (success) {
                        Navigator.pop(context);
                        _fetchQuizQuestions();
                      }
                    }
                  },
                  child: Text(L10n.getTranslatedText(context, 'Add')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _submitQuizQuestion({
    required String question,
    required List<String> options,
    required int correctOption,
  }) async {
    final url = ApiEndpoints.getUri(ApiEndpoints.subtopicQuizQuestionsNoLang(widget.courseId, widget.topicId, widget.subtopicId, widget.quizId));

    try {
      String? token = await _storage.read(key: "access_token");
      if (token == null) {
        _showError("No access token found");
        return false;
      }

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type":
              "application/json; charset=UTF-8", // Ensure UTF-8 encoding
        },
        body: json.encode({
          "title": "New Quiz",
          "question_text": question,
          "options": options,
          "correct_option": correctOption,
          "target_language": widget.targetLanguage,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData =
            json.decode(utf8.decode(response.bodyBytes)); // Decode with UTF-8
        debugPrint(
            "✅ Quiz question added successfully: ${responseData["message"]}");
        return true;
      } else {
        _showError("❌ Failed to add quiz question: ${response.body}");
        return false;
      }
    } catch (e) {
      _showError("🚨 Error submitting quiz question: $e");
      return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          "${widget.courseTitle} > ${widget.topicTitle} > ${widget.subtopicTitle} > Quiz",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : quizQuestions.isEmpty
                ? Center(child: Text(L10n.getTranslatedText(context, 'No quiz questions added yet.')))
                : ListView.builder(
                    itemCount: quizQuestions.length,
                    itemBuilder: (context, index) {
                      final question = quizQuestions[index];
                      final options =
                          question["options"] as List<dynamic>? ?? [];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${index + 1}. ${question["question_text"]}",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Column(
                                children: options.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final optionText = entry.value.toString();
                                  return Container(
                                    margin: EdgeInsets.symmetric(vertical: 4),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: question["correct_option"] == idx
                                          ? Colors.green.withValues()
                                          : Colors.grey.withValues(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Text("${idx + 1}) ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Expanded(child: Text(optionText)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addQuizQuestion,
        backgroundColor: AcademeTheme.appColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
