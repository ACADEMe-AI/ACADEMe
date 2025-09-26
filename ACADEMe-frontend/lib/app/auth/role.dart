import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<void> fetchUserRole(String userEmail) async {
    isAdmin = AdminRoles.isAdmin(userEmail);
    isTeacher = TeacherRoles.isTeacher(userEmail);

    if (isAdmin) {
      userRole = 'admin';
    } else if (isTeacher) {
      userRole = 'teacher';
    } else {
      userRole = 'student';
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', isAdmin);
    await prefs.setBool('isTeacher', isTeacher);
    await prefs.setString('userRole', userRole);
  }

  Future<void> loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool('isAdmin') ?? false;
    isTeacher = prefs.getBool('isTeacher') ?? false;
    userRole = prefs.getString('userRole') ?? 'student';
  }
}

class AdminRoles {
  static List<String> adminEmails = [];

  /// Fetches admin emails from the API and updates the list.
  static Future<void> fetchAdminEmails() async {
    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.adminEmails),
      );

      if (response.statusCode == 200) {
        List<dynamic> emails = json.decode(response.body);
        adminEmails = List<String>.from(emails);
      } else {
        throw Exception("Failed to load admin emails");
      }
    } catch (e) {
      debugPrint("Error fetching admin emails: $e");
    }
  }

  /// Checks if the given email is an admin.
  static bool isAdmin(String email) {
    return adminEmails.contains(email.trim());
  }
}

class TeacherRoles {
  static List<String> teacherEmails = [];

  /// Fetches teacher emails from the API and updates the list.
  static Future<void> fetchTeacherEmails() async {
    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.teacherEmails),
      );

      if (response.statusCode == 200) {
        List<dynamic> emails = json.decode(response.body);
        teacherEmails = List<String>.from(emails);
      } else {
        throw Exception("Failed to load teacher emails");
      }
    } catch (e) {
      debugPrint("Error fetching teacher emails: $e");
    }
  }

  /// Checks if the given email is a teacher.
  static bool isTeacher(String email) {
    return teacherEmails.contains(email.trim());
  }
}
