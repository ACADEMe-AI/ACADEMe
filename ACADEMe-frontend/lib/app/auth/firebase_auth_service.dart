// firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../api_endpoints.dart';

class FirebaseAuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Get Firebase custom token from backend
  Future<String?> getFirebaseCustomToken() async {
    try {
      debugPrint("🔄 Starting Firebase custom token request...");

      // Get credentials from secure storage
      String? userId = await _secureStorage.read(key: "user_id");
      String? accessToken = await _secureStorage.read(key: "access_token");

      // Validate credentials
      if (userId == null || userId.isEmpty) {
        debugPrint("❌ No user ID found in storage");
        return null;
      }

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint("❌ No access token found");
        return null;
      }

      debugPrint("✅ Requesting Firebase token for user: $userId");

      // Request custom token from backend
      final response = await http.post(
        ApiEndpoints.getUri(ApiEndpoints.firebaseToken),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({"user_id": userId}),
      ).timeout(const Duration(seconds: 30));

      debugPrint("📡 Backend response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final customToken = responseData['token'] as String?;
        
        if (customToken != null && customToken.isNotEmpty) {
          debugPrint("✅ Firebase custom token received successfully");
          return customToken;
        } else {
          debugPrint("❌ Empty token received in response");
          return null;
        }
      } else {
        debugPrint("❌ Failed to get Firebase custom token: ${response.statusCode}");
        debugPrint("Response body: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error getting Firebase custom token: $e");
      return null;
    }
  }

  /// Authenticate with Firebase using custom token with retry logic
  Future<bool> authenticateWithFirebase({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint("🔄 Firebase auth attempt $attempt/$maxRetries");

        // Check if already authenticated
        final currentUser = _firebaseAuth.currentUser;
        if (currentUser != null) {
          debugPrint("✅ Already authenticated with Firebase: ${currentUser.uid}");
          
          // Verify the UID matches stored user_id
          final storedUserId = await _secureStorage.read(key: "user_id");
          if (currentUser.uid == storedUserId) {
            return true;
          } else {
            debugPrint("⚠️ Firebase UID mismatch, re-authenticating...");
            await signOutFromFirebase();
          }
        }

        // Get custom token from backend
        final customToken = await getFirebaseCustomToken();
        if (customToken == null) {
          debugPrint("❌ No custom token received on attempt $attempt");
          if (attempt == maxRetries) {
            debugPrint("❌ All authentication attempts failed");
            return false;
          }
          await Future.delayed(Duration(seconds: attempt * 2));
          continue;
        }

        debugPrint("✅ Attempting to sign in with custom token...");

        // Sign in with custom token
        final userCredential = await _firebaseAuth.signInWithCustomToken(customToken);
        
        if (userCredential.user != null) {
          final firebaseUid = userCredential.user!.uid;
          debugPrint("✅ Successfully authenticated with Firebase: $firebaseUid");
          
          // Store Firebase UID for future reference
          await _secureStorage.write(key: "firebase_uid", value: firebaseUid);
          
          // Verify it matches backend user_id
          final storedUserId = await _secureStorage.read(key: "user_id");
          if (firebaseUid != storedUserId) {
            debugPrint("⚠️ Warning: Firebase UID ($firebaseUid) doesn't match stored user_id ($storedUserId)");
          }
          
          return true;
        } else {
          debugPrint("❌ Firebase authentication failed - no user returned on attempt $attempt");
          if (attempt == maxRetries) return false;
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } on firebase_auth.FirebaseAuthException catch (e) {
        debugPrint("❌ Firebase auth exception on attempt $attempt: ${e.code} - ${e.message}");
        if (attempt == maxRetries) return false;
        await Future.delayed(Duration(seconds: attempt * 2));
      } catch (e) {
        debugPrint("❌ General Firebase authentication error on attempt $attempt: $e");
        if (attempt == maxRetries) return false;
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    return false;
  }

  /// Get current Firebase user
  firebase_auth.User? getCurrentFirebaseUser() {
    return _firebaseAuth.currentUser;
  }

  /// Check if user is authenticated with Firebase
  bool isFirebaseAuthenticated() {
    return _firebaseAuth.currentUser != null;
  }

  /// Sign out from Firebase
  Future<void> signOutFromFirebase() async {
    try {
      await _firebaseAuth.signOut();
      await _secureStorage.delete(key: "firebase_uid");
      debugPrint("✅ Signed out from Firebase");
    } catch (e) {
      debugPrint("❌ Error signing out from Firebase: $e");
    }
  }

  /// Listen to Firebase auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Force refresh Firebase token
  Future<bool> refreshFirebaseAuth() async {
    try {
      debugPrint("🔄 Refreshing Firebase authentication...");
      await signOutFromFirebase();
      return await authenticateWithFirebase();
    } catch (e) {
      debugPrint("❌ Error refreshing Firebase auth: $e");
      return false;
    }
  }

  /// Get Firebase ID Token (for additional security if needed)
  Future<String?> getFirebaseIdToken() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        debugPrint("✅ Firebase ID token retrieved");
        return token;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error getting Firebase ID token: $e");
      return null;
    }
  }

  /// Debug method to check storage contents
  Future<void> debugStorageContents() async {
    try {
      debugPrint("🔍 === STORAGE DEBUG INFO ===");
      final keys = ['user_id', 'access_token', 'user_email', 'firebase_uid'];
      for (String key in keys) {
        final value = await _secureStorage.read(key: key);
        debugPrint("🔍 $key: '${value ?? 'NULL'}'");
      }
      debugPrint("🔍 Firebase Current User: ${_firebaseAuth.currentUser?.uid ?? 'NULL'}");
      debugPrint("🔍 === END STORAGE DEBUG ===");
    } catch (e) {
      debugPrint("❌ Error debugging storage: $e");
    }
  }
}