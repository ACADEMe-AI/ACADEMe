import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../../academe_theme.dart';
import 'package:ACADEMe/widget/homepage_drawer.dart';
import 'dart:math';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ACADEMe/home/pages/progress/screens/progress_screen.dart';
import '../../localization/l10n.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:ACADEMe/home/pages/topic_view.dart';
import 'package:ACADEMe/started/pages/class.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/askme_button.dart';
import 'package:ACADEMe/home/pages/ask_me/screens/ask_me_screen.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/localization/language_provider.dart';

class HomeCourseDataCache {
  static final HomeCourseDataCache _instance = HomeCourseDataCache._internal();
  factory HomeCourseDataCache() => _instance;
  HomeCourseDataCache._internal();

  List<Map<String, dynamic>>? _cachedCourses;
  String? _cachedLanguage;
  DateTime? _lastFetchTime;

  static const Duration _cacheValidDuration = Duration(minutes: 30);

  bool isCacheValid(String language) {
    if (_lastFetchTime == null || _cachedCourses == null || _cachedLanguage != language) {
      return false;
    }
    return DateTime.now().difference(_lastFetchTime!) < _cacheValidDuration;
  }

  List<Map<String, dynamic>>? getCachedCourses(String language) {
    if (isCacheValid(language)) {
      return _cachedCourses;
    }
    return null;
  }

  void setCachedCourses(List<Map<String, dynamic>> courses, String language) {
    _cachedCourses = courses;
    _cachedLanguage = language;
    _lastFetchTime = DateTime.now();
  }

  void clearCache() {
    _cachedCourses = null;
    _cachedLanguage = null;
    _lastFetchTime = null;
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onCourseTap;
  final int selectedIndex;

  const HomePage({
    super.key,
    required this.onProfileTap,
    required this.onCourseTap,
    required this.selectedIndex,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController();
  final ValueNotifier<bool> _showSearchUI = ValueNotifier(false);
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final HomeCourseDataCache _cache = HomeCourseDataCache();
  List<Map<String, dynamic>> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCourses();
  }

  Future<void> _initializeCourses() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    List<Map<String, dynamic>>? cachedCourses = _cache.getCachedCourses(currentLanguage);
    if (cachedCourses != null) {
      setState(() {
        _courses = cachedCourses;
      });
      // Still fetch fresh data in background to update progress
      _fetchCourses(currentLanguage);
      return;
    }

    await _fetchCourses(currentLanguage);
  }

  Future<void> _refreshCourses() async {
    if (!mounted) return;

    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    // Clear cache to force fresh data
    _cache.clearCache();
    await _fetchCourses(currentLanguage);
  }

  Future<void> _fetchCourses(String language) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
    final String? token = await _secureStorage.read(key: 'access_token');

    if (token == null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("$backendUrl/api/courses/?target_language=$language"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        List<Map<String, dynamic>> coursesWithProgress = [];

        for (var course in data) {
          String courseId = course["id"].toString();
          int totalTopics = await _getTotalTopics(courseId);
          int completedCount = await _getCompletedTopicsCount(courseId);
          double progress = totalTopics > 0 ? completedCount / totalTopics : 0.0;

          coursesWithProgress.add({
            "id": courseId,
            "title": course["title"],
            "progress": progress,
            "completedModules": completedCount,
            "totalModules": totalTopics,
          });
        }

        _cache.setCachedCourses(coursesWithProgress, language);

        if (mounted) {
          setState(() {
            _courses = coursesWithProgress;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<int> _getTotalTopics(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('total_topics_$courseId') ?? 0;
  }

  Future<int> _getCompletedTopicsCount(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completedTopics = prefs.getStringList('completed_topics') ?? [];
    return completedTopics.where((key) => key.startsWith('$courseId|')).length;
  }

  Future<void> _fetchAndStoreUserDetails() async {
    try {
      final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
      final String? token = await _secureStorage.read(key: 'access_token');

      if (token == null) return;

      final response = await http.get(
        Uri.parse("$backendUrl/api/users/me"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        await _secureStorage.write(key: 'name', value: data['name']);
        await _secureStorage.write(key: 'email', value: data['email']);
        await _secureStorage.write(key: 'student_class', value: data['student_class']);
        await _secureStorage.write(key: 'photo_url', value: data['photo_url']);
      }
    } catch (e) {
      debugPrint("Error fetching user details: $e");
    }
  }

  Future<void> _checkAndShowClassSelection() async {
    final String? studentClass = await _secureStorage.read(key: 'student_class');
    if (studentClass == null || int.tryParse(studentClass) == null ||
        int.parse(studentClass) < 1 || int.parse(studentClass) > 12) {
      if (!mounted) return;
      await showClassSelectionSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _showSearchUI,
      builder: (context, showSearch, child) {
        return Scaffold(
          body: showSearch ? _buildSearchUI(context) : _buildMainUI(context),
        );
      },
    );
  }

  final List<Color?> predefinedColors = [
    Colors.pink[100],
    Colors.blue[100],
    Colors.green[100]
  ];

  final List<Color?> repeatingColors = [Colors.green[100], Colors.pink[100]];

  Widget _buildSearchUI(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    ValueNotifier<List<String>> searchResults = ValueNotifier([]);
    TextEditingController searchController = TextEditingController();
    List<String> allCourses = [];

    Future<void> loadCourses() async {
      try {
        allCourses = _courses.map((course) => course["title"].toString()).toList();
        searchResults.value = allCourses;
      } catch (e) {
        debugPrint("Error loading courses: $e");
      }
    }

    void searchCourses(String query) {
      if (query.isEmpty) {
        searchResults.value = allCourses;
        return;
      }
      searchResults.value = allCourses
          .where((title) => title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    loadCourses();

    return WillPopScope(
      onWillPop: () async {
        _showSearchUI.value = false;
        SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ));
        return false;
      },
      child: GestureDetector(
        onTap: () {
          _showSearchUI.value = false;
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ));
        },
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: TextField(
                  controller: searchController,
                  autofocus: true,
                  onChanged: searchCourses,
                  decoration: InputDecoration(
                    hintText: "${L10n.getTranslatedText(context, 'Search')}...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(26.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'Popular Searches'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Machine Learning')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Data Science')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(
                                  L10n.getTranslatedText(context, 'Flutter')),
                              onPressed: () {},
                            ),
                            ActionChip(
                              label: Text(L10n.getTranslatedText(
                                  context, 'Linear Algebra')),
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          L10n.getTranslatedText(context, 'Search Results'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ValueListenableBuilder<List<String>>(
                          valueListenable: searchResults,
                          builder: (context, results, _) {
                            return Column(
                              children: results
                                  .map(
                                    (title) => ListTile(
                                  leading: const Icon(Icons.book),
                                  title: Text(title),
                                  onTap: () {},
                                ),
                              )
                                  .toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          L10n.getTranslatedText(context, 'Recent Searches'),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(L10n.getTranslatedText(
                              context, 'Advanced Python')),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(L10n.getTranslatedText(
                              context, 'Cyber Security')),
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainUI(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    TextEditingController messageController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchAndStoreUserDetails();
      if (mounted) await _checkAndShowClassSelection();
    });

    return ASKMeButton(
      showFAB: true,
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMeScreen()),
        );
      },
      child: WillPopScope(
        onWillPop: () async {
          SystemNavigator.pop();
          return false;
        },
        child: Scaffold(
          key: scaffoldKey,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(105),
            child: AppBar(
              backgroundColor: AcademeTheme.appColor,
              automaticallyImplyLeading: false,
              elevation: 0,
              leading: Container(),
              flexibleSpace: Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: FutureBuilder<Map<String, String?>>(
                  future: _getUserDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text("Error loading user details"));
                    } else {
                      final String name = snapshot.data?['name'] ?? 'User';
                      final String photoUrl = snapshot.data?['photo_url'] ??
                          'assets/design_course/userImage.png';
                      return getAppBarUI(
                        widget.onProfileTap,
                            () {
                          scaffoldKey.currentState?.openDrawer();
                        },
                        widget.onCourseTap,
                        context,
                        name,
                        photoUrl,
                        _pageController,
                        widget.selectedIndex,
                      );
                    }
                  },
                ),
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
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: TextField(
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
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(30),
                              blurRadius: 8,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: ClipOval(
                                      child: Image.asset(
                                        "assets/icons/ASKMe.png",
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        L10n.getTranslatedText(
                                            context, 'Your Personal Tutor'),
                                        style: TextStyle(
                                          color: const Color.fromARGB(255, 10, 10, 10),
                                          fontSize: width * 0.06,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: "Roboto",
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "ASKMe",
                                        style: TextStyle(
                                          color: const Color.fromARGB(255, 9, 9, 9),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: messageController,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 12),
                                        hintText: L10n.getTranslatedText(
                                            context, 'ASKMe Anything...'),
                                        hintStyle: TextStyle(color: Colors.grey[600]),
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.blue,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Transform.rotate(
                                  angle: -pi / 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.send,
                                        color: Colors.blue, size: 24),
                                    onPressed: () {
                                      String message = messageController.text.trim();
                                      if (message.isNotEmpty) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AskMeScreen(initialMessage: message),
                                          ),
                                        );
                                        messageController.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ProgressScreen()),
                          );
                        },
                        child: Card(
                          color: Colors.indigoAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      L10n.getTranslatedText(
                                          context, 'My Progress'),
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      L10n.getTranslatedText(
                                          context, 'Track your progress'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color.fromARGB(255, 247, 177, 55),
                                      ),
                                      child: const Icon(
                                          Icons.local_fire_department,
                                          color: Colors.white,
                                          size: 24),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Text(
                                          "420",
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildContinueLearningSection(context),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(0.0),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          // borderRadius: BorderRadius.circular(12.0),
                          // border: Border.all(
                          //   color: Colors.grey.shade300,
                          //   width: 1.5,
                          // ),
                          // boxShadow: [
                          //   BoxShadow(
                          //     color: Colors.black.withAlpha(30),
                          //     blurRadius: 8,
                          //     spreadRadius: 2,
                          //     offset: const Offset(0, 4),
                          //   ),
                          // ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildSwipeableBanner(_pageController, context),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    L10n.getTranslatedText(
                                        context, 'All Courses'),
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  TextButton(
                                    onPressed: widget.onCourseTap,
                                    child: Text(
                                      L10n.getTranslatedText(
                                          context, 'See All'),
                                      style: const TextStyle(
                                          fontSize: 17, color: Colors.blue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 0),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(22),
                                            border: Border.all(
                                                color: Colors.red, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.red.withAlpha(50),
                                                ),
                                                child: const Icon(Icons.book,
                                                    size: 16, color: Colors.red),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                  L10n.getTranslatedText(
                                                      context, 'English'),
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.orange, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.orange.withAlpha(50),
                                                ),
                                                child: const Icon(Icons.calculate,
                                                    size: 16, color: Colors.orange),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                  L10n.getTranslatedText(
                                                      context, 'Maths'),
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.blue, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.blue.withAlpha(50),
                                                ),
                                                child: const Icon(Icons.language,
                                                    size: 16, color: Colors.blue),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                  L10n.getTranslatedText(
                                                      context, 'Language'),
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 6, horizontal: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                                color: Colors.green, width: 1.5),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: Colors.green.withAlpha(50),
                                                ),
                                                child: const Icon(Icons.science,
                                                    size: 16, color: Colors.green),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                  L10n.getTranslatedText(
                                                      context, 'Biology'),
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    L10n.getTranslatedText(
                                        context, 'My Courses'),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onCourseTap,
                                    child: Text(
                                      L10n.getTranslatedText(
                                          context, 'See All'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 0),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.2,
                              ),
                              itemCount: _courses.length,
                              itemBuilder: (context, index) {
                                return CourseCard(
                                  _courses[index]["title"],
                                  "${(index + 10) * 2} ${L10n.getTranslatedText(context, 'Lessons')}",
                                  repeatingColors[
                                  index % repeatingColors.length]!,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TopicViewScreen(
                                          courseId: _courses[index]["id"],
                                        ),
                                      ),
                                    );
                                    // Refresh courses when returning from topic view
                                    _refreshCourses();
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                L10n.getTranslatedText(context, 'Recommended'),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: SizedBox(
                                height: 160,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: CourseCard(
                                        L10n.getTranslatedText(
                                            context, 'Marketing'),
                                        "9 ${L10n.getTranslatedText(context, 'Lessons')}",
                                        Colors.pink[100]!,
                                        onTap: () {},
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: CourseCard(
                                        L10n.getTranslatedText(
                                            context, 'Trading'),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildContinueLearningSection(BuildContext context) {
    // Filter courses: progress > 0% and < 100%
    final ongoingCourses = _courses.where((course) =>
    course["progress"] > 0 && course["progress"] < 1).toList();

    if (ongoingCourses.isEmpty || _isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Continue Learning'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            TextButton(
              onPressed: widget.onCourseTap,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                L10n.getTranslatedText(context, 'See All'),
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: ongoingCourses.map((course) {
            return Column(
              children: [
                learningCard(
                  course["title"],
                  course["completedModules"],
                  course["totalModules"],
                  (course["progress"] * 100).toInt(),
                  predefinedColors.length > ongoingCourses.indexOf(course)
                      ? predefinedColors[ongoingCourses.indexOf(course)]!
                      : Colors.primaries[ongoingCourses.indexOf(course) %
                      Colors.primaries.length][100]!,
                      () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TopicViewScreen(
                          courseId: course["id"],
                        ),
                      ),
                    );
                    // Refresh courses when returning from topic view
                    _refreshCourses();
                  },
                ),
                const SizedBox(height: 12),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<Map<String, String?>> _getUserDetails() async {
    final String? name = await _secureStorage.read(key: 'name');
    final String? photoUrl = await _secureStorage.read(key: 'photo_url');
    return {
      'name': name,
      'photo_url': photoUrl,
    };
  }
}

Widget barGraph(double yellowHeight, double purpleHeight) {
  return Column(
    children: [
      Container(
        height: purpleHeight,
        width: 22,
        decoration: const BoxDecoration(
          color: Colors.grey,
        ),
      ),
      Container(
        height: yellowHeight,
        width: 24,
        decoration: const BoxDecoration(
          color: Colors.yellow,
        ),
      ),
    ],
  );
}

Widget learningCard(String title, int completed, int total, int percentage,
    Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Text("$completed / $total"),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: percentage / 100,
                  color: Colors.blue,
                  backgroundColor: Colors.grey[300],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: Colors.grey[600]),
                onPressed: onTap,
              ),
              const SizedBox(height: 10),
              Text("$percentage%"),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget getAppBarUI(
    VoidCallback onProfileTap,
    VoidCallback onHamburgerTap,
    VoidCallback onCourseTap,
    BuildContext context,
    String name,
    String photoUrl,
    PageController pageController,
    int selectedIndex,
    ) {
  return Container(
    height: 100,
    padding: const EdgeInsets.only(top: 38.0, left: 18, right: 18, bottom: 5),
    child: Row(
      children: <Widget>[
        GestureDetector(
          onTap: onProfileTap,
          child: CircleAvatar(
            radius: 30,
            backgroundImage: photoUrl.startsWith('http')
                ? NetworkImage(photoUrl) as ImageProvider
                : AssetImage(photoUrl),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              L10n.getTranslatedText(context, 'Hello'),
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          width: 40,
          height: 40,
          child: IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.black,
              size: 20,
            ),
            onPressed: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: true,
                barrierLabel: "Dismiss",
                barrierColor: Colors.black.withAlpha(70),
                transitionDuration: const Duration(milliseconds: 300),
                pageBuilder: (context, animation, secondaryAnimation) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      heightFactor: 1,
                      child: Material(
                        color: Colors.white,
                        child: HomepageDrawer(
                            onClose: () => Navigator.of(context).pop(),
                            onProfileTap: onProfileTap,
                            onCourseTap: onCourseTap
                        ),
                      ),
                    ),
                  );
                },
                transitionBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(-1, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("See All", style: TextStyle(color: Colors.blue, fontSize: 14)),
      ],
    );
  }
}

Widget buildSwipeableBanner(PageController controller, BuildContext context) {
  return SizedBox(
    height: 170,
    child: Column(
      children: [
        Expanded(
          child: PageView(
            controller: controller,
            children: [
              adContainer(
                  Colors.purple[200]!, 'assets/images/img.png', context),
              adContainer(Colors.blue[200]!, 'assets/images/img.png', context),
              adContainer(Colors.green[200]!, 'assets/images/img.png', context),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SmoothPageIndicator(
          controller: controller,
          count: 3,
          effect: ExpandingDotsEffect(
            activeDotColor: Colors.purple,
            dotColor: Colors.grey[300]!,
            dotHeight: 8,
            dotWidth: 8,
            expansionFactor: 2,
          ),
        ),
      ],
    ),
  );
}

Widget adContainer(Color color, String imagePath, BuildContext context) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
    child: Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        L10n.getTranslatedText(context, 'Clear your doubts'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${L10n.getTranslatedText(context, 'Experts ready to clear')} \n${L10n.getTranslatedText(context, 'your doubts anytime')}",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 0),
            ],
          ),
        ),
        Positioned(
          right: 5,
          top: 8,
          child: Image.asset(
            imagePath,
            width: 140,
            height: 150,
            fit: BoxFit.cover,
          ),
        ),
      ],
    ),
  );
}

class CourseTag extends StatelessWidget {
  final String text;
  final Color color;

  const CourseTag(this.text, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 12),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.black, fontSize: 14)),
        ],
      ),
    );
  }
}

Widget courseBox(IconData icon, String label, Color color) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 2),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withAlpha(40),
          ),
          child: Icon(
            icon,
            size: 24,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class CourseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const CourseCard(
      this.title,
      this.subtitle,
      this.color, {
        super.key,
        required this.onTap,
      });

  IconData _getSubjectIcon(String title) {
    switch (title.toLowerCase()) {
      case 'mathematics':
      case 'math':
      case 'algebra':
        return Icons.calculate;
      case 'science':
      case 'physics':
      case 'chemistry':
      case 'biology':
        return Icons.science;
      case 'english':
      case 'language':
        return Icons.menu_book;
      case 'computer':
      case 'programming':
      case 'coding':
        return Icons.computer;
      case 'history':
      case 'geography':
      case 'social studies':
        return Icons.public;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width * 0.42,
        height: height * 0.20,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _getSubjectIcon(title),
              size: width * 0.10,
              color: Colors.black.withAlpha(180),
            ),
            SizedBox(height: height * 0.015),
            AutoSizeText(
              title,
              style: TextStyle(
                fontSize: width * 0.045,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              minFontSize: 12,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: height * 0.008),
            AutoSizeText(
              subtitle,
              style: TextStyle(
                fontSize: width * 0.035,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              minFontSize: 10,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}