import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api_endpoints.dart';
import '../pages/homepage/controllers/home_controller.dart';
import '../pages/profile/controllers/profile_controller.dart';
import '../pages/topics/controllers/topic_cache_controller.dart' as topic;
import '../pages/courses/models/course_model.dart';

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
      id: json["id"] ?? "",
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

  /// ✅ Send OTP to email for registration
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

  /// ✅ Send OTP to email for password reset
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

  /// ✅ Reset password with OTP verification
  Future<(bool, String?)> resetPasswordWithOTP(String email, String otp, String newPassword) async {
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

  /// ✅ Sign up user via backend with OTP verification & store access token securely
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

        // ✅ Extract and store token securely
        final String accessToken = responseData["access_token"] ?? "";
        if (accessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: accessToken);
        }

        // ✅ Store user details securely
        final String userId = responseData["id"] ?? "";
        final String userName = responseData["name"] ?? "";
        final String userEmail = responseData["email"] ?? "";
        final String userClass = responseData["student_class"] ?? "SELECT";
        final String userPhotoUrl = responseData["photo_url"] ?? "https://www.w3schools.com/w3images/avatar2.png";

        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: userName);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: userClass);
        await _secureStorage.write(key: "photo_url", value: userPhotoUrl);

        // ✅ Create AppUser object
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

  /// ✅ Sign up user via backend WITHOUT OTP (for Google Sign-In)
  Future<(AppUser?, String?)> signUpWithoutOTP(String email, String password, String name,
      String studentClass, String photoUrl) async {
    try {
      // Create user in Firebase Auth first for Google Sign-In
      final firebase_auth.UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebase_auth.User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return (null, "Firebase user creation failed");
      }

      // Now register with backend using Firebase UID
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.signup),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": email,
          "password": password,
          "name": name,
          "student_class": studentClass,
          "photo_url": photoUrl,
          "otp": "GOOGLE_AUTH", // Special OTP for Google users
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // ✅ Extract and store token securely
        final String accessToken = responseData["access_token"] ?? "";
        if (accessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: accessToken);
        }

        // ✅ Store user details securely
        final String userId = responseData["id"] ?? firebaseUser.uid;
        final String userName = responseData["name"] ?? name;
        final String userEmail = responseData["email"] ?? email;
        final String userClass = responseData["student_class"] ?? studentClass;
        final String userPhotoUrl = responseData["photo_url"] ?? photoUrl;

        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: userName);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: userClass);
        await _secureStorage.write(key: "photo_url", value: userPhotoUrl);

        // ✅ Create AppUser object
        AppUser user = AppUser(
          id: userId,
          email: userEmail,
          name: userName,
          studentClass: userClass,
          photoUrl: userPhotoUrl,
        );
        return (user, null);
      } else {
        // Delete Firebase user if backend registration fails
        await firebaseUser.delete();
        final errorData = jsonDecode(response.body);
        return (null, errorData["detail"]?.toString() ?? "Signup failed");
      }
    } catch (e) {
      return (null, "An unexpected error occurred: $e");
    }
  }

  /// ✅ Sign in existing user via backend & store access token
  Future<(AppUser?, String?)> signIn(String email, String password) async {
    try {
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String userId = responseData["id"] ?? "";
        final String accessToken = responseData["access_token"] ?? "";
        final String name = responseData["name"] ?? "Unknown";
        final String userEmail = responseData["email"] ?? "";
        final String studentClass = responseData["student_class"] ?? "SELECT";
        final String photoUrl = responseData["photo_url"] ??
            "https://www.w3schools.com/w3images/avatar2.png";

        // ✅ Store token securely
        if (accessToken.isNotEmpty) {
          await _secureStorage.write(key: "access_token", value: accessToken);
        }

        // ✅ Store user details securely
        await _secureStorage.write(key: "user_id", value: userId);
        await _secureStorage.write(key: "user_name", value: name);
        await _secureStorage.write(key: "user_email", value: userEmail);
        await _secureStorage.write(key: "student_class", value: studentClass);
        await _secureStorage.write(key: "photo_url", value: photoUrl);

        // ✅ Return the AppUser object
        return (
        AppUser(
          id: userId.isNotEmpty ? userId : "N/A",
          name: name,
          email: userEmail,
          studentClass: studentClass,
          photoUrl: photoUrl,
        ),
        null
        );
      } else {
        final errorData = jsonDecode(response.body);
        return (null, errorData["detail"]?.toString() ?? "Login failed");
      }
    } catch (e) {
      return (null, "An unexpected error occurred: $e");
    }
  }

  /// ✅ Google Sign-In (Using Backend WITHOUT OTP)
  Future<(AppUser?, String?)> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return (null, '❌ Google Sign-In canceled');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final firebase_auth.AuthCredential credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await _auth.signInWithCredential(credential);
      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) return (null, '❌ Google authentication failed');

      final String email = firebaseUser.email ?? "";
      final String name = firebaseUser.displayName ?? "Google User";
      final String photoUrl = firebaseUser.photoURL ?? "https://www.w3schools.com/w3images/avatar2.png";

      if (email.isEmpty) {
        return (null, '❌ Google authentication failed: Email not found');
      }

      const String defaultPassword = "GOOGLE_AUTH_ACADEMe";
      const String defaultClass = "SELECT";

      // ✅ Check if user exists in backend
      final bool userExists = await checkIfUserExists(email);

      if (!userExists) {
        // ✅ Register user using backend WITHOUT OTP
        final (_, String? signupError) = await signUpWithoutOTP(email, defaultPassword, name, defaultClass, photoUrl);
        if (signupError != null) return (null, "❌ Signup failed: $signupError");
      }

      // ✅ Log in the user using backend
      final (AppUser? user, String? loginError) = await signIn(email, defaultPassword);
      if (loginError != null) return (null, "❌ Login failed: $loginError");

      return (user, null);
    } catch (e) {
      return (null, "❌ An unexpected error occurred: $e");
    }
  }

  /// ✅ Check if user exists via backend
  Future<bool> checkIfUserExists(String email) async {
    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userExists(email)),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData["exists"] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      debugPrint("🔄 Starting complete logout process...");

      // 1. Sign out from Firebase & Google
      try {
        await _auth.signOut();
        debugPrint("✅ Firebase Auth signed out");
      } catch (e) {
        debugPrint("⚠️ Firebase signout error: $e");
      }

      try {
        await _googleSignIn.signOut();
        debugPrint("✅ Google Sign-In signed out");
      } catch (e) {
        debugPrint("⚠️ Google signout error: $e");
      }

      // 2. Clear home controller cache first
      try {
        final homeController = HomeController();
        homeController.clearCache();
        homeController.clearUserCache();
        debugPrint("✅ HomeController cache cleared");
      } catch (e) {
        debugPrint("⚠️ HomeController clear error: $e");
      }

      // 3. Clear ALL FlutterSecureStorage data
      try {
        await _secureStorage.deleteAll();
        debugPrint("✅ FlutterSecureStorage cleared");
      } catch (e) {
        debugPrint("⚠️ SecureStorage clear error: $e");
        // Try to clear individual known keys if deleteAll fails
        try {
          final allKeys = await _secureStorage.readAll();
          for (String key in allKeys.keys) {
            await _secureStorage.delete(key: key);
          }
          debugPrint("✅ FlutterSecureStorage cleared individually");
        } catch (e2) {
          debugPrint("❌ Failed to clear SecureStorage: $e2");
        }
      }

      // 4. Clear ALL SharedPreferences data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        debugPrint("✅ SharedPreferences cleared");
      } catch (e) {
        debugPrint("⚠️ SharedPreferences clear error: $e");
      }

      // 5. Clear all application caches
      try {
        CourseDataCache().clearCache();
        debugPrint("✅ CourseDataCache cleared");
      } catch (e) {
        debugPrint("⚠️ CourseDataCache clear error: $e");
      }

      try {
        topic.TopicCacheController().clearCache();
        debugPrint("✅ TopicCacheController cleared");
      } catch (e) {
        debugPrint("⚠️ TopicCacheController clear error: $e");
      }

      // 6. Clear ProfileController cache
      try {
        ProfileController.clearCache();
        debugPrint("✅ ProfileController cache cleared");
      } catch (e) {
        debugPrint("⚠️ ProfileController clear error: $e");
      }

      // 7. Clear additional Flutter caches
      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        debugPrint("✅ Image cache cleared");
      } catch (e) {
        debugPrint("⚠️ Image cache clear error: $e");
      }

      // 8. Clear temporary directory cache
      try {
        final tempDir = await getTemporaryDirectory();
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
          debugPrint("✅ Temporary directory cleared");
        }
      } catch (e) {
        debugPrint("⚠️ Temp directory clear error: $e");
      }

      debugPrint("🎉 Complete logout process finished successfully");

    } catch (e) {
      debugPrint("❌ Critical logout error: $e");
      throw Exception("Logout failed: $e");
    }
  }

  /// ✅ Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: "access_token");
  }

  /// ✅ Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    String? token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// ✅ Send password reset email (Firebase method - kept for compatibility)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// ✅ Fetch user details from backend
  Future<Map<String, dynamic>?> getUserDetails() async {
    String? token = await getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await http.get(
        ApiEndpoints.getUri(ApiEndpoints.userDetails),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ Get stored user data from secure storage
  Future<AppUser?> getStoredUser() async {
    try {
      final String? userId = await _secureStorage.read(key: "user_id");
      final String? email = await _secureStorage.read(key: "user_email");
      final String? name = await _secureStorage.read(key: "user_name");
      final String? studentClass = await _secureStorage.read(key: "student_class");
      final String? photoUrl = await _secureStorage.read(key: "photo_url");

      if (userId != null && email != null) {
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
}