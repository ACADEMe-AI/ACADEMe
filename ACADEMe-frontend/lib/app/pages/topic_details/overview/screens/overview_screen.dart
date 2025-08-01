import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../controllers/overview_controller.dart';
import '../models/overview_model.dart';
import '../widgets/overview_widgets.dart';
import '../../lessons/screens/lessons_screen.dart';
import '../widgets/qna.dart';

class OverviewScreen extends StatefulWidget {
  final String courseId;
  final String topicId;
  final String courseTitle;
  final String topicTitle;
  final String language;

  const OverviewScreen({
    super.key,
    required this.courseId,
    required this.topicId,
    required this.courseTitle,
    required this.topicTitle,
    required this.language,
  });

  @override
  OverviewScreenState createState() => OverviewScreenState();
}

class OverviewScreenState extends State<OverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;
  late OverviewController _controller;
  late OverviewModel _model;
  final GlobalKey<LessonsSectionState> _lessonsSectionKey = GlobalKey<LessonsSectionState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController();
    _controller = OverviewController(
      courseId: widget.courseId,
      topicId: widget.topicId,
      context: context,
    );
    _model = OverviewModel();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final topicDetails = await _controller.fetchTopicDetails();
    final subtopicData = await _controller.fetchSubtopicData();
    final userProgress = await _controller.fetchUserProgress();

    setState(() {
      _model.updateFromController({
        ...topicDetails,
        ...subtopicData,
        ...userProgress,
        'isLoading': false,
      });
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _model.updateFromController({
        ..._model.toMap(),
        'isLoading': true,
      });
    });

    await _fetchData();

    if (_lessonsSectionKey.currentState != null) {
      await _lessonsSectionKey.currentState!.refreshData();
    }

    // Update topic cache with latest progress
    await _controller.updateTopicCacheProgress();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              OverviewHeader(
                height: height,
                width: width,
                model: _model,
                onBackPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: AcademeTheme.appColor,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: ProgressSection(
                          height: height,
                          width: width,
                          model: _model,
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: StickyTabBarDelegate(
                          TabBar(
                            controller: _tabController,
                            labelColor: AcademeTheme.appColor,
                            unselectedLabelColor: Colors.black,
                            indicatorColor: AcademeTheme.appColor,
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelStyle: TextStyle(fontSize: width * 0.045),
                            tabs: [
                              Tab(text: L10n.getTranslatedText(context, 'Overview')),
                              Tab(text: L10n.getTranslatedText(context, 'Q&A')),
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _model.hasSubtopicData
                                ? LessonsSection(
                                    key: _lessonsSectionKey,
                                    courseId: widget.courseId,
                                    topicId: widget.topicId,
                                    courseTitle: widget.courseTitle,
                                    topicTitle: widget.topicTitle,
                                    language: widget.language,
                                    userProgress: _model.userProgress,
                                  )
                                : const Center(child: CircularProgressIndicator()),
                            const QSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}