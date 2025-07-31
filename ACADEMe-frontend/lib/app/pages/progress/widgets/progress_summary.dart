import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/app/pages/progress/widgets/motivation_popup.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../homepage/controllers/home_controller.dart';
import '../controllers/progress_controller.dart';
import '../models/progress_models.dart';

class SummarySection extends StatefulWidget {
  final ProgressController controller;

  const SummarySection({super.key, required this.controller});

  @override
  State<SummarySection> createState() => _SummarySectionState();
}

class _SummarySectionState extends State<SummarySection> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResults = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = !connectivityResults.contains(ConnectivityResult.none);
    });
  }

  void _setupConnectivityListener() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isOnline = !results.contains(ConnectivityResult.none);
      });
    });
  }

  Widget _buildOfflineMessage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AcademeTheme.appColor.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: AcademeTheme.appColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  L10n.getTranslatedText(context, 'No Internet Connection'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  L10n.getTranslatedText(context, 'Please check your internet connection and try again. Your progress data needs an active connection to load'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _checkConnectivity,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(L10n.getTranslatedText(context, 'Retry')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcademeTheme.appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradeErrorMessage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.transparent),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.grade_rounded,
                    size: 48,
                    color: Colors.orange[600],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  L10n.getTranslatedText(context, 'Couldn\'t load your overall grade'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  L10n.getTranslatedText(context, 'We\'re having trouble fetching your grade data right now. Please try again in a moment'),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      // This will trigger a rebuild and retry the FutureBuilder
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(L10n.getTranslatedText(context, 'Try Again')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return _buildOfflineMessage();
    }

    return FutureBuilder<double>(
      future: widget.controller.fetchOverallGrade(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        } else if (snapshot.hasError) {
          // Show the attractive error message instead of the ugly one
          return _buildGradeErrorMessage();
        }

        double overallGrade = snapshot.data ?? 0.0;
        String letterGrade =
        ProgressHelpers.getLetterGrade(context, overallGrade);
        double progressValue = overallGrade / 100;

        return Consumer<HomeController>(
          builder: (context, homeController, child) {
            List<Map<String, dynamic>> courses = homeController.courses;
            int totalCourses = courses.length;

            return FutureBuilder<int>(
              future: _getCompletedCoursesCount(courses),
              builder: (context, completedSnapshot) {
                if (completedSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                int completedCourses = completedSnapshot.data ?? 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          27, 158, 158, 158)),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _buildSummaryItem(
                                    L10n.getTranslatedText(
                                        context, 'Total Courses'),
                                    totalCourses.toString()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          27, 158, 158, 158)),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: _buildSummaryItem(
                                    L10n.getTranslatedText(
                                        context, 'Completed'),
                                    completedCourses.toString()),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color.fromARGB(27, 158, 158, 158)),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: _buildSummaryItem(
                            L10n.getTranslatedText(context, 'Overall Grade'),
                            overallGrade.toStringAsFixed(2),
                            isCircular: true,
                            letterGrade: letterGrade,
                            progressValue: progressValue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMotivationCard(context, overallGrade),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<int> _getCompletedCoursesCount(
      List<Map<String, dynamic>> courses) async {
    final prefs = await SharedPreferences.getInstance();
    int completedCount = 0;

    for (var course in courses) {
      String courseId = course["id"];
      int totalTopics = prefs.getInt('total_topics_$courseId') ?? 0;
      if (totalTopics == 0) continue;

      List<String> completedTopics =
          prefs.getStringList('completed_topics') ?? [];
      int completedTopicsCount =
          completedTopics.where((key) => key.startsWith('$courseId|')).length;

      if (completedTopicsCount >= totalTopics) {
        completedCount++;
      }
    }

    return completedCount;
  }

  Widget _buildSummaryItem(String title, String value,
      {bool isCircular = false,
        String letterGrade = "",
        double progressValue = 0.0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 16),
          isCircular
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.bold,
                  color: AcademeTheme.appColor,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey[300],
                      color: AcademeTheme.appColor,
                      strokeWidth: 8,
                    ),
                  ),
                  Text(
                    letterGrade,
                    style: TextStyle(
                      fontSize: letterGrade.length == 1 ? 28 : 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          )
              : Text(value,
              style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.bold,
                  color: AcademeTheme.appColor)),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context, double score) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => const MotivationPopup(),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.yellow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProgressHelpers.getMotivationMessage(context, score),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      L10n.getTranslatedText(
                          context, 'Learn about your weak points'),
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Two cards in a row (Total Courses and Completed)
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color.fromARGB(27, 158, 158, 158)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildShimmerContent(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color.fromARGB(27, 158, 158, 158)),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _buildShimmerContent(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Overall Grade card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                    color: const Color.fromARGB(27, 158, 158, 158)),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: _buildShimmerContent(isOverallGrade: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerContent({bool isOverallGrade = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildShimmerBar(width: 120, height: 20),
          ),
          SizedBox(height: 16),
          if (isOverallGrade)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildShimmerBar(width: 100, height: 52),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                  ),
                ),
              ],
            )
          else
            _buildShimmerBar(width: 80, height: 54),
        ],
      ),
    );
  }

  Widget _buildShimmerBar({required double width, required double height}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}