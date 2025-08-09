import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:flutter/animation.dart';
import '../../../../../api_endpoints.dart';
import '../../../../../providers/progress_provider.dart';

class FlashCardController with ChangeNotifier {
  final List<Map<String, String>> materials;
  final List<Map<String, dynamic>> quizzes;
  final Function()? onQuizComplete;
  final int initialIndex;
  final String courseId;
  final String topicId;
  final String subtopicId;
  final String subtopicTitle;
  final String? language;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentPage = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
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
  AnimationController? _celebrationController;
  Animation<double>? _bounceAnimation;
  Animation<double>? _scaleAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _pulseAnimation;
  Animation<double>? _rotateAnimation;
  final SwiperController _swiperController = SwiperController();
  bool _isDisposed = false;

  FlashCardController({
    required this.materials,
    required this.quizzes,
    this.onQuizComplete,
    this.initialIndex = 0,
    required this.courseId,
    required this.topicId,
    required this.subtopicId,
    required this.subtopicTitle,
    this.language,
  }) : _currentPage = initialIndex {
    _loadSwipeHintState();
    fetchTopicDetails();

    if (materials.isEmpty && quizzes.isEmpty) {
      Future.delayed(Duration.zero, () {
        if (!_isDisposed && onQuizComplete != null) {
          onQuizComplete!();
        }
      });
    } else {
      _setupVideoController();
      _preloadAdjacentMaterials();
    }

    if (_currentPage < materials.length) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          unawaited(_sendProgressToBackend());
        }
      });
    }

    if (_showSwipeHint) {
      Timer(const Duration(seconds: 3), () {
        if (!_isDisposed) {
          hideSwipeHint();
        }
      });
    }
  }

  // Getters
  int get currentPage => _currentPage;
  bool get showSwipeHint => _showSwipeHint;
  bool get isTransitioning => _isTransitioning;
  bool get showCelebration => _showCelebration;
  VideoPlayerController? get videoController => _videoController;
  ChewieController? get chewieController => _chewieController;
  AudioPlayer get audioPlayer =>
      _audioPlayer; // Added public getter for audio player
  String get currentTopicTitle => topicTitle;
  SwiperController get swiperController => _swiperController;
  AnimationController? get celebrationController => _celebrationController;
  Animation<double>? get bounceAnimation => _bounceAnimation;
  Animation<double>? get scaleAnimation => _scaleAnimation;
  Animation<Offset>? get slideAnimation => _slideAnimation;
  Animation<double>? get pulseAnimation => _pulseAnimation;
  Animation<double>? get rotateAnimation => _rotateAnimation;
  bool get animationsInitialized => _celebrationController != null;

  void initializeAnimations(TickerProvider vsync) {
    if (_isDisposed) return;

    _celebrationController?.dispose();

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: vsync,
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController!,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _celebrationController!,
        curve: const Interval(0.2, 0.8, curve: Curves.bounceOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _celebrationController!,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _celebrationController!,
        curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _celebrationController!,
        curve: const Interval(0.7, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  void hideSwipeHint() async {
    if (_showSwipeHint && !_isDisposed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_swipe_hint', false);
      _showSwipeHint = false;
      notifyListeners();
    }
  }

  void _preloadAdjacentMaterials() {
    if (_isDisposed) return;

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
      if (!_isDisposed) {
        _processPreloadQueue();
      }
    });
  }

  void _processPreloadQueue() async {
    while (_preloadQueue.isNotEmpty && !_isDisposed) {
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
      if (_isDisposed) return;

      _cachedVideos[index] = file;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      if (_isDisposed) {
        controller.dispose();
        return;
      }

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
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _handleSwipe() async {
    if (_showSwipeHint && !_isDisposed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_swipe_hint', false);
      _showSwipeHint = false;
      notifyListeners();
    }
  }

  Future<void> fetchTopicDetails() async {
    if (_isDisposed) return;

    String? token = await _storage.read(key: 'access_token');
    if (token == null) {
      debugPrint("❌ Missing access token");
      return;
    }

    try {
      final url = language != null
          ? ApiEndpoints.topicSubtopics(courseId, topicId, language!)
          : ApiEndpoints.topicSubtopicsNoLang(courseId, topicId);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (_isDisposed) return;

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
      if (!_isDisposed) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateTopicDetails(Map<String, dynamic> data) {
    if (_isDisposed) return;

    topicTitle = data["title"]?.toString() ?? "Untitled Topic";
    notifyListeners();
  }

  Future<void> _setupVideoController() async {
    if (_isDisposed) return;

    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
    }
    _videoController?.pause();
    _videoController?.dispose();
    _chewieController?.pause();
    _chewieController?.dispose();

    if (_currentPage < materials.length &&
        materials[_currentPage]["type"] == "video") {
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
        if (_isDisposed) {
          _videoController?.dispose();
          return;
        }
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
        if (_isDisposed) {
          _videoController?.dispose();
          return;
        }
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
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _videoListener() {
    if (_isDisposed || _videoController == null) return;

    if (_videoController!.value.isInitialized &&
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
    if (_isDisposed) return;

    final material = getCurrentMaterial();
    final materialId = material["id"] ?? "material_$_currentPage";

    // Check if already completed using cached data
    final progressProvider = ProgressProvider();
    final isCompleted = progressProvider.isActivityCompleted(
      courseId: courseId,
      topicId: topicId,
      activityId: materialId,
      activityType: 'reading',
    );

    if (isCompleted) return;

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

    // Queue for batched processing
    progressProvider.queueProgressUpdate(progressData);
  }

  Future<void> nextMaterialOrQuiz() async {
    if (_isDisposed) return;

    final totalItems = materials.length + quizzes.length;
    final hasNextPage = _currentPage < totalItems - 1;

    if (hasNextPage) {
      _isTransitioning = true;
      notifyListeners();

      // Play celebration animation if available
      if (animationsInitialized) {
        _showCelebration = true;
        notifyListeners();
        await _celebrationController!.forward();
        _showCelebration = false;
        notifyListeners();
      }

      final nextPage = _currentPage + 1;
      _currentPage = nextPage;

      // Skip material setup if next page is a quiz
      if (nextPage >= materials.length) {
        // Directly navigate to next quiz without material setup
        swiperController.move(_currentPage, animation: false);
        _isTransitioning = false;
        notifyListeners();
        return;
      }

      // Existing material setup
      swiperController.move(_currentPage, animation: false);
      await _setupVideoController();
      _preloadAdjacentMaterials();

      _isTransitioning = false;
      notifyListeners();

      if (_currentPage < materials.length) {
        unawaited(_sendProgressToBackend());
      }
    } else {
      if (onQuizComplete != null) {
        onQuizComplete!();
      }
    }
  }

  void updateCurrentPage(int index) {
    if (_isDisposed) return;

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
    _isDisposed = true;
    _showSwipeHint = false;

    // Pause and dispose video controllers
    _videoController?.pause();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _videoController = null;

    _chewieController?.pause();
    _chewieController?.dispose();
    _chewieController = null;

    // Stop audio player
    _audioPlayer.stop();
    _audioPlayer.dispose();

    // Cancel timers
    _preloadTimer?.cancel();
    _preloadTimer = null;

    // Dispose animations
    _celebrationController?.dispose();
    _celebrationController = null;

    // Dispose swiper controller
    _swiperController.dispose();

    // Dispose all preloaded controllers
    for (final controller in _preloadedControllers.values) {
      controller.pause();
      controller.dispose();
    }
    _preloadedControllers.clear();

    for (final controller in _preloadedChewieControllers.values) {
      controller.pause();
      controller.dispose();
    }
    _preloadedChewieControllers.clear();

    super.dispose();
  }
}
