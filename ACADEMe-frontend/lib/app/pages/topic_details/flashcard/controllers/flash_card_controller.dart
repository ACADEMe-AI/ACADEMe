import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  String _selectedQuality = 'auto';
  final List<String> _availableQualities = ['auto', '144p', '240p', '360p', '480p', '720p', '1080p', '1440p', '2160p'];
  String _adaptiveQuality = '480p';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _networkTestTimer;
  Duration _lastVideoPosition = Duration.zero;
  bool _isChangingQuality = false;
  bool _wasPlayingBeforeQualityChange = false;

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
    _loadQualitySettings();
    _startNetworkMonitoring();
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
  String get selectedQuality => _selectedQuality;
  List<String> get availableQualities => _availableQualities;
  String get currentAdaptiveQuality => _adaptiveQuality;
  bool get isChangingQuality => _isChangingQuality;

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
      final qualityUrl = _getQualityUrl(url, _selectedQuality); // Modified this line
      final file = await _cacheManager.getSingleFile(qualityUrl); // Modified this line
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

  void setVideoQuality(String quality) async {
    if (_selectedQuality != quality && !_isChangingQuality) {
      _isChangingQuality = true;
      notifyListeners();

      // Save current state
      if (_videoController != null && _videoController!.value.isInitialized) {
        _lastVideoPosition = _videoController!.value.position;
        _wasPlayingBeforeQualityChange = _videoController!.value.isPlaying;
      }

      _selectedQuality = quality;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('video_quality', quality);

      // Restart video with new quality if currently playing video
      if (_currentPage < materials.length && materials[_currentPage]["type"] == "video") {
        await _setupVideoController();
      }

      _isChangingQuality = false;
      notifyListeners();
    }
  }

  Future<void> _loadQualitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedQuality = prefs.getString('video_quality') ?? 'auto';
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  String _getQualityUrl(String originalUrl, String quality) {
    // Use adaptive quality when auto is selected
    String targetQuality = quality == 'auto' ? _adaptiveQuality : quality;

    if (targetQuality == '2160p' && quality == 'auto') {
      return originalUrl; // Return original for auto-detected 4K quality
    }

    // For Cloudinary URLs, add quality transformation
    if (originalUrl.contains('cloudinary.com')) {
      final urlParts = originalUrl.split('/upload/');
      if (urlParts.length == 2) {
        String qualityParam;
        switch (targetQuality) {
          case '144p':
            qualityParam = 'q_auto:low,h_144,c_limit,br_150k';
            break;
          case '240p':
            qualityParam = 'q_auto:low,h_240,c_limit,br_300k';
            break;
          case '360p':
            qualityParam = 'q_auto:good,h_360,c_limit,br_600k';
            break;
          case '480p':
            qualityParam = 'q_auto:good,h_480,c_limit,br_1000k';
            break;
          case '720p':
            qualityParam = 'q_auto:good,h_720,c_limit,br_2000k';
            break;
          case '1080p':
            qualityParam = 'q_auto:good,h_1080,c_limit,br_4000k';
            break;
          case '1440p':
            qualityParam = 'q_auto:good,h_1440,c_limit,br_8000k';
            break;
          case '2160p':
            qualityParam = 'q_auto:good,h_2160,c_limit,br_15000k';
            break;
          default:
            return originalUrl;
        }
        return '${urlParts[0]}/upload/$qualityParam/${urlParts[1]}';
      }
    }

    return originalUrl; // Return original if not Cloudinary or parsing fails
  }

  // Add this entire method
  void _startNetworkMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Handle the list of connectivity results
      if (results.isNotEmpty) {
        _testNetworkSpeed();
      }
    });

    // Test network speed periodically when in auto mode
    _networkTestTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_selectedQuality == 'auto' && !_isDisposed) {
        _testNetworkSpeed();
      }
    });

    // Initial network test
    _testNetworkSpeed();
  }

  Future<void> _testNetworkSpeed() async {
    if (_selectedQuality != 'auto' || _isDisposed) return;

    try {
      final stopwatch = Stopwatch()..start();

      // Test with a small image from Cloudinary (about 50KB)
      final response = await http.get(
        Uri.parse('https://res.cloudinary.com/demo/image/upload/w_500,h_500,c_limit/sample.jpg'),
      ).timeout(const Duration(seconds: 10));

      stopwatch.stop();

      if (response.statusCode == 200) {
        final bytes = response.contentLength ?? response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        final speedKbps = (bytes * 8) / (seconds * 1000); // Convert to Kbps

        String newQuality = _determineQualityFromSpeed(speedKbps);

        if (newQuality != _adaptiveQuality) {
          _adaptiveQuality = newQuality;
          debugPrint('Network speed: ${speedKbps.toStringAsFixed(1)} Kbps - Selected: $newQuality');

          // Save current position before reloading video
          if (_videoController != null && _videoController!.value.isInitialized &&
              _currentPage < materials.length && materials[_currentPage]["type"] == "video") {
            _lastVideoPosition = _videoController!.value.position;
            await _setupVideoController();
          }

          if (!_isDisposed) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('Network speed test failed: $e');
      // Fallback to 360p on error
      if (_adaptiveQuality != '360p') {
        _adaptiveQuality = '360p';
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    }
  }

  String _determineQualityFromSpeed(double speedKbps) {
    if (speedKbps < 500) {
      return '144p'; // Very slow connection
    } else if (speedKbps < 1000) {
      return '240p'; // Slow connection
    } else if (speedKbps < 2000) {
      return '360p'; // Medium connection
    } else if (speedKbps < 5000) {
      return '480p'; // Good connection
    } else if (speedKbps < 10000) {
      return '720p'; // Fast connection
    } else {
      return '1080p'; // Very fast connection
    }
  }

  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Video Quality'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _availableQualities.length,
              itemBuilder: (context, index) {
                final quality = _availableQualities[index];
                final isSelected = _selectedQuality == quality;

                return ListTile(
                  leading: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                  title: Text(
                    quality == 'auto'
                        ? 'Auto (${_adaptiveQuality.toUpperCase()})'
                        : quality.toUpperCase(),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(_getQualityDescription(quality)),
                  onTap: () {
                    Navigator.pop(context);
                    if (!isSelected) {
                      setVideoQuality(quality);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getQualityDescription(String quality) {
    switch (quality) {
      case 'auto': return 'Adapts to network speed';
      case '144p': return 'Data saver';
      case '240p': return 'Low bandwidth';
      case '360p': return 'Standard definition';
      case '480p': return 'Enhanced definition';
      case '720p': return 'High definition';
      case '1080p': return 'Full HD';
      case '1440p': return 'Quad HD';
      case '2160p': return '4K Ultra HD';
      default: return '';
    }
  }

  ChewieController _createChewieController(VideoPlayerController videoController) {
    return ChewieController(
      videoPlayerController: videoController,
      autoPlay: true,
      looping: false,
      allowMuting: true,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: true,
      showOptions: true,
      showControlsOnInitialize: true,
      hideControlsTimer: const Duration(seconds: 3),
      additionalOptions: (context) {
        return <OptionItem>[
          OptionItem(
            onTap: (context) {
              Navigator.pop(context);
              _showQualityDialog(context);
            },
            iconData: Icons.video_settings,
            title: _selectedQuality == 'auto'
                ? 'Quality: Auto (${_adaptiveQuality.toUpperCase()})'
                : 'Quality: ${_selectedQuality.toUpperCase()}',
          ),
        ];
      },
    );
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

    // Properly dispose controllers
    if (_videoController != null) {
      _videoController!.removeListener(_videoListener);
      _videoController?.pause();
      if (!_isChangingQuality) {
        _videoController?.dispose();
      }
    }
    if (_chewieController != null) {
      _chewieController?.pause();
      if (!_isChangingQuality) {
        _chewieController?.dispose();
        _chewieController = null;
      }
    }

    if (_currentPage < materials.length &&
        materials[_currentPage]["type"] == "video") {
      final originalUrl = materials[_currentPage]["content"]!;
      final qualityUrl = _getQualityUrl(originalUrl, _selectedQuality);

      try {
        // Always create new controller for quality changes
        _videoController = VideoPlayerController.network(qualityUrl);
        await _videoController!.initialize();

        if (_isDisposed) {
          _videoController?.dispose();
          return;
        }

        // Create new Chewie controller
        _chewieController?.dispose();
        _chewieController = _createChewieController(_videoController!);

        // Restore position if available
        if (_lastVideoPosition != Duration.zero) {
          await _videoController!.seekTo(_lastVideoPosition);
          if (_wasPlayingBeforeQualityChange && !_isChangingQuality) {
            await _videoController!.play();
          }
          if (!_isChangingQuality) {
            _lastVideoPosition = Duration.zero;
            _wasPlayingBeforeQualityChange = false;
          }
        }

        _videoController!.addListener(_videoListener);

      } catch (e) {
        debugPrint('Error setting up video controller: $e');
        _isChangingQuality = false;
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

    // Don't auto-reset when video completes - let Chewie handle it
    if (_videoController!.value.isInitialized) {
      notifyListeners();
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

    // Cancel network monitoring
    _connectivitySubscription?.cancel(); // Add this
    _networkTestTimer?.cancel(); // Add this

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
