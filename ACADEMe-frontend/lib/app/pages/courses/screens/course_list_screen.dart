import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/app/pages/ask_me/screens/ask_me_screen.dart';
import 'package:ACADEMe/app/components/askme_button.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import '../controllers/course_controller.dart';
import '../widgets/course_widgets.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  CourseListScreenState createState() => CourseListScreenState();
}

class CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final AutoSizeGroup _tabTextGroup = AutoSizeGroup();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCourses();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeCourses() async {
    if (!mounted) return;
    final controller = Provider.of<CourseController>(context, listen: false);
    await controller.initializeCourses(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Schedule the check for after the current build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndRefreshIfNeeded();
      }
    });
  }

  Future<void> _checkAndRefreshIfNeeded() async {
    final controller = Provider.of<CourseController>(context, listen: false);
    if (!controller.hasInitialized) {
      await _initializeCourses();
    }
  }

  Future<void> _refreshCourses() async {
    if (!mounted) return;
    final controller = Provider.of<CourseController>(context, listen: false);
    await controller.refreshCourses(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<CourseController>(
      builder: (context, controller, child) {
        return ASKMeButton(
          onFABPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AskMeScreen()),
            );
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            appBar: CourseAppBar(
              onRefresh: _refreshCourses,
              isLoading: controller.isLoading,
            ),
            body: Column(
              children: [
                CourseTabBar(
                  tabController: _tabController,
                  tabTextGroup: _tabTextGroup,
                ),
                if (controller.isRefreshing)
                  const LinearProgressIndicator(
                    backgroundColor: Colors.grey,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // All Courses Tab
                      CourseListView(
                        courses: controller.courses,
                        isLoading: controller.isLoading,
                        hasInitialized: controller.hasInitialized,
                        onRefresh: _refreshCourses,
                        emptyMessage: L10n.getTranslatedText(
                            context, 'No courses available'),
                        getModuleProgressText: controller.getModuleProgressText,
                      ),
                      // Ongoing Courses Tab
                      CourseListView(
                        courses: controller.ongoingCourses,
                        isLoading: controller.isLoading,
                        hasInitialized: controller.hasInitialized,
                        onRefresh: _refreshCourses,
                        emptyMessage: L10n.getTranslatedText(
                            context, 'No ongoing courses'),
                        getModuleProgressText: controller.getModuleProgressText,
                      ),
                      // Completed Courses Tab
                      CourseListView(
                        courses: controller.completedCourses,
                        isLoading: controller.isLoading,
                        hasInitialized: controller.hasInitialized,
                        onRefresh: _refreshCourses,
                        emptyMessage: L10n.getTranslatedText(
                            context, 'No completed courses'),
                        getModuleProgressText: controller.getModuleProgressText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
