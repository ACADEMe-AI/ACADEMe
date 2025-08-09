import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../../../../../providers/progress_provider.dart';
import '../../flashcard/screens/flash_card_screen.dart';
import '../../reports/screens/test_report_screen.dart';
import '../controllers/lessons_controller.dart';
import '../models/lessons_model.dart';
import '../widgets/lessons_widgets.dart';
import '../widgets/shimmer_widgets.dart'; // Add this import
import '../../flashcard/controllers/flash_card_controller.dart';

class LessonsSection extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String courseTitle;
  final String topicTitle;
  final String language;
  final List<Map<String, dynamic>> userProgress;

  const LessonsSection({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.language,
    required this.userProgress,
  });

  @override
  LessonsSectionState createState() => LessonsSectionState();
}

class LessonsSectionState extends State<LessonsSection> {
  final LessonsController _controller = LessonsController();
  SubtopicState _state = const SubtopicState();

  @override
  void initState() {
    super.initState();
    _initializeProgress();
    _fetchSubtopics();
  }

  Future<void> _initializeProgress() async {
    final progressProvider = ProgressProvider();

    // Preload progress data once (will use cache if valid)
    await progressProvider.preloadProgress(
      courseId: widget.courseId,
      topicId: widget.topicId,
    );

    _determineResumePoint();
  }

  Future<void> _fetchSubtopics() async {
    setState(() => _state = _state.copyWith(isLoading: true));

    final subtopics = await _controller.fetchSubtopics(
      context: context,
      courseId: widget.courseId,
      topicId: widget.topicId,
    );

    if (subtopics.isNotEmpty) {
      setState(() {
        _state = _state.copyWith(
          isExpanded: {
            for (int i = 0; i < subtopics.length; i++)
              "${(i + 1).toString().padLeft(2, '0')} - ${subtopics[i]["title"]}":
                  false
          },
          subtopicIds: {
            for (var sub in subtopics)
              "${(subtopics.indexOf(sub) + 1).toString().padLeft(2, '0')} - ${sub["title"]}":
                  sub["id"].toString()
          },
          isLoading: false,
        );
      });
    } else {
      setState(() => _state = _state.copyWith(isLoading: false));
    }
  }

  void _determineResumePoint() {
    final resumePoint = _controller.determineResumePoint(
      widget.courseId,
      widget.topicId,
    );

    if (resumePoint != null) {
      setState(() {
        _state = _state.copyWith(
          showResume: true,
          resumeSubtopicId: resumePoint['subtopic_id'],
        );
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      _state = _state.copyWith(
        subtopicMaterials: {},
        subtopicQuizzes: {},
        subtopicLoading: {},
        isLoading: true,
      );
    });

    await _fetchSubtopics();
    _determineResumePoint();

    for (final entry in _state.isExpanded.entries) {
      if (entry.value && _state.subtopicIds.containsKey(entry.key)) {
        await _fetchMaterialsAndQuizzes(_state.subtopicIds[entry.key]!);
      }
    }
  }

  Future<void> _fetchMaterialsAndQuizzes(String subtopicId) async {
    setState(() {
      _state = _state.copyWith(
        subtopicLoading: {
          ..._state.subtopicLoading,
          subtopicId: true,
        },
      );
    });

    final content = await _controller.fetchMaterialsAndQuizzes(
      context: context,
      courseId: widget.courseId,
      topicId: widget.topicId,
      subtopicId: subtopicId,
    );

    setState(() {
      _state = _state.copyWith(
        subtopicMaterials: {
          ..._state.subtopicMaterials,
          subtopicId: content.materials,
        },
        subtopicQuizzes: {
          ..._state.subtopicQuizzes,
          subtopicId: content.quizzes,
        },
        subtopicLoading: {
          ..._state.subtopicLoading,
          subtopicId: false,
        },
      );
    });
  }

  Future<Map<String, dynamic>?> _findNextUncompletedSubtopic() async {
    final subtopicIdsList = _state.subtopicIds.values.toList();
    int startIndex = _state.resumeSubtopicId != null
        ? subtopicIdsList.indexOf(_state.resumeSubtopicId!)
        : 0;

    for (int i = startIndex; i < subtopicIdsList.length; i++) {
      final subtopicId = subtopicIdsList[i];
      if (!_state.subtopicMaterials.containsKey(subtopicId)) {
        await _fetchMaterialsAndQuizzes(subtopicId);
      }

      final materials = _state.subtopicMaterials[subtopicId] ?? [];
      final quizzes = _state.subtopicQuizzes[subtopicId] ?? [];

      for (int j = 0; j < materials.length; j++) {
        if (!_controller.isActivityCompleted(
          courseId: widget.courseId,
          topicId: widget.topicId,
          activityId: materials[j]['id'],
          activityType: 'material',
        )) {
          return {
            'subtopicId': subtopicId,
            'index': j,
            'subtopicTitle': _state.subtopicIds.entries
                .firstWhere((entry) => entry.value == subtopicId)
                .key,
          };
        }
      }

      for (int j = 0; j < quizzes.length; j++) {
        if (!_controller.isActivityCompleted(
          courseId: widget.courseId,
          topicId: widget.topicId,
          activityId: quizzes[j]['id'],
          activityType: 'quiz',
          questionId: quizzes[j]['question_id'],
        )) {
          return {
            'subtopicId': subtopicId,
            'index': materials.length + j,
            'subtopicTitle': _state.subtopicIds.entries
                .firstWhere((entry) => entry.value == subtopicId)
                .key,
          };
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                left: 16, right: 16, top: 16, bottom: 100),
            child: Column(
              children: [
                if (_state.isLoading)
                  // Replace CircularProgressIndicator with SubtopicListShimmer
                  const SubtopicListShimmer()
                else
                  ..._state.isExpanded.keys.map((section) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            section,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          trailing: Icon(
                            _state.isExpanded[section]!
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.black,
                          ),
                          onTap: () async {
                            setState(() {
                              _state = _state.copyWith(
                                isExpanded: {
                                  ..._state.isExpanded,
                                  section: !_state.isExpanded[section]!,
                                },
                              );
                            });
                            if (_state.isExpanded[section]! &&
                                _state.subtopicIds.containsKey(section)) {
                              await _fetchMaterialsAndQuizzes(
                                  _state.subtopicIds[section]!);
                            }
                          },
                        ),
                        if (_state.isExpanded[section]! &&
                            _state.subtopicIds.containsKey(section))
                          LessonsAndQuizzesWidget(
                            subtopicId: _state.subtopicIds[section]!,
                            materials: _state.subtopicMaterials[
                                    _state.subtopicIds[section]!] ??
                                [],
                            quizzes: _state.subtopicQuizzes[
                                    _state.subtopicIds[section]!] ??
                                [],
                            isLoading: _state.subtopicLoading[
                                    _state.subtopicIds[section]!] ??
                                false,
                            // userProgress: widget.userProgress,
                            courseId: widget.courseId,
                            topicId: widget.topicId,
                            onTap: (index) => _navigateToFlashcard(
                              _state.subtopicIds[section]!,
                              _state.subtopicIds.entries
                                  .firstWhere((entry) =>
                                      entry.value ==
                                      _state.subtopicIds[section]!)
                                  .key,
                              index,
                            ),
                          ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: _state.isNavigating ? null : () => _handleResumeButton(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AcademeTheme.appColor,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            _state.isNavigating
                ? L10n.getTranslatedText(context, 'Loading...')
                : _state.showResume
                    ? L10n.getTranslatedText(context, 'Resume')
                    : L10n.getTranslatedText(context, 'Start Course'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleResumeButton() async {
    if (_state.isNavigating) return;
    setState(() => _state = _state.copyWith(isNavigating: true));

    final target = await _findNextUncompletedSubtopic();

    if (target == null) {
      setState(() => _state = _state.copyWith(isNavigating: false));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestReportScreen(
            courseId: widget.courseId,
            topicId: widget.topicId,
            courseTitle: widget.courseTitle,
            topicTitle: widget.topicTitle,
            language: widget.language,
          ),
        ),
      );
      return;
    }

    _navigateToFlashcard(
      target['subtopicId'],
      target['subtopicTitle'],
      target['index'],
    );
  }

  void _navigateToFlashcard(
      String subtopicId, String subtopicTitle, int index) {
    final materials = (_state.subtopicMaterials[subtopicId] ?? [])
        .map<Map<String, String>>((material) {
      return {
        "id": material["id"]?.toString() ?? "",
        "type": material["type"]?.toString() ?? "",
        "content": material["content"]?.toString() ?? "",
      };
    }).toList();

    final quizzes = _state.subtopicQuizzes[subtopicId] ?? [];

    final controller = FlashCardController(
      materials: materials,
      quizzes: quizzes,
      onQuizComplete: () => _navigateToNextSubtopic(subtopicId),
      initialIndex: index,
      courseId: widget.courseId,
      topicId: widget.topicId,
      subtopicId: subtopicId,
      subtopicTitle: subtopicTitle,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlashCardScreen(controller: controller),
      ),
    ).then((_) {
      if (mounted)
        setState(() => _state = _state.copyWith(isNavigating: false));
    });
  }

  void _navigateToNextSubtopic(String currentSubtopicId) {
    int currentIndex =
        _state.subtopicIds.values.toList().indexOf(currentSubtopicId);
    if (currentIndex < _state.subtopicIds.length - 1) {
      String nextSubtopicId =
          _state.subtopicIds.values.toList()[currentIndex + 1];
      String nextSubtopicTitle =
          _state.subtopicIds.keys.toList()[currentIndex + 1];

      _fetchMaterialsAndQuizzes(nextSubtopicId).then((_) {
        if (!context.mounted) return;

        final materials = (_state.subtopicMaterials[nextSubtopicId] ?? [])
            .map<Map<String, String>>((material) {
          return {
            "id": material["id"]?.toString() ?? "",
            "type": material["type"]?.toString() ?? "",
            "content": material["content"]?.toString() ?? "",
          };
        }).toList();

        final quizzes = _state.subtopicQuizzes[nextSubtopicId] ?? [];

        final controller = FlashCardController(
          materials: materials,
          quizzes: quizzes,
          onQuizComplete: () => _navigateToNextSubtopic(nextSubtopicId),
          initialIndex: 0,
          courseId: widget.courseId,
          topicId: widget.topicId,
          subtopicId: nextSubtopicId,
          subtopicTitle: nextSubtopicTitle,
        );

        // Use pushReplacement instead of push to replace current screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FlashCardScreen(controller: controller),
          ),
        );
      });
    } else {
      // Use pushReplacement for final screen too
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestReportScreen(
            courseId: widget.courseId,
            topicId: widget.topicId,
            courseTitle: widget.courseTitle,
            topicTitle: widget.topicTitle,
            language: widget.language,
          ),
        ),
      );
    }
  }
}
