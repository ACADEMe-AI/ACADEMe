import 'dart:async';
import 'dart:async' show unawaited;
import 'dart:io';
import 'package:ACADEMe/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:flutter/animation.dart';

class FlashCardController with ChangeNotifier {
  final List<Map<String, String>> materials;
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final int initialIndex;
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String subtopicTitle;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentPage = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://10.0.2.2:8000';
  String topicTitle = "Loading...";
  bool _showSwipeHint = true;
  bool isLoading = true;
  bool _isTransitioning = false;
  final Map<int, File> _cachedVideos = {};
  final Map<int, File> _cachedImages = {};
  final Map<int, File> _cachedAudios = {};
  final Map<int, File> _cachedDocuments = {};
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  Timer? _preloadTimer;
  List<int> _preloadQueue = [];
  final Map<int, VideoPlayerController> _preloadedControllers = {};
  final Map<int, ChewieController> _preloadedChewieControllers = {};
  bool _showCelebration = false;
  late AnimationController _celebrationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;
  final SwiperController _swiperController = SwiperController();

  FlashCardController({
    required this.materials,
    required this.quizzes,
    this.onQuizComplete,
    this.initialIndex = 0,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.subtopicTitle,
  }) : _currentPage = initialIndex {
    _loadSwipeHintState();
    fetchTopicDetails();

    if (materials.isEmpty && quizzes.isEmpty) {
      Future.delayed(Duration.zero, () {
        if (onQuizComplete != null) {
          onQuizComplete!();
        }
      });
    } else {
      _setupVideoController();
      _preloadAdjacentMaterials();
    }

    // Send progress for the initial material
    if (materials.isNotEmpty && _currentPage < materials.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        unawaited(_sendProgressToBackend());
      });
    }

    if (_showSwipeHint) {
      Timer(const Duration(seconds: 3), () {
        hideSwipeHint();
      });
    }
  }

  int get currentPage => _currentPage;
  bool get showSwipeHint => _showSwipeHint;
  bool get isTransitioning => _isTransitioning;
  bool get showCelebration => _showCelebration;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  String get currentTopicTitle => topicTitle;
  SwiperController get swiperController => _swiperController;
  AnimationController get celebrationController => _celebrationController;
  Animation<double> get bounceAnimation => _bounceAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<Offset> get slideAnimation => _slideAnimation;
  Animation<double> get pulseAnimation => _pulseAnimation;
  Animation<double> get rotateAnimation => _rotateAnimation;

  void initializeAnimations(TickerProvider vsync) {
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: vsync,
    );
    
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.2, 0.8, curve: Curves.bounceOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _celebrationController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  void hideSwipeHint() async {
    if (_showSwipeHint) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_swipe_hint', false);
      _showSwipeHint = false;
      notifyListeners();
    }
  }

  void _preloadAdjacentMaterials() {
    _preloadTimer?.cancel();
    _preloadQueue.clear();

    final totalPages = materials.length + quizzes.length;
    _preloadQueue = [
      _currentPage - 1,
      _currentPage,
      _currentPage + 1,
      _currentPage + 2,
    ].where((index) => index >= 0 && index < totalPages).toList();

    _preloadTimer = Timer(const Duration(milliseconds: 300), () {
      _processPreloadQueue();
    });
  }

  void _processPreloadQueue() async {
    while (_preloadQueue.isNotEmpty) {
      final index = _preloadQueue.removeAt(0);

      if (index < materials.length) {
        final material = materials[index];
        switch (material["type"]) {
          case "video":
            if (!_cachedVideos.containsKey(index) ||
                !_preloadedControllers.containsKey(index)) {
              await _preloadAndInitializeVideo(index, material["content"]!);
            }
            break;
          case "image":
            if (!_cachedImages.containsKey(index)) {
              final file = await _preloadImage(material["content"]!);
              if (file != null) _cachedImages[index] = file;
            }
            break;
          case "audio":
            if (!_cachedAudios.containsKey(index)) {
              final file = await _preloadFile(material["content"]!);
              if (file != null) _cachedAudios[index] = file;
            }
            break;
          case "document":
            if (!_cachedDocuments.containsKey(index)) {
              final file = await _preloadFile(material["content"]!);
              if (file != null) _cachedDocuments[index] = file;
            }
            break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _preloadAndInitializeVideo(int index, String url) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      _cachedVideos[index] = file;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        looping: false,
        allowMuting: true,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );

      _preloadedControllers[index] = controller;
      _preloadedChewieControllers[index] = chewieController;
    } catch (e) {
      debugPrint("Error preloading video: $e");
    }
  }

  Future<File?> _preloadImage(String url) async {
    try {
      return await _cacheManager.getSingleFile(url);
    } catch (e) {
      debugPrint("Error preloading image: $e");
      return null;
    }
  }

  Future<File?> _preloadFile(String url) async {
    try {
      return await _cacheManager.getSingleFile(url);
    } catch (e) {
      debugPrint("Error preloading file: $e");
      return null;
    }
  }

  Future<void> _loadSwipeHintState() async {
    final prefs = await SharedPreferences.getInstance();
    _showSwipeHint = prefs.getBool('show_swipe_hint') ?? true;
    notifyListeners();
  }

  void _handleSwipe() async {
    if (_showSwipeHint) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_swipe_hint', false);
      _showSwipeHint = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopicDetails() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      return;
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.topicSubtopicsNoLang(courseId, topicId)),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final String responseBody = utf8.decode(response.bodyBytes);
        final dynamic jsonData = jsonDecode(responseBody);

        if (jsonData is List) {
          if (jsonData.isNotEmpty && jsonData[0] is Map<String, dynamic>) {
            updateTopicDetails(jsonData[0]);
          }
        } else if (jsonData is Map<String, dynamic>) {
          updateTopicDetails(jsonData);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching topic details: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    topicTitle = data["title"]?.toString() ?? "Untitled Topic";
    notifyListeners();
  }

  void _setupVideoController() async {
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
    }
    _videoController?.dispose();
    _chewieController?.dispose();

    if (_currentPage < materials.length && materials[_currentPage]["type"] == "video") {
      if (_preloadedControllers.containsKey(_currentPage)) {
        _videoController = _preloadedControllers[_currentPage];
        _chewieController = _preloadedChewieControllers[_currentPage];
        _preloadedControllers.remove(_currentPage);
        _preloadedChewieControllers.remove(_currentPage);
        _videoController!.play();
        _videoController!.addListener(_videoListener);
      } else if (_cachedVideos.containsKey(_currentPage)) {
        final videoFile = _cachedVideos[_currentPage]!;
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowMuting: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );
        _videoController!.addListener(_videoListener);
      } else {
        final videoUrl = materials[_currentPage]["content"]!;
        _videoController = VideoPlayerController.network(videoUrl);
        await _videoController!.initialize();
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: true,
          looping: false,
          allowMuting: true,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );
        _videoController!.addListener(_videoListener);
      }
    } else {
      _videoController = null;
      _chewieController = null;
    }
    notifyListeners();
  }

  void _videoListener() {
    if (_videoController != null &&
        _videoController!.value.isInitialized &&
        !_videoController!.value.isPlaying &&
        _videoController!.value.position >= _videoController!.value.duration) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.pause();
    }
  }

  Map<String, dynamic> getCurrentMaterial() {
    if (_currentPage < materials.length) {
      return materials[_currentPage];
    } else {
      return {
        "type": "quiz",
        "quiz": quizzes[_currentPage - materials.length],
      };
    }
  }

  Future<void> _sendProgressToBackend() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final material = getCurrentMaterial();
    final materialId = material["id"] ?? "material_$_currentPage";

    final progressList = await _fetchProgressList();
    final progressExists = progressList.any((progress) =>
        progress["material_id"] == materialId &&
        progress["activity_type"] == "reading");

    if (progressExists) return;

    final progressData = {
      "course_id": courseId,
      "topic_id": topicId,
      "subtopic_id": subtopicId,
      "material_id": materialId,
      "quiz_id": null,
      "question_id": null,
      "score": 0,
      "status": "completed",
      "activity_type": "reading",
      "metadata": {"time_spent": "5 minutes"},
      "timestamp": DateTime.now().toIso8601String(),
    };

    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.progressNoLang),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(progressData),
      );

      if (response.statusCode != 200) {
        debugPrint("❌ Failed to update progress: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error updating progress: $e");
    }
  }

  Future<List<dynamic>> _fetchProgressList() async {
    String? token = await _storage.read(key: 'access_token');
    if (token == null) return [];

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.progressNoLang),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody is Map<String, dynamic> && responseBody.containsKey("progress")) {
          return responseBody["progress"];
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching progress: $e");
    }
    return [];
  }

  Future<void> nextMaterialOrQuiz() async {
    final totalItems = materials.length + quizzes.length;
    final hasNextPage = _currentPage < totalItems - 1;

    if (hasNextPage) {
      _showCelebration = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 1200));

      final nextPage = _currentPage + 1;
      _currentPage = nextPage;
      _isTransitioning = true;
      notifyListeners();

      await Future.delayed(const Duration(milliseconds: 300));

      _isTransitioning = false;
      _setupVideoController();
      _preloadAdjacentMaterials();

      if (_currentPage < materials.length) {
        unawaited(_sendProgressToBackend());
      }

      _showCelebration = false;
      notifyListeners();
    } else {
      if (onQuizComplete != null) {
        onQuizComplete!();
      }
    }
  }

  void updateCurrentPage(int index) {
    _handleSwipe();
    if (_currentPage != index) {
      _currentPage = index;
      notifyListeners();
      _setupVideoController();
      _preloadAdjacentMaterials();

      if (_currentPage < materials.length) {
        unawaited(_sendProgressToBackend());
      }
    }
  }

  @override
  void dispose() {
    _showSwipeHint = false;
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();
    _audioPlayer.dispose();
    _preloadTimer?.cancel();
    _celebrationController.dispose();
    _swiperController.dispose();

    for (final controller in _preloadedControllers.values) {
      controller.dispose();
    }
    for (final controller in _preloadedChewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}