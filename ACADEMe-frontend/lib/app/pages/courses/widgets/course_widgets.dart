import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../controllers/course_controller.dart';
import 'dart:developer';
import '../../topics/screens/topic_view_screen.dart';

class CourseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRefresh;
  final bool isLoading;

  const CourseAppBar({
    super.key,
    required this.onRefresh,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AcademeTheme.appColor,
      automaticallyImplyLeading: false,
      elevation: 0,
      title: Text(
        L10n.getTranslatedText(context, 'My Courses'),
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: isLoading ? null : onRefresh,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CourseTabBar extends StatelessWidget {
  final TabController tabController;
  final AutoSizeGroup tabTextGroup;

  const CourseTabBar({
    super.key,
    required this.tabController,
    required this.tabTextGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.black54,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(width: 2, color: Colors.blue),
        ),
        tabs: [
          _buildSynchronizedTab(context, 'ALL'),
          _buildSynchronizedTab(context, 'ON GOING'),
          _buildSynchronizedTab(context, 'COMPLETED'),
        ],
      ),
    );
  }

  Widget _buildSynchronizedTab(BuildContext context, String labelKey) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: tabTextGroup,
        style: const TextStyle(fontSize: 16),
        minFontSize: 12,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CourseCard extends StatelessWidget {
  final Course course;
  final Future<String> Function(String courseId, BuildContext context)
      getModuleProgressText;

  const CourseCard({
    super.key,
    required this.course,
    required this.getModuleProgressText,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        log("Selected Course ID: ${course.id}");

        try {
          final controller =
              Provider.of<CourseController>(context, listen: false);
          await controller.selectCourse(course.id);

          if (!context.mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TopicViewScreen(
                courseId: course.id,
                courseTitle: course.title,
              ),
            ),
          );

          // Refresh course progress after returning
          if (context.mounted) {
            await controller.refreshCourseProgress(course.id);
          }
        } catch (error) {
          log("Error storing course ID: $error");
        }
      },
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 5,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 5,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      Container(
                        height: 5,
                        width: MediaQuery.of(context).size.width *
                            (course.progress.clamp(0.0, 1.0)),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FutureBuilder<String>(
                          future: getModuleProgressText(course.id, context),
                          builder: (context, snapshot) {
                            return Text(
                              snapshot.data ??
                                  "0/0 ${L10n.getTranslatedText(context, 'Modules')}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "${(course.progress.clamp(0.0, 1.0) * 100).toInt()}%",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  final Widget child;

  const ShimmerEffect({super.key, required this.child});

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white54,
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

class CourseCardShimmer extends StatelessWidget {
  const CourseCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 5,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title shimmer
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 10),
                // Progress bar shimmer
                Container(
                  height: 5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 5),
                // Bottom text shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 12,
                      width: 30,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShimmerLoadingList extends StatelessWidget {
  const ShimmerLoadingList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 6, // Show 6 shimmer cards
      itemBuilder: (context, index) {
        return ShimmerEffect(
          child: CourseCardShimmer(),
        );
      },
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRefresh;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRefresh,
              child: Text(L10n.getTranslatedText(context, 'Refresh')),
            ),
          ],
        ],
      ),
    );
  }
}

class CourseListView extends StatelessWidget {
  final List<Course> courses;
  final bool isLoading;
  final bool hasInitialized;
  final VoidCallback onRefresh;
  final String emptyMessage;
  final Future<String> Function(String courseId, BuildContext context)
      getModuleProgressText;

  const CourseListView({
    super.key,
    required this.courses,
    required this.isLoading,
    required this.hasInitialized,
    required this.onRefresh,
    required this.emptyMessage,
    required this.getModuleProgressText,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && !hasInitialized) {
      return const ShimmerLoadingList();
    }

    if (courses.isEmpty && hasInitialized) {
      return EmptyStateWidget(
        message: emptyMessage,
        onRefresh: onRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          return CourseCard(
            course: courses[index],
            getModuleProgressText: getModuleProgressText,
          );
        },
      ),
    );
  }
}
