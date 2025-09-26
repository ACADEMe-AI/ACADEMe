import 'package:ACADEMe/app/pages/bottom_nav/providers/bottom_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../academe_theme.dart';
import '../../admin_panel/courses.dart';
import '../../teacher_panel/teacher_dashboard.dart';
import '../courses/screens/course_list_screen.dart';
import '../homepage/screens/home_screen.dart';
import 'package:ACADEMe/app/pages/community/screens/community_screen.dart';
import 'package:ACADEMe/app/pages/profile/screens/profile_page.dart';
import 'package:ACADEMe/localization/l10n.dart';

class BottomNav extends StatelessWidget {
  final bool isAdmin;
  final bool isTeacher;
  const BottomNav({super.key, required this.isAdmin, this.isTeacher = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        final int selectedIndex = bottomNavProvider.selectedIndex;

        final List<Widget> pages = isAdmin
            ? [
          HomeScreen(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onCourseTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex,
          ),
          const CourseListScreen(),
          const MyCommunityScreen(),
          const ProfilePage(),
          CourseManagementScreen(),
        ]
            : isTeacher
            ? [
          HomeScreen(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onCourseTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex,
          ),
          CourseListScreen(),
          MyCommunityScreen(),
          ProfilePage(),
          TeacherDashboard(),
        ]
            : [
          HomeScreen(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onCourseTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex,
          ),
          CourseListScreen(),
          MyCommunityScreen(),
          ProfilePage(),
        ];

        return Scaffold(
          body: pages[selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: bottomNavProvider.setIndex,
            selectedItemColor: AcademeTheme.appColor.withAlpha(180),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: isAdmin
                ? [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: L10n.getTranslatedText(context, 'Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: L10n.getTranslatedText(context, 'Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: L10n.getTranslatedText(context, 'Admin')),
            ]
                : isTeacher
                ? [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: L10n.getTranslatedText(context, 'Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: L10n.getTranslatedText(context, 'Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school_outlined),
                  label: L10n.getTranslatedText(context, 'Teaching')),
            ]
                : [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.school),
                  label: L10n.getTranslatedText(context, 'Courses')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.groups),
                  label: L10n.getTranslatedText(context, 'Community')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
            ],
          ),
        );
      },
    );
  }
}
