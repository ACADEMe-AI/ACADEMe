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
