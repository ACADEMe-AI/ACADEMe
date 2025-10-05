import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ACADEMe/localization/language_provider.dart';
import 'package:provider/provider.dart';

class ProfileController {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> loadUserDetails() async {
    try {
      // Read from SharedPreferences for class (immediate updates)
      final prefs = await SharedPreferences.getInstance();
      final studentClass = prefs.getString('student_class');

      // Read other data from secure storage
      final name = await _secureStorage.read(key: 'name');
      final email = await _secureStorage.read(key: 'email');
      final photoUrl = await _secureStorage.read(key: 'photo_url');

      return {
        'name': name,
        'email': email,
        'student_class': studentClass,
        'photo_url': photoUrl,
      };
    } catch (e) {
      throw Exception('Failed to load user details: $e');
    }
  }

  Future<void> changeLanguage(Locale locale, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);

    if (!context.mounted) return;
    Provider.of<LanguageProvider>(context, listen: false).setLocale(locale);
  }

  Future<Locale> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('language') ?? 'en';
    return Locale(langCode);
  }

  // Add method to clear cache
  static void clearCache() {
    // This will be called during logout
  }
}
