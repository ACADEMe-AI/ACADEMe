import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/academe_theme.dart';
import '../../../../localization/l10n.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import '../widgets/homepage_drawer.dart';
import '../../../components/askme_button.dart';
import '../../ask_me/screens/ask_me_screen.dart';
import '../../progress/screens/progress_screen.dart';
import '../../../../started/pages/class.dart';
import '../../homepage/controllers/home_controller.dart';

// Import all the split widget files
import '../widgets/app_bar.dart';
import '../widgets/search_ui.dart' hide CourseCard;
import '../widgets/ask_me_card.dart';
import '../widgets/progress_card.dart';
import '../widgets/continue_learning.dart';
import '../widgets/swipeable_banner.dart';
import '../widgets/course_tags.dart';
import '../widgets/courses_grid.dart';
import '../widgets/course_card.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onCourseTap;
  final int selectedIndex;

  const HomeScreen({
    super.key,
    required this.onProfileTap,
    required this.onCourseTap,
    required this.selectedIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _showSearchUI = ValueNotifier(false);
  final HomeController _controller = HomeController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (mounted) await _checkAndShowClassSelection();
      } catch (e) {
        debugPrint("Error in post frame callback: $e");
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _showSearchUI.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    try {
      await _controller.initializeData(currentLanguage);
    } catch (e) {
      debugPrint("Error initializing data: $e");
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    await _controller.refreshData(currentLanguage);
  }

  Future<void> _checkAndShowClassSelection() async {
    try {
      final String? studentClass = await _secureStorage.read(key: 'student_class');
      final String? classSelectionShown = await _secureStorage.read(key: 'class_selection_shown');

      // Only show if class is not set AND the popup hasn't been shown before
      if ((studentClass == null || int.tryParse(studentClass) == null ||
          int.parse(studentClass) < 1 || int.parse(studentClass) > 12) &&
          classSelectionShown != 'true') {
        if (!mounted) return;

        await showClassSelectionSheet(context);

        // Mark that class selection popup has been shown
        await _secureStorage.write(key: 'class_selection_shown', value: 'true');
      }
    } catch (e) {
      debugPrint("Error checking class selection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return ChangeNotifierProvider.value(
      value: _controller,
      child: ASKMeButton(
        showFAB: true,
        onFABPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMeScreen()),
        ),
        child: WillPopScope(
          onWillPop: () async {
            SystemNavigator.pop();
            return false;
          },
          child: Scaffold(
            key: scaffoldKey,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(90),
              child: AppBar(
                backgroundColor: AcademeTheme.appColor,
                automaticallyImplyLeading: false,
                elevation: 0,
                leading: Container(),
                flexibleSpace: Consumer<HomeController>(
                  builder: (context, controller, child) {
                    return FutureBuilder<Map<String, String?>>(
                      future: controller.getUserDetails(),
                      builder: (context, snapshot) {
                        // Force a fresh fetch every time
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return HomeAppBar(
                            onProfileTap: widget.onProfileTap,
                            onHamburgerTap: () => scaffoldKey.currentState?.openDrawer(),
                            name: 'User',
                            photoUrl: 'https://www.w3schools.com/w3images/avatar2.png',
                          );
                        }

                        return HomeAppBar(
                          onProfileTap: widget.onProfileTap,
                          onHamburgerTap: () => scaffoldKey.currentState?.openDrawer(),
                          name: snapshot.data?['name'] ?? 'User',
                          photoUrl: snapshot.data?['photo_url'] ?? 'assets/design_course/userImage.png',
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            backgroundColor: AcademeTheme.appColor,
            body: RefreshIndicator(
              onRefresh: _refreshData,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: _showSearchUI,
                  builder: (context, showSearch, _) {
                    return showSearch
                        ? Consumer<HomeController>(
                      builder: (context, controller, child) {
                        return SearchUI(
                          showSearchUI: _showSearchUI,
                          allCourses: controller.courses,
                        );
                      },
                    )
                        : _buildMainContent();
                  },
                ),
              ),
            ),
            drawer: HomepageDrawer(
              onClose: () => Navigator.of(context).pop(),
              onProfileTap: widget.onProfileTap,
              onCourseTap: widget.onCourseTap,
            ),
            drawerEdgeDragWidth: double.infinity,
            endDrawerEnableOpenDragGesture: true,
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const FullPageShimmer();
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Search field
            TextField(
              onTap: () => _showSearchUI.value = true,
              decoration: InputDecoration(
                hintText: L10n.getTranslatedText(context, 'search'),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                  child: Transform.rotate(
                    angle: -1.57,
                    child: const Icon(Icons.tune),
                  ),
                ),
                suffixIcon: const Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color.fromARGB(205, 232, 238, 239),
              ),
            ),
            const SizedBox(height: 20),
            AskMeCard(messageController: _messageController),
            const SizedBox(height: 20),
            ProgressCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProgressScreen()),
              ),
            ),
            const SizedBox(height: 20),

            // Continue Learning Section
            ContinueLearningSection(
              courses: controller.courses,
              refreshCourses: _refreshData,
              onSeeAllTap: widget.onCourseTap,
            ),
            const SizedBox(height: 20),

            SwipeableBanner(pageController: _pageController),
            const SizedBox(height: 16),

            // All Courses header above tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.getTranslatedText(context, 'All Courses'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onCourseTap,
                    child: Text(
                      L10n.getTranslatedText(context, 'See All'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Course tags
            CourseTagsGrid(),
            const SizedBox(height: 16),

            // My Courses section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    L10n.getTranslatedText(context, 'My Courses'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onCourseTap,
                    child: Text(
                      L10n.getTranslatedText(context, 'See All'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Courses grid
            CoursesGrid(),

            // const SizedBox(height: 16),
            // // Recommended section
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 4),
            //   child: Text(
            //     L10n.getTranslatedText(context, 'Recommended'),
            //     style: const TextStyle(
            //       fontSize: 18,
            //       fontWeight: FontWeight.bold,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),
            // // Recommended courses
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 4),
            //   child: SizedBox(
            //     height: 160,
            //     child: Row(
            //       children: [
            //         Expanded(
            //           child: CourseCard(
            //             L10n.getTranslatedText(context, 'Marketing'),
            //             "9 ${L10n.getTranslatedText(context, 'Lessons')}",
            //             Colors.pink[100]!,
            //             onTap: () {},
            //           ),
            //         ),
            //         const SizedBox(width: 8),
            //         Expanded(
            //           child: CourseCard(
            //             L10n.getTranslatedText(context, 'Trading'),
            //             "14 ${L10n.getTranslatedText(context, 'Lessons')}",
            //             Colors.green[100]!,
            //             onTap: () {},
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        );
      },
    );
  }
}

// Shimmer Effect Widget
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

// Full page shimmer for entire homepage
class FullPageShimmer extends StatelessWidget {
  const FullPageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Search field shimmer
        ShimmerEffect(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Ask Me Card shimmer
        ShimmerEffect(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Progress Card shimmer
        ShimmerEffect(
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Continue Learning section shimmer
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerEffect(
              child: Container(
                height: 20,
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ShimmerEffect(
                      child: Container(
                        width: 160,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Banner shimmer
        ShimmerEffect(
          child: Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // All Courses header shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerEffect(
              child: Container(
                height: 18,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            ShimmerEffect(
              child: Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Course tags shimmer
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(6, (index) {
            return ShimmerEffect(
              child: Container(
                height: 32,
                width: 80 + (index * 10).toDouble(),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),

        // My Courses header shimmer
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ShimmerEffect(
              child: Container(
                height: 18,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            ShimmerEffect(
              child: Container(
                height: 16,
                width: 60,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Courses grid shimmer
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            return ShimmerEffect(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Recommended section shimmer
        ShimmerEffect(
          child: Container(
            height: 18,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Recommended courses shimmer
        SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: ShimmerEffect(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ShimmerEffect(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}