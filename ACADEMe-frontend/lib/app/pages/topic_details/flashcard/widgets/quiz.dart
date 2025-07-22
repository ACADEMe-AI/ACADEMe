import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class QuizPage extends StatefulWidget {
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final Function()? onSwipeToNext; // Add this callback
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String subtopicTitle;
  final bool hasNextMaterial; // Add this to know if there's a next material

  const QuizPage({
    super.key,
    required this.quizzes,
    this.onQuizComplete,
    this.onSwipeToNext, // Add this parameter
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.subtopicTitle,
    this.hasNextMaterial = false, // Add this parameter with default value
  });

  @override
  QuizPageState createState() => QuizPageState();
}

class QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int _currentQuestionIndex = 0;
  int? _selectedAnswer;
  bool isSubmitting = false;
  final String _baseUrl = dotenv.env['BACKEND_URL'] ??
      'http://10.0.2.2:8000'; // Replace with your API endpoint
  List<dynamic> _progressList = [];
  final FlutterSecureStorage _storage =
  const FlutterSecureStorage(); // Add FlutterSecureStorage

  // Animation variables
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  // Progress line animation variables
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  bool _showResultAnimation = false;
  bool _lastAnswerCorrect = false;

  @override
  void initState() {
    super.initState();
    _fetchProgress();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
    ));

    // Initialize progress line animation
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchProgress() async {
    String? token =
    await _storage.read(key: 'access_token'); // Retrieve the access token
    if (!mounted) {
      return; // Ensure widget is still active before using context
    }
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Access token not found'))),
      );
      return;
    }

    final response = await http.get(
      Uri.parse(
          "$_baseUrl/api/progress/?target_language=en"), // Hardcoded "en" for English
      headers: {
        'Authorization':
        'Bearer $token', // Include the access token in the headers
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _progressList = data["progress"];
      });
    } else if (response.statusCode == 404) {
      // Handle 404 Not Found error (no progress records)
      final responseBody = json.decode(response.body);
      if (responseBody["detail"] == "No progress records found") {
        setState(() {
          _progressList = []; // Treat as an empty progress list
        });
      } else {
        if (!mounted) {
          return; // Ensure widget is still active before using context
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(L10n.getTranslatedText(
                  context, 'No progress records found'))),
        );
      }
    } else {
      if (!mounted) {
        return; // Ensure widget is still active before using context
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Failed to fetch progress'))),
      );
    }
  }

  Future<void> _sendProgress(
      bool isCorrect, String quizId, String questionId) async {
    String? token = await _storage.read(key: 'access_token');
    if (!mounted) {
      return;
    }
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                L10n.getTranslatedText(context, 'Access token not found'))),
      );
      return;
    }

    // Calculate score per question
    final totalQuestions = widget.quizzes.length;
    final scorePerQuestion = totalQuestions > 0 ? (100 / totalQuestions) : 0;
    final score = isCorrect ? scorePerQuestion : 0;

    final existingProgress = _progressList.firstWhere(
          (progress) =>
      progress["quiz_id"] == quizId &&
          progress["question_id"] == questionId,
      orElse: () => null,
    );

    if (existingProgress == null) {
      // Create new progress
      final response = await http.post(
        Uri.parse("$_baseUrl/api/progress/"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          "course_id": widget.courseId,
          "topic_id": widget.topicId,
          "subtopic_id": widget.subtopicId,
          "material_id": null,
          "quiz_id": quizId,
          "question_id": questionId, // Add question_id
          "score": score,
          "status": "completed",
          "activity_type": "quiz",
          "metadata": {
            "time_spent": "5 minutes",
          },
          "timestamp": DateTime.now().toIso8601String(),
        }),
      );
      if (!mounted) {
        return;
      }
      // if (response.statusCode == 201) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //         content: Text(L10n.getTranslatedText(
      //             context, 'Progress saved successfully'))),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //         content: Text(
      //             L10n.getTranslatedText(context, 'Failed to save progress'))),
      //   );
      // }
    } else {
      // Update existing progress
      final progressId = existingProgress["progress_id"];
      final response = await http.put(
        Uri.parse("$_baseUrl/api/progress/$progressId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode({
          "status": "completed",
          "score": score,
          "metadata": {
            "time_spent": "5 minutes",
          },
        }),
      );
      if (!mounted) {
        return;
      }

      // if (response.statusCode == 200) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //         content: Text(L10n.getTranslatedText(
      //             context, 'Progress updated successfully'))),
      //   );
      // } else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //         content: Text(L10n.getTranslatedText(
      //             context, 'Failed to update progress'))),
      //   );
      // }
    }
  }

  // Store result in Shared Preferences
  Future<void> _storeQuizResult(bool isCorrect) async {
    final String storageKey = 'quiz_results_${widget.courseId}_${widget.topicId}';
    String? existingResults = await _storage.read(key: storageKey);

    Map<String, dynamic> results = existingResults != null
        ? json.decode(existingResults)
        : {
      'totalQuestions': 0,
      'correctAnswers': 0,
      'quizData': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    results['totalQuestions'] = (results['totalQuestions'] as int) + 1;
    if (isCorrect) {
      results['correctAnswers'] = (results['correctAnswers'] as int) + 1;
    }

    // Add current quiz data
    final currentQuiz = widget.quizzes[_currentQuestionIndex];
    results['quizData'].add({
      'title': widget.subtopicTitle,
      'isCorrect': isCorrect,
      'timestamp': DateTime.now().toIso8601String(),
    });

    results['lastUpdated'] = DateTime.now().toIso8601String();

    await _storage.write(
      key: storageKey,
      value: json.encode(results),
    );
  }

  double _calculateFontSize(String text) {
    if (text.length <= 15) {
      return 16.0; // Original size for short text
    } else if (text.length <= 30) {
      return 14.0; // Slightly smaller for medium text
    } else if (text.length <= 50) {
      return 12.0; // Smaller for longer text
    } else {
      return 10.0; // Smallest for very long text
    }
  }

  Widget _buildCardFlipAnimation() {
    if (!_showResultAnimation) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withOpacity(0.6 * _fadeAnimation.value),
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_scaleAnimation.value * 3.14159),
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _lastAnswerCorrect
                        ? [const Color(0xFF4CAF50), const Color(0xFF8BC34A)]
                        : [const Color(0xFFE57373), const Color(0xFFFF7043)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: _scaleAnimation.value > 0.5
                    ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(3.14159),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // Main content - positioned to fill the container minus progress bar space
                        Positioned.fill(
                          bottom: 6, // Leave exact space for progress bar height
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Icon(
                                    _lastAnswerCorrect
                                        ? Icons.verified_rounded
                                        : Icons.error_outline_rounded,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _lastAnswerCorrect
                                      ? L10n.getTranslatedText(context, 'Perfect!')
                                      : L10n.getTranslatedText(context, 'Oops!'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_lastAnswerCorrect)
                                  const Text(
                                    "Keep it up! 🚀",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                Text(
                                  L10n.getTranslatedText(context, 'Saving progress...'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Progress bar positioned at the bottom
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progressAnimation.value,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }


  void _showResultPopup(
      bool isCorrect, String submittedQuizId, String questionId) {
    // Set animation state
    setState(() {
      _lastAnswerCorrect = isCorrect;
      _showResultAnimation = true;
    });

    // Start the card flip animation
    _animationController.forward();

    // Start progress bar animation after card animation completes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _progressAnimationController.forward();
    });

    // Navigate after animation completes
    Future.delayed(const Duration(milliseconds: 3500), () async {
      if (!mounted) return;

      await _storeQuizResult(isCorrect);

      // FIXED: Send progress BEFORE any state changes or callbacks
      await _sendProgress(isCorrect, submittedQuizId, questionId);

      // Hide animations
      setState(() {
        _showResultAnimation = false;
      });
      _animationController.reset();
      _progressAnimationController.reset();

      // Check if there are more questions in the current quiz
      if (_currentQuestionIndex < widget.quizzes.length - 1) {
        // Move to next question in current quiz
        setState(() {
          isSubmitting = false;
          _currentQuestionIndex++;
          _selectedAnswer = null;
        });
      } else {
        // All questions completed - reset and trigger callbacks
        setState(() {
          isSubmitting = false;
          _currentQuestionIndex = 0;
          _selectedAnswer = null;
        });

        // Trigger next material if exists, else complete quiz
        if (widget.hasNextMaterial && widget.onSwipeToNext != null) {
          widget.onSwipeToNext!(); // Trigger swipe to next material
        } else {
          if (widget.onQuizComplete != null) {
            widget.onQuizComplete!();
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.quizzes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            L10n.getTranslatedText(context, 'No quizzes available'),
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    final currentQuiz = widget.quizzes[_currentQuestionIndex];
    final questionText =
        currentQuiz["question_text"] ?? "No question text available";
    final options =
        (currentQuiz["options"] as List<dynamic>?)?.cast<String>() ??
            ["No options available"];
    final correctOption = currentQuiz["correct_option"] as int? ?? 0;
    final quizId = currentQuiz["id"] as String? ?? "";

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Box with Increased Minimum Height
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(
                          minHeight: 155, // Set minimum height here
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AcademeTheme.appColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            questionText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Answer Options
                      Expanded(
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2, // Two options per row
                            crossAxisSpacing: 12, // Horizontal spacing
                            mainAxisSpacing: 12, // Vertical spacing
                            childAspectRatio: 1.2, // Reduced from 1.5 to 1.2 for taller boxes
                          ),
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            // Calculate text size based on content length
                            double fontSize = _calculateFontSize(options[index]);

                            return GestureDetector(
                              onTap: () {
                                if (!isSubmitting) {
                                  setState(() {
                                    _selectedAnswer = index;
                                  });
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedAnswer == index
                                      ? AcademeTheme.appColor
                                      : Colors.white,
                                  border: Border.all(
                                    color: AcademeTheme.appColor,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.all(12), // Reduced padding to fit more text
                                child: Center(
                                  child: Text(
                                    options[index],
                                    style: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.w600,
                                      color: _selectedAnswer == index
                                          ? Colors.white
                                          : AcademeTheme.appColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    maxLines: null, // Allow unlimited lines
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button Fixed at Bottom
              SafeArea(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                      if (_selectedAnswer != null) {
                        setState(() {
                          isSubmitting = true;
                        });

                        final submittedQuizId = quizId;
                        final currentQuiz =
                        widget.quizzes[_currentQuestionIndex];
                        final questionId =
                            currentQuiz["question_id"]?.toString() ??
                                currentQuiz["id"]?.toString() ??
                                "";
                        final submittedQuestionIndex = _currentQuestionIndex;
                        bool isCorrect = _selectedAnswer == correctOption;

                        _showResultPopup(
                            isCorrect, submittedQuizId, questionId);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(L10n.getTranslatedText(
                                  context, 'Please select an answer!'))),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.yellow, // Fixed color (won't change when disabled)
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      // Ensures no overlay effect on disabled state
                      disabledBackgroundColor:
                      Colors.yellow, // Keep the same as enabled state
                      disabledForegroundColor: Colors.black, // Keep text color same
                    ),
                    child: Text(
                      L10n.getTranslatedText(
                          context, 'Submit'), // Keep the text fixed
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Card flip animation overlay
          _buildCardFlipAnimation(),
        ],
      ),
    );
  }
}