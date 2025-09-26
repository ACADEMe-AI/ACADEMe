import 'package:ACADEMe/app/auth/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ACADEMe/introduction_page.dart';
import '../pages/bottom_nav/bottom_nav.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool? isUserLoggedIn;
  bool? isAdmin;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  /// 🔹 Asynchronously checks login status & loads admin role
  Future<void> _initializeAuth() async {
    String? token = await _secureStorage.read(key: "access_token");

    if (token != null) {
      String? userEmail = await _secureStorage.read(key: "user_email");
      if (userEmail != null) {
        await UserRoleManager().fetchUserRole(userEmail);
      }
      await UserRoleManager().loadRole();
      isAdmin = UserRoleManager().isAdmin;
      bool isTeacher = UserRoleManager().isTeacher;
      setState(() {
        isUserLoggedIn = true;
      });
    } else {
      setState(() {
        isUserLoggedIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isUserLoggedIn == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return isUserLoggedIn!
        ? BottomNav(isAdmin: isAdmin ?? false, isTeacher: UserRoleManager().isTeacher)
        : const AcademeScreen();
  }
}
