import 'dart:convert';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/app/pages/progress/widgets/progress_loading_animation.dart';
import 'package:ACADEMe/app/pages/progress/widgets/text_formatter.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';

import '../../ask_me/screens/ask_me_screen.dart';
import '../controllers/progress_controller.dart';

void showMotivationPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return const MotivationPopup();
    },
  );
}

class MotivationPopup extends StatefulWidget {
  const MotivationPopup({super.key});

  @override
  MotivationPopupState createState() => MotivationPopupState();
}

class MotivationPopupState extends State<MotivationPopup> {
  late Future<String> _recommendationFuture;
  final TextEditingController _messageController = TextEditingController();
  final ProgressController _progressControl = ProgressController();

  @override
  void initState() {
    super.initState();
    _recommendationFuture = _fetchRecommendations();
  }

  /// **Fetch recommendations using ProgressController**
  Future<String> _fetchRecommendations() async {
    try {
      // Get the target language from the app's language provider
      final targetLanguage =
          Provider.of<LanguageProvider>(context, listen: false)
              .locale
              .languageCode;

      // Use the ProgressController to fetch recommendations
      final recommendations = await _progressControl.fetchRecommendations(
        targetLanguage: targetLanguage,
      );

      // Convert the response to string if it's not already
      if (recommendations is String) {
        return recommendations;
      } else {
        // If it's a complex object, you might want to format it
        return jsonEncode(recommendations);
      }
    } catch (error) {
      // Handle errors appropriately
      throw Exception("❌ Failed to fetch recommendations: $error");
    }
  }

  void _sendFollowUpToChatbot() async {
    String followUpMessage = _messageController.text.trim();

    // Debug: Print the follow-up message
    print('Follow-up message: "$followUpMessage"');

    if (followUpMessage.isNotEmpty) {
      String recommendationText = "";

      try {
        // Wait for the recommendation to complete
        recommendationText = await _recommendationFuture;
        print('Recommendation text length: ${recommendationText.length}');
        print(
            'Recommendation preview: ${recommendationText.substring(0, recommendationText.length > 100 ? 100 : recommendationText.length)}...');
      } catch (error) {
        print('Error fetching recommendation: $error');
        recommendationText =
            "⚠️ Error fetching recommendation. Please try again.";
      }

      // Combine Recommendation + Follow-up
      String fullMessage =
          "📊 Recommendation: \n$recommendationText\n\n🗨️ Follow-up: $followUpMessage";

      // Debug: Print the full message
      print('Full message length: ${fullMessage.length}');
      print('Navigation about to start...');

      if (!mounted) {
        print('Widget not mounted, returning early');
        return; // Ensure widget is still active before using context
      }

      try {
        // Close the current bottom sheet first
        Navigator.pop(context);

        // Small delay to ensure the bottom sheet is fully closed
        await Future.delayed(const Duration(milliseconds: 100));

        // Navigate to Chatbot Screen with message
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AskMeScreen(initialMessage: fullMessage),
          ),
        );

        print('Navigation completed with result: $result');
      } catch (navigationError) {
        print('Navigation error: $navigationError');
        // If navigation fails, show an error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${L10n.getTranslatedText(context, 'Failed to open chat')}: $navigationError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      _messageController.clear();
    } else {
      print('Follow-up message is empty');
      // Optionally show a message that input is required
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(L10n.getTranslatedText(
              context, 'Please enter a follow-up message')),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // **Scrollable Content (Fetched Data)**
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: FutureBuilder<String>(
                    future: _recommendationFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Use the ProgressLoadingWidget instead of custom loading animation
                        return ProgressLoadingWidget(
                          primaryText: L10n.getTranslatedText(
                              context, 'Analyzing your progress...'),
                          secondaryText: L10n.getTranslatedText(
                              context, 'Generating personalized insights'),
                          primaryColor: AcademeTheme.appColor,
                          motivationalTips: [
                            L10n.getTranslatedText(
                                context, 'Reviewing your study patterns'),
                            L10n.getTranslatedText(
                                context, 'Identifying improvement areas'),
                            L10n.getTranslatedText(
                                context, 'Creating personalized suggestions'),
                            L10n.getTranslatedText(
                                context, 'Preparing detailed analysis'),
                          ],
                        );
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return _errorView();
                      }

                      // Success state with fade-in animation
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: const Duration(milliseconds: 600),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with icon
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AcademeTheme.appColor.withOpacity(0.1),
                                      AcademeTheme.appColor.withOpacity(0.05),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        AcademeTheme.appColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AcademeTheme.appColor
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.analytics,
                                        color: AcademeTheme.appColor,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            L10n.getTranslatedText(context,
                                                'Your Progress Analysis'),
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            L10n.getTranslatedText(context,
                                                'Personalized insights ready'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _formattedText(snapshot.data!),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // **Message Input Field (Fixed at Bottom)**
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // **Message Input Box**
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText:
                                "${L10n.getTranslatedText(context, 'Ask follow-up')}...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide:
                                  BorderSide(color: AcademeTheme.appColor),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // **Send Button**
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AcademeTheme.appColor,
                              AcademeTheme.appColor.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: AcademeTheme.appColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendFollowUpToChatbot,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// **Error View when API fails**
  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            L10n.getTranslatedText(context, 'Unable to load recommendations'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            L10n.getTranslatedText(
                context, 'Please check your connection and try again'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _recommendationFuture = _fetchRecommendations();
              });
            },
            icon: const Icon(Icons.refresh),
            label: Text(L10n.getTranslatedText(context, 'Try Again')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AcademeTheme.appColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
            ),
          ),
        ],
      ),
    );
  }

  /// **Formats raw recommendation text with bold headings, bullet points, and other markdown symbols**
  /// **Filters out IDs and only shows titles**
  Widget _formattedText(String text) {
    return RecommendationTextFormatter.formatText(text, context);
  }
}
