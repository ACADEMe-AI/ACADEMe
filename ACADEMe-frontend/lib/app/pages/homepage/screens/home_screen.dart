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
import '../widgets/search_ui.dart';
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
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCourses();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _controller.fetchAndStoreUserDetails();
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

  Future<void> _initializeCourses() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    setState(() => _isLoading = true);
    try {
      final courses = await _controller.fetchCourses(currentLanguage);
      if (mounted) {
        setState(() {
          _courses = courses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint("Error initializing courses: $e");
    }
  }

  Future<void> _refreshCourses() async {
    if (!mounted) return;
    _controller.clearCache();
    await _initializeCourses();
  }

  Future<void> _checkAndShowClassSelection() async {
    try {
      final String? studentClass = await _secureStorage.read(key: 'student_class');
      if (studentClass == null || int.tryParse(studentClass) == null ||
          int.parse(studentClass) < 1 || int.parse(studentClass) > 12) {
        if (!mounted) return;
        await showClassSelectionSheet(context);
      }
    } catch (e) {
      debugPrint("Error checking class selection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return ASKMeButton(
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
              flexibleSpace: FutureBuilder<Map<String, String?>>(
                future: _controller.getUserDetails(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return HomeAppBar(
                    onProfileTap: widget.onProfileTap,
                    onHamburgerTap: () => scaffoldKey.currentState?.openDrawer(),
                    name: snapshot.data?['name'] ?? 'User',
                    photoUrl: snapshot.data?['photo_url'] ?? 'assets/design_course/userImage.png',
                  );
                },
              ),
            ),
          ),
          backgroundColor: AcademeTheme.appColor,
          body: RefreshIndicator(
            onRefresh: _refreshCourses,
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
                    ? SearchUI(showSearchUI: _showSearchUI)
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
    );
  }

 Widget _buildMainContent() {
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
      ContinueLearningSection(
        courses: _courses,
        refreshCourses: _refreshCourses,
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
      
      // Course tags - Updated with refresh callback
      CourseTagsGrid(refreshCourses: _refreshCourses),
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
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CoursesGrid(
              courses: _courses,
              refreshCourses: _refreshCourses,
            ),
      const SizedBox(height: 16),
      // Recommended section
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          L10n.getTranslatedText(context, 'Recommended'),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 8),
      // Recommended courses
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 160,
          child: Row(
            children: [
              Expanded(
                child: CourseCard(
                  L10n.getTranslatedText(context, 'Marketing'),
                  "9 ${L10n.getTranslatedText(context, 'Lessons')}",
                  Colors.pink[100]!,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CourseCard(
                  L10n.getTranslatedText(context, 'Trading'),
                  "14 ${L10n.getTranslatedText(context, 'Lessons')}",
                  Colors.green[100]!,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
}