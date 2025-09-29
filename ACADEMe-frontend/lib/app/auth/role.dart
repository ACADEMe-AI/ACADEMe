import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api_endpoints.dart';

class UserRoleManager {
  static final UserRoleManager _instance = UserRoleManager._internal();
  bool isAdmin = false;
  bool isTeacher = false;
  String userRole = 'student'; // 'student', 'teacher', 'admin'

  factory UserRoleManager() {
    return _instance;
  }

  UserRoleManager._internal();

  /// Fetch user role and update both memory and storage
  Future<void> fetchUserRole(String userEmail) async {
    try {
      debugPrint("Fetching role for user: $userEmail");
      
      // Check roles
      isAdmin = AdminRoles.isAdmin(userEmail);
      isTeacher = TeacherRoles.isTeacher(userEmail);

      if (isAdmin) {
        userRole = 'admin';
      } else if (isTeacher) {
        userRole = 'teacher';
      } else {
        userRole = 'student';
      }

      debugPrint("Role determined - Admin: $isAdmin, Teacher: $isTeacher, Role: $userRole");

      // Store in both SharedPreferences and SecureStorage
      await _saveRoleToStorage();
      
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      await loadRole(); // Fallback to stored role
    }
  }

  /// Save role information to both storage systems
  Future<void> _saveRoleToStorage() async {
    try {
      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isAdmin', isAdmin);
      await prefs.setBool('isTeacher', isTeacher);
      await prefs.setString('userRole', userRole);

      // Also save to SecureStorage as backup
      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: 'user_role', value: userRole);
      await secureStorage.write(key: 'is_admin', value: isAdmin.toString());
      await secureStorage.write(key: 'is_teacher', value: isTeacher.toString());
      
      debugPrint("Role saved to storage successfully");
    } catch (e) {
      debugPrint("Error saving role to storage: $e");
    }
  }

  /// Load role from storage
  Future<void> loadRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      isAdmin = prefs.getBool('isAdmin') ?? false;
      isTeacher = prefs.getBool('isTeacher') ?? false;
      userRole = prefs.getString('userRole') ?? 'student';
      
      debugPrint("Role loaded from storage - Admin: $isAdmin, Teacher: $isTeacher, Role: $userRole");
    } catch (e) {
      debugPrint("Error loading role from storage: $e");
      // Reset to defaults
      isAdmin = false;
      isTeacher = false;
      userRole = 'student';
    }
  }

  /// Clear role data
  Future<void> clearRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isAdmin');
      await prefs.remove('isTeacher');
      await prefs.remove('userRole');

      const FlutterSecureStorage secureStorage = FlutterSecureStorage();
      await secureStorage.delete(key: 'user_role');
      await secureStorage.delete(key: 'is_admin');
      await secureStorage.delete(key: 'is_teacher');

      isAdmin = false;
      isTeacher = false;
      userRole = 'student';
      
      debugPrint("Role data cleared");
    } catch (e) {
      debugPrint("Error clearing role data: $e");
    }
  }
}

class AdminRoles {
  static List<String> adminEmails = [];
  static DateTime? lastFetched;
  static const Duration cacheValidityDuration = Duration(hours: 1);

  /// Fetches admin emails from the API and updates the list.
  static Future<void> fetchAdminEmails() async {
    try {
      // Check if cache is still valid
      if (lastFetched != null && 
          DateTime.now().difference(lastFetched!).compareTo(cacheValidityDuration) < 0 &&
          adminEmails.isNotEmpty) {
        debugPrint("Using cached admin emails (${adminEmails.length} emails)");
        return;
      }

      debugPrint("Fetching admin emails from API...");
      
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.adminEmails),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        
        if (responseBody is List) {
          adminEmails = List<String>.from(responseBody.map((e) => e.toString().toLowerCase().trim()));
        } else if (responseBody is Map) {
          // Handle multiple possible response formats
          if (responseBody.containsKey('emails')) {
            adminEmails = List<String>.from(responseBody['emails'].map((e) => e.toString().toLowerCase().trim()));
          } else if (responseBody.containsKey('admin_emails')) {
            adminEmails = List<String>.from(responseBody['admin_emails'].map((e) => e.toString().toLowerCase().trim()));
          } else {
            throw Exception("Unexpected response format for admin emails. Expected 'emails' or 'admin_emails' key.");
          }
        } else {
          throw Exception("Unexpected response format for admin emails");
        }
        
        lastFetched = DateTime.now();
        debugPrint("Successfully fetched ${adminEmails.length} admin emails");
      } else {
        throw Exception("Failed to load admin emails. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching admin emails: $e");
      // Keep existing cache if available
      if (adminEmails.isEmpty) {
        // Load from SharedPreferences as fallback
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String>? cached = prefs.getStringList('cached_admin_emails');
          if (cached != null) {
            adminEmails = cached;
            debugPrint("Loaded ${adminEmails.length} admin emails from cache");
          }
        } catch (cacheError) {
          debugPrint("Error loading admin emails from cache: $cacheError");
        }
      }
    }
  }

  /// Checks if the given email is an admin.
  static bool isAdmin(String email) {
    String normalizedEmail = email.toLowerCase().trim();
    bool result = adminEmails.contains(normalizedEmail);
    debugPrint("Checking if $normalizedEmail is admin: $result");
    return result;
  }

  /// Save admin emails to cache
  static Future<void> _saveToCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_admin_emails', adminEmails);
    } catch (e) {
      debugPrint("Error saving admin emails to cache: $e");
    }
  }
}

class TeacherRoles {
  static List<String> teacherEmails = [];
  static DateTime? lastFetched;
  static const Duration cacheValidityDuration = Duration(hours: 1);

  /// Fetches teacher emails from the API and updates the list.
  static Future<void> fetchTeacherEmails() async {
    try {
      // Check if cache is still valid
      if (lastFetched != null && 
          DateTime.now().difference(lastFetched!).compareTo(cacheValidityDuration) < 0 &&
          teacherEmails.isNotEmpty) {
        debugPrint("Using cached teacher emails (${teacherEmails.length} emails)");
        return;
      }

      debugPrint("Fetching teacher emails from API...");
      
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherEmails),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic responseBody = json.decode(response.body);
        
        if (responseBody is List) {
          teacherEmails = List<String>.from(responseBody.map((e) => e.toString().toLowerCase().trim()));
        } else if (responseBody is Map) {
          // Handle multiple possible response formats
          if (responseBody.containsKey('emails')) {
            teacherEmails = List<String>.from(responseBody['emails'].map((e) => e.toString().toLowerCase().trim()));
          } else if (responseBody.containsKey('teacher_emails')) {
            teacherEmails = List<String>.from(responseBody['teacher_emails'].map((e) => e.toString().toLowerCase().trim()));
          } else {
            throw Exception("Unexpected response format for teacher emails. Expected 'emails' or 'teacher_emails' key.");
          }
        } else {
          throw Exception("Unexpected response format for teacher emails");
        }
        
        lastFetched = DateTime.now();
        debugPrint("Successfully fetched ${teacherEmails.length} teacher emails");
        await _saveToCache();
      } else {
        throw Exception("Failed to load teacher emails. Status: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching teacher emails: $e");
      // Keep existing cache if available
      if (teacherEmails.isEmpty) {
        // Load from SharedPreferences as fallback
        try {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          List<String>? cached = prefs.getStringList('cached_teacher_emails');
          if (cached != null) {
            teacherEmails = cached;
            debugPrint("Loaded ${teacherEmails.length} teacher emails from cache");
          }
        } catch (cacheError) {
          debugPrint("Error loading teacher emails from cache: $cacheError");
        }
      }
    }
  }

  /// Checks if the given email is a teacher.
  static bool isTeacher(String email) {
    String normalizedEmail = email.toLowerCase().trim();
    bool result = teacherEmails.contains(normalizedEmail);
    debugPrint("Checking if $normalizedEmail is teacher: $result");
    return result;
  }

  /// Save teacher emails to cache
  static Future<void> _saveToCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('cached_teacher_emails', teacherEmails);
    } catch (e) {
      debugPrint("Error saving teacher emails to cache: $e");
    }
  }
}