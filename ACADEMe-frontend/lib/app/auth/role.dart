import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_endpoints.dart';

class UserRoleManager {
  static final UserRoleManager _instance = UserRoleManager._internal();
  bool isAdmin = false;

  factory UserRoleManager() {
    return _instance;
  }

  UserRoleManager._internal();

  Future<void> fetchUserRole(String userEmail) async {
    isAdmin = AdminRoles.isAdmin(userEmail);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAdmin', isAdmin);
  }

  Future<void> loadRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isAdmin = prefs.getBool('isAdmin') ?? false;
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
