// auth_service.dart
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_endpoints.dart';
import '../pages/homepage/controllers/home_controller.dart';
import '../pages/profile/controllers/profile_controller.dart';
import '../pages/topics/controllers/topic_cache_controller.dart' as topic;
import '../pages/courses/models/course_model.dart';
import './role.dart';
import './firebase_auth_service.dart';

class AppUser {
  final String id;
  final String email;
  final String name;
  final String studentClass;
  final String photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.studentClass,
    required this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json["id"]?.toString() ?? "",
      email: json["email"] ?? "",
      name: json["name"] ?? "",
      studentClass: json["student_class"] ?? "SELECT",
      photoUrl: json["photo_url"] ?? "https://www.w3schools.com/w3images/avatar2.png",
    );
  }
}

class AuthService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  String? _refreshToken;

  /// Send OTP to email for registration
  Future<(bool, String?)> sendOTP(String email) async {
    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.sendOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return (true, responseData["message"]?.toString() ?? "OTP sent successfully");
      } else {
        final errorData = jsonDecode(response.body);
        return (false, errorData["detail"]?.toString() ?? "Failed to send OTP");
      }
    } catch (e) {
      return (false, "An unexpected error occurred: $e");
    }
  }

  /// Send OTP to email for password reset
  Future<(bool, String?)> sendForgotPasswordOTP(String email) async {
    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.sendForgotPasswordOtp),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return (true, responseData["message"]?.toString() ?? "Reset OTP sent successfully");
      } else {
        final errorData = jsonDecode(response.body);
        return (false, errorData["detail"]?.toString() ?? "Failed to send reset OTP");
      }
    } catch (e) {
      return (false, "An unexpected error occurred: $e");
    }
  }

  Future<bool> isTokenValid() async {
    try {
      String? token = await getAccessToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userDetails),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Try refreshing token
        debugPrint("Access token invalid, attempting refresh");
        return await refreshAccessToken();
      }

      return false;
    } catch (e) {
      debugPrint("Token validation failed: $e");
      // Try refreshing on error
      return await refreshAccessToken();
    }
  }

  /// Reset password with OTP verification
  Future<(bool, String?)> resetPasswordWithOTP(
      String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.resetPassword),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "new_password": newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return (true, responseData["message"]?.toString() ?? "Password reset successfully");
      } else {
        final errorData = jsonDecode(response.body);
        return (false, errorData["detail"]?.toString() ?? "Failed to reset password");
      }
    } catch (e) {
      return (false, "An unexpected error occurred: $e");
    }
  }

  /// Sign up user via backend with OTP verification
  Future<(AppUser?, String?)> signUp(String email, String password, String name,
      String studentClass, String photoUrl, String otp) async {
    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.signup),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "student_class": studentClass,
          "photo_url": photoUrl,
          "otp": otp,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String accessToken = responseData["access_token"] ?? "";
        final String refreshToken = responseData["refresh_token"] ?? "";  // NEW
        final String userId = responseData["id"]?.toString() ?? "";
        final String userName = responseData["name"] ?? "";
        final String userEmail = responseData["email"] ?? "";
        final String userClass = responseData["student_class"] ?? "SELECT";
        final String userPhotoUrl = responseData["photo_url"] ?? "https://www.w3schools.com/w3images/avatar2.png";
        final String role = responseData["role"] ?? "student";  // NEW

        if (userId.isEmpty) {
          return (null, "Invalid user ID received from server");
        }

        // Store tokens
        await _secureStorage.write(key: "access_token", value: accessToken);
        if (refreshToken.isNotEmpty) {
          await _secureStorage.write(key: "refresh_token", value: refreshToken);
        }

        // Store user details
        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: userName);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: userClass);
        await _secureStorage.write(key: "photo_url", value: userPhotoUrl);
        await _secureStorage.write(key: "user_role", value: role);  // NEW

        debugPrint("User credentials stored - User ID: $userId, Role: $role");

        AppUser user = AppUser.fromJson(responseData);
        return (user, null);
      } else {
        final errorData = jsonDecode(response.body);
        return (null, errorData["detail"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      return (null, "An unexpected error occurred: $e");
    }
  }

  /// Sign in existing user via backend & store access token
  Future<(AppUser?, String?)> signIn(String email, String password) async {
    try {
      debugPrint("Starting sign-in process for: $email");

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      ).timeout(const Duration(seconds: 30));

      debugPrint("Login response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String accessToken = responseData["access_token"] ?? "";
        final String refreshToken = responseData["refresh_token"] ?? "";  // NEW
        final String userId = responseData["id"]?.toString() ?? "";
        final String name = responseData["name"] ?? "Unknown";
        final String userEmail = responseData["email"] ?? "";
        final String studentClass = responseData["student_class"] ?? "SELECT";
        final String photoUrl = responseData["photo_url"] ?? "https://www.w3schools.com/w3images/avatar2.png";
        final String role = responseData["role"] ?? "student";  // NEW

        if (userId.isEmpty) {
          debugPrint("Empty user ID received from backend");
          return (null, "Invalid user ID received from server");
        }

        debugPrint("User ID from backend: $userId");

        // Store tokens
        if (accessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: accessToken);
          debugPrint("Access token stored");
        } else {
          debugPrint("Empty access token received");
          return (null, "No access token received from server");
        }

        // Store refresh token - NEW
        if (refreshToken.isNotEmpty) {
          await _secureStorage.write(key: "refresh_token", value: refreshToken);
          _refreshToken = refreshToken;
          debugPrint("Refresh token stored");
        }

        // Store user details
        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: name);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: studentClass);
        await _secureStorage.write(key: "photo_url", value: photoUrl);
        await _secureStorage.write(key: "user_role", value: role);  // NEW

        debugPrint("User credentials stored successfully - User ID: $userId, Role: $role");

        // Authenticate with Firebase
        debugPrint("Starting Firebase authentication...");
        final bool firebaseAuthSuccess = await _firebaseAuthService.authenticateWithFirebase();

        if (firebaseAuthSuccess) {
          debugPrint("Firebase authentication successful");
        } else {
          debugPrint("Firebase authentication failed, but user is logged in to backend");
        }

        await _firebaseAuthService.debugStorageContents();

        return (
        AppUser(
          id: userId,
          name: name,
          email: userEmail,
          studentClass: studentClass,
          photoUrl: photoUrl,
        ),
        null
        );
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData["detail"]?.toString() ?? "Login failed";
        debugPrint("Login failed: $errorMessage");
        return (null, errorMessage);
      }
    } catch (e) {
      debugPrint("Sign-in error: $e");
      return (null, "An unexpected error occurred: $e");
    }
  }

// NEW: Add refresh token method
  Future<bool> refreshAccessToken() async {
    try {
      String? refreshToken = await _secureStorage.read(key: "refresh_token");

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint("No refresh token available");
        return false;
      }

      debugPrint("Refreshing access token...");

      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.refreshToken),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"refresh_token": refreshToken}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String newAccessToken = responseData["access_token"] ?? "";
        final String role = responseData["role"] ?? "student";

        if (newAccessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: newAccessToken);
          await _secureStorage.write(key: "user_role", value: role);
          debugPrint("Access token refreshed successfully");
          return true;
        }
      } else if (response.statusCode == 401) {
        debugPrint("Refresh token expired, clearing auth");
        await signOut();
        return false;
      }

      return false;
    } catch (e) {
      debugPrint("Error refreshing token: $e");
      return false;
    }
  }



  Future<(AppUser?, String?)> signInWithGoogle() async {
    try {
      print('Starting Google Sign-In process...');

      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('User canceled Google Sign-In');
        return (null, 'Google Sign-In was canceled');
      }

      print('Google user signed in: ${googleUser.email}');

      final String email = googleUser.email;
      final String name = googleUser.displayName ?? "Google User";
      final String photoUrl = googleUser.photoUrl ?? "https://www.w3schools.com/w3images/avatar2.png";

      if (email.isEmpty) {
        return (null, 'Google authentication failed: Email not found');
      }

      debugPrint("Google Sign-In: Authenticating $email with backend");

      final requestBody = {
        "email": email,
        "name": name,
        "photo_url": photoUrl,
      };

      final uri = ApiEndpoints.getUri(ApiEndpoints.googleSignin);

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String userId = responseData["id"]?.toString() ?? "";
        final String accessToken = responseData["access_token"] ?? "";
        final String refreshToken = responseData["refresh_token"] ?? "";  // NEW
        final String userName = responseData["name"] ?? name;
        final String userEmail = responseData["email"] ?? email;
        final String studentClass = responseData["student_class"] ?? "SELECT";
        final String userPhotoUrl = responseData["photo_url"] ?? photoUrl;
        final String role = responseData["role"] ?? "student";  // NEW

        String finalUserId = userId;
        if (finalUserId.isEmpty && accessToken.isNotEmpty) {
          try {
            final parts = accessToken.split('.');
            if (parts.length == 3) {
              final payload = parts[1];
              final normalized = base64Url.normalize(payload);
              final decoded = utf8.decode(base64Url.decode(normalized));
              final payloadMap = jsonDecode(decoded);
              finalUserId = payloadMap["id"]?.toString() ?? "";
            }
          } catch (e) {
            print('Error decoding JWT: $e');
          }
        }

        if (finalUserId.isEmpty) {
          debugPrint("Empty user ID received from backend");
          return (null, "Invalid user ID received from server");
        }

        // Store tokens
        if (accessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: accessToken);
          debugPrint("Access token stored");
        } else {
          debugPrint("Empty access token received");
          return (null, "No access token received from server");
        }

        if (refreshToken.isNotEmpty) {
          await _secureStorage.write(key: "refresh_token", value: refreshToken);
          debugPrint("Refresh token stored");
        }

        // Store user details
        await _secureStorage.write(key: "user_id", value: finalUserId);
        await _secureStorage.write(key: "user_name", value: userName);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: studentClass);
        await _secureStorage.write(key: "photo_url", value: userPhotoUrl);
        await _secureStorage.write(key: "user_role", value: role);  // NEW

        debugPrint("Google user credentials stored - User ID: $finalUserId, Role: $role");

        debugPrint("Starting Firebase authentication...");
        final bool firebaseAuthSuccess = await _firebaseAuthService.authenticateWithFirebase();

        if (firebaseAuthSuccess) {
          debugPrint("Firebase authentication successful");
        } else {
          debugPrint("Firebase authentication failed, but user is logged in to backend");
        }

        return (
        AppUser(
          id: finalUserId,
          name: userName,
          email: userEmail,
          studentClass: studentClass,
          photoUrl: userPhotoUrl,
        ),
        null
        );
      } else if (response.statusCode == 404) {
        return (null, 'Google Sign-In endpoint not found. Please contact support.');
      } else if (response.statusCode >= 500) {
        return (null, 'Server error occurred. Please try again later.');
      } else {
        final errorData = jsonDecode(response.body);
        String errorMessage = errorData["detail"]?.toString() ?? "Google Sign-In failed";
        return (null, errorMessage);
      }
    } on TimeoutException {
      print('Request timed out');
      return (null, 'Request timed out. Please check your internet connection.');
    } on SocketException {
      print('No internet connection');
      return (null, 'No internet connection. Please check your network settings.');
    } on HttpException {
      print('HTTP error occurred');
      return (null, 'Network error occurred. Please try again.');
    } on FormatException {
      print('Invalid response format');
      return (null, 'Invalid response from server. Please try again.');
    } catch (e) {
      debugPrint("Google Sign-In error: $e");
      print('Unexpected error: $e');
      return (null, 'An unexpected error occurred: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint("Starting complete logout process...");

      // Get refresh token before clearing
      String? refreshToken = await _secureStorage.read(key: "refresh_token");
      String? accessToken = await getAccessToken();

      // Call backend logout endpoint
      if (refreshToken != null && accessToken != null) {
        try {
          await http.post(
            ApiEndpoints.getUri(ApiEndpoints.logout),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $accessToken',
            },
            body: jsonEncode({"refresh_token": refreshToken}),
          ).timeout(const Duration(seconds: 5));
          debugPrint("Backend logout successful");
        } catch (e) {
          debugPrint("Backend logout error: $e");
        }
      }

      // Sign out from Firebase & Google
      try {
        await _auth.signOut();
        debugPrint("Firebase Auth signed out");
      } catch (e) {
        debugPrint("Firebase signout error: $e");
      }

      try {
        await _googleSignIn.signOut();
        debugPrint("Google Sign-In signed out");
      } catch (e) {
        debugPrint("Google signout error: $e");
      }

      // Clear role data (keep if you still need UserRoleManager)
      try {
        final roleManager = UserRoleManager();
        await roleManager.clearRole();
        AdminRoles.adminEmails.clear();
        TeacherRoles.teacherEmails.clear();
        AdminRoles.lastFetched = null;
        TeacherRoles.lastFetched = null;
        debugPrint("User roles cleared");
      } catch (e) {
        debugPrint("Role clear error: $e");
      }

      // Clear FlutterSecureStorage
      try {
        await _secureStorage.deleteAll();
        debugPrint("FlutterSecureStorage cleared");
      } catch (e) {
        debugPrint("SecureStorage deleteAll error: $e");
      }

      // Clear SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        final authKeys = [
          'isAdmin', 'isTeacher', 'userRole', 'cached_admin_emails',
          'cached_teacher_emails', 'user_role', 'is_admin', 'is_teacher'
        ];
        for (String key in authKeys) {
          await prefs.remove(key);
        }
        debugPrint("SharedPreferences cleared");
      } catch (e) {
        debugPrint("SharedPreferences clear error: $e");
      }

      // Clear application caches
      try {
        final homeController = HomeController();
        homeController.clearCache();
        homeController.clearUserCache();
        CourseDataCache().clearCache();
        topic.TopicCacheController().clearCache();
        ProfileController.clearCache();
        debugPrint("Application caches cleared");
      } catch (e) {
        debugPrint("Cache clear error: $e");
      }

      debugPrint("Complete logout process finished");
    } catch (e) {
      debugPrint("Critical logout error: $e");
      try {
        await _secureStorage.deleteAll();
      } catch (e2) {
        debugPrint("Final cleanup failed: $e2");
      }
      throw Exception("Logout failed: $e");
    }
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: "access_token");
  }

  /// Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    try {
      String? token = await getAccessToken();
      if (token == null || token.isEmpty) {
        debugPrint("No access token found");
        return false;
      }

      bool isValid = await isTokenValid();
      if (!isValid) {
        debugPrint("Token is invalid or expired, clearing auth data");
        await signOut();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint("Error checking login status: $e");
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch user details from backend
  Future<Map<String, dynamic>?> getUserDetails() async {
    String? token = await getAccessToken();
    if (token == null || token.isEmpty) {
      debugPrint("No access token available for getUserDetails");
      return null;
    }

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userDetails),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        debugPrint("Token expired (401), clearing auth data");
        await signOut();
        return null;
      } else {
        debugPrint("getUserDetails failed with status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error in getUserDetails: $e");
      return null;
    }
  }

  /// Get stored user data from secure storage
  Future<AppUser?> getStoredUser() async {
    try {
      final String? userId = await _secureStorage.read(key: "user_id");
      final String? email = await _secureStorage.read(key: "user_email");
      final String? name = await _secureStorage.read(key: "user_name");
      final String? studentClass = await _secureStorage.read(key: "student_class");
      final String? photoUrl = await _secureStorage.read(key: "photo_url");

      if (userId != null && userId.isNotEmpty && email != null) {
        return AppUser(
          id: userId,
          email: email,
          name: name ?? "Unknown",
          studentClass: studentClass ?? "SELECT",
          photoUrl: photoUrl ?? "https://www.w3schools.com/w3images/avatar2.png",
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Debug method to check storage state
  Future<void> debugAuthState() async {
    try {
      debugPrint("=== AUTH STATE DEBUG ===");
      final String? userId = await _secureStorage.read(key: "user_id");
      final String? token = await _secureStorage.read(key: "access_token");
      final String? email = await _secureStorage.read(key: "user_email");

      debugPrint("User ID: '${userId ?? 'NULL'}'");
      debugPrint("Access Token: '${token != null ? 'EXISTS' : 'NULL'}'");
      debugPrint("Email: '${email ?? 'NULL'}'");
      debugPrint("Firebase User: ${_auth.currentUser?.uid ?? 'NULL'}");
      debugPrint("=== END AUTH DEBUG ===");
    } catch (e) {
      debugPrint("Error debugging auth state: $e");
    }
  }
}
