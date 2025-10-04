import 'package:ACADEMe/app/auth/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/introduction_page.dart';
import '../pages/bottom_nav/bottom_nav.dart';
import '../auth/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();
  bool? isUserLoggedIn;
  bool isAdmin = false;
  bool isTeacher = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// 🔹 Comprehensive authentication and role initialization
  Future<void> _initializeAuth() async {
    try {
      setState(() => isLoading = true);

      // Check if we have a valid token
      String? accessToken = await _authService.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // No token, user not logged in
        setState(() {
          isUserLoggedIn = false;
          isAdmin = false;
          isTeacher = false;
          isLoading = false;
        });
        return;
      }

      // Validate token (will auto-refresh if expired)
      bool hasValidToken = await _authService.isTokenValid();

      if (!hasValidToken) {
        debugPrint("Token validation failed, clearing auth");
        await _authService.signOut();
        setState(() {
          isUserLoggedIn = false;
          isAdmin = false;
          isTeacher = false;
          isLoading = false;
        });
        return;
      }

      // Get user details from backend (includes role)
      final userDetails = await _authService.getUserDetails();

      if (userDetails == null) {
        debugPrint("Cannot get user details, signing out");
        await _authService.signOut();
        setState(() {
          isUserLoggedIn = false;
          isAdmin = false;
          isTeacher = false;
          isLoading = false;
        });
        return;
      }

      // Get role from backend response
      final String role = userDetails['role'] ?? 'student';
      debugPrint("User role from backend: $role");

      // Store role locally
      await _secureStorage.write(key: "user_role", value: role);

      setState(() {
        isUserLoggedIn = true;
        isAdmin = (role == 'admin');
        isTeacher = (role == 'teacher');
        isLoading = false;
      });

      debugPrint("Auth initialized - Role: $role, Admin: $isAdmin, Teacher: $isTeacher");

    } catch (e) {
      debugPrint("Error initializing auth: $e");
      await _authService.signOut();
      setState(() {
        isUserLoggedIn = false;
        isAdmin = false;
        isTeacher = false;
        isLoading = false;
      });
    }
  }

  /// CRITICAL FIX 4: Fallback method to load roles from cache
  Future<void> _loadRolesFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? cachedAdmins = prefs.getStringList('cached_admin_emails');
      List<String>? cachedTeachers = prefs.getStringList('cached_teacher_emails');
      
      if (cachedAdmins != null) {
        debugPrint("Loaded ${cachedAdmins.length} admin emails from cache");
      }
      
      if (cachedTeachers != null) {
        debugPrint("Loaded ${cachedTeachers.length} teacher emails from cache");
      }
    } catch (e) {
      debugPrint("Error loading roles from cache: $e");
    }
  }

  /// CRITICAL FIX 5: Enhanced refresh method with complete cleanup
  Future<void> refreshAuth() async {
    debugPrint("🔄 Refreshing authentication state...");

    // Clear role manager cache
    final roleManager = UserRoleManager();
    await roleManager.clearRole();
    
    // Reinitialize everything
    await _initializeAuth();
  }

  /// CRITICAL FIX 6: Method to handle complete logout
  Future<void> performCompleteLogout() async {
    debugPrint("🚪 Performing complete logout...");
    setState(() => isLoading = true);
    
    try {
      // Clear all authentication and role data
      await _authService.signOut();
      
      // Clear role manager
      final roleManager = UserRoleManager();
      await roleManager.clearRole();

      setState(() {
        isUserLoggedIn = false;
        isAdmin = false;
        isTeacher = false;
        isLoading = false;
      });
      
      debugPrint("✅ Complete logout successful");
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
      // Force reset state even if logout fails
      setState(() {
        isUserLoggedIn = false;
        isAdmin = false;
        isTeacher = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return isUserLoggedIn == true
        ? BottomNav(
            isAdmin: isAdmin, 
            isTeacher: isTeacher,
          )
        : const AcademeScreen();
  }
}