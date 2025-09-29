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

      // CRITICAL FIX 1: Validate token with backend before proceeding
      String? accessToken = await _authService.getAccessToken();
      bool hasValidToken = false;
      
      if (accessToken != null && accessToken.isNotEmpty) {
        // Verify token is still valid by making a test API call
        final userDetails = await _authService.getUserDetails();
        hasValidToken = userDetails != null;
        
        if (!hasValidToken) {
          debugPrint("Token expired or invalid, clearing all auth data");
          await _authService.signOut();
        }
      }
      
      if (!hasValidToken) {
        setState(() {
          isUserLoggedIn = false;
          isAdmin = false;
          isTeacher = false;
          isLoading = false;
        });
        return;
      }

      // Get stored user email - with fallback to backend
      String? userEmail = await _secureStorage.read(key: "user_email");
      
      if (userEmail == null || userEmail.isEmpty) {
        final userDetails = await _authService.getUserDetails();
        if (userDetails != null && userDetails['email'] != null) {
          userEmail = userDetails['email'];
          await _secureStorage.write(key: "user_email", value: userEmail);
        } else {
          debugPrint("Cannot determine user email, signing out");
          await _authService.signOut();
          setState(() {
            isUserLoggedIn = false;
            isAdmin = false;
            isTeacher = false;
            isLoading = false;
          });
          return;
        }
      }

      // CRITICAL FIX 2: Always fetch fresh role lists for current session
      debugPrint("Fetching fresh role lists for user: $userEmail");
      try {
        // Clear existing role lists to force fresh fetch
        AdminRoles.adminEmails.clear();
        TeacherRoles.teacherEmails.clear();
        AdminRoles.lastFetched = null;
        TeacherRoles.lastFetched = null;
        
        await Future.wait([
          AdminRoles.fetchAdminEmails(),
          TeacherRoles.fetchTeacherEmails(),
        ]).timeout(const Duration(seconds: 15));
        
        debugPrint("Role lists fetched - Admins: ${AdminRoles.adminEmails.length}, Teachers: ${TeacherRoles.teacherEmails.length}");
      } catch (e) {
        debugPrint("Warning: Failed to fetch role lists from API: $e");
        // Try loading from cache as fallback
        await _loadRolesFromCache();
      }
      
      // CRITICAL FIX 3: Force fresh role determination
      final roleManager = UserRoleManager();
      // Clear any cached role data
      await roleManager.clearRole();
      // Fetch fresh role for current user
      await roleManager.fetchUserRole(userEmail!);
      
      setState(() {
        isUserLoggedIn = true;
        isAdmin = roleManager.isAdmin;
        isTeacher = roleManager.isTeacher;
        isLoading = false;
      });
      
      debugPrint("Auth initialized - User: $userEmail, Admin: $isAdmin, Teacher: $isTeacher");
      
    } catch (e) {
      debugPrint("Error initializing auth: $e");
      // On any error, clear auth state
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
        AdminRoles.adminEmails = cachedAdmins;
        debugPrint("Loaded ${cachedAdmins.length} admin emails from cache");
      }
      
      if (cachedTeachers != null) {
        TeacherRoles.teacherEmails = cachedTeachers;
        debugPrint("Loaded ${cachedTeachers.length} teacher emails from cache");
      }
    } catch (e) {
      debugPrint("Error loading roles from cache: $e");
    }
  }

  /// CRITICAL FIX 5: Enhanced refresh method with complete cleanup
  Future<void> refreshAuth() async {
    debugPrint("🔄 Refreshing authentication state...");
    
    // Clear all role-related caches
    AdminRoles.adminEmails.clear();
    TeacherRoles.teacherEmails.clear();
    AdminRoles.lastFetched = null;
    TeacherRoles.lastFetched = null;
    
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
      
      // Clear role lists
      AdminRoles.adminEmails.clear();
      TeacherRoles.teacherEmails.clear();
      AdminRoles.lastFetched = null;
      TeacherRoles.lastFetched = null;
      
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