import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:ACADEMe/app/pages/homepage/controllers/home_controller.dart';
import 'package:ACADEMe/app/pages/topics/controllers/topic_cache_controller.dart';

class AppStateManager {
  static final FlutterSecureStorage _secureStorage =
      const FlutterSecureStorage();

  static Future<void> resetAppState() async {
    try {
      debugPrint("🔄 Starting complete app state reset...");

      // 1. Clear all secure storage
      await _clearSecureStorage();

      // 2. Clear shared preferences
      await _clearSharedPreferences();

      // 3. Clear all controller caches
      await _clearControllerCaches();

      // 4. Clear image cache
      _clearImageCache();

      // 5. Clear temporary files
      await _clearTemporaryFiles();

      debugPrint("🎉 App state reset completed successfully");
    } catch (e) {
      debugPrint("❌ Error resetting app state: $e");
      throw Exception("Failed to reset app state: $e");
    }
  }

  static Future<void> _clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint("✅ Secure storage cleared");
    } catch (e) {
      debugPrint("⚠️ Error clearing secure storage: $e");
      // Fallback: Delete known keys individually
      final knownKeys = [
        'access_token',
        'user_id',
        'user_email',
        'user_name',
        'student_class',
        'photo_url',
        'email',
        'password'
      ];
      for (var key in knownKeys) {
        try {
          await _secureStorage.delete(key: key);
        } catch (e) {
          debugPrint("⚠️ Error deleting key $key: $e");
        }
      }
    }
  }

  static Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint("✅ Shared preferences cleared");
    } catch (e) {
      debugPrint("⚠️ Error clearing shared preferences: $e");
    }
  }

  static Future<void> _clearControllerCaches() async {
    try {
      // Clear HomeController cache
      final homeController = HomeController();
      homeController.clearCache(); // Removed await - this returns void
      debugPrint("✅ HomeController cache cleared");

      // Clear TopicCacheController
      final topicCacheController = TopicCacheController();
      topicCacheController.clearCache(); // This also returns void
      debugPrint("✅ TopicCacheController cleared");

      // If you have CourseDataCache, uncomment and use it
      // final courseDataCache = CourseDataCache();
      // await courseDataCache.clearCache(); // Only use await if it returns Future<void>
      // debugPrint("✅ CourseDataCache cleared");
    } catch (e) {
      debugPrint("⚠️ Error clearing controller caches: $e");
    }
  }

  static void _clearImageCache() {
    try {
      PaintingBinding.instance.imageCache
          .clear(); // Removed await - returns void
      PaintingBinding.instance.imageCache
          .clearLiveImages(); // Removed await - returns void
      debugPrint("✅ Image cache cleared");
    } catch (e) {
      debugPrint("⚠️ Error clearing image cache: $e");
    }
  }

  static Future<void> _clearTemporaryFiles() async {
    try {
      // Clear temp directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
        debugPrint("✅ Temporary directory cleared");
      }

      // Clear cache files from documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final cacheFiles = appDocDir.listSync();
      for (var file in cacheFiles) {
        if (file.path.contains('cache') || file.path.contains('temp')) {
          await file.delete(recursive: true);
        }
      }
      debugPrint("✅ App documents cache cleared");
    } catch (e) {
      debugPrint("⚠️ Error clearing temporary files: $e");
    }
  }
}
