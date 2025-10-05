import 'package:ACADEMe/app/pages/bottom_nav/providers/bottom_nav_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../academe_theme.dart';
import '../../admin_panel/courses.dart';
import '../courses/screens/course_list_screen.dart';
import '../homepage/screens/home_screen.dart';
import 'package:ACADEMe/app/pages/community/screens/community_screen.dart';
import 'package:ACADEMe/app/pages/profile/screens/profile_page.dart';
import 'package:ACADEMe/localization/l10n.dart';

// Import the new teacher screens
import '../../teacher_panel/teacher_home_screen.dart';
import '../../teacher_panel/teacher_content_screen.dart';
import '../../teacher_panel/teacher_live_classes_screen.dart';
import '../../teacher_panel/teacher_student_management_screen.dart';
import '../../teacher_panel/teacher_profile_screen.dart';

class BottomNav extends StatefulWidget {
  final bool isAdmin;
  final bool isTeacher;
  const BottomNav({super.key, required this.isAdmin, this.isTeacher = false});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  @override
  void initState() {
    super.initState();
    // Reset index to 0 when BottomNav is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<BottomNavProvider>(context, listen: false);
        // Get max valid index for current role
        final maxIndex = widget.isAdmin ? 4 : (widget.isTeacher ? 4 : 3);
        // Reset to 0 if current index is out of bounds
        if (provider.selectedIndex > maxIndex) {
          provider.setIndex(0);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BottomNavProvider>(
      builder: (context, bottomNavProvider, child) {
        final int selectedIndex = bottomNavProvider.selectedIndex;

        final List<Widget> pages = widget.isAdmin
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
            : widget.isTeacher
            ? [
          TeacherHomeScreen(
            onProfileTap: () => bottomNavProvider.setIndex(4),
            onContentTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex,
          ),
          const TeacherContentScreen(),
          const TeacherLiveClassesScreen(),
          const TeacherStudentManagementScreen(),
          const TeacherProfileScreen(),
        ]
            : [
          HomeScreen(
            onProfileTap: () => bottomNavProvider.setIndex(3),
            onCourseTap: () => bottomNavProvider.setIndex(1),
            selectedIndex: selectedIndex,
          ),
          const CourseListScreen(),
          const MyCommunityScreen(),
          const ProfilePage(),
        ];

        // Ensure selectedIndex is within bounds
        final safeIndex = selectedIndex < pages.length ? selectedIndex : 0;

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: bottomNavProvider.setIndex,
            selectedItemColor: AcademeTheme.appColor.withAlpha(180),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            items: widget.isAdmin
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
                : widget.isTeacher
                ? [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: L10n.getTranslatedText(context, 'Home')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.content_copy),
                  label: L10n.getTranslatedText(context, 'Content')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.video_call),
                  label:
                  L10n.getTranslatedText(context, 'Live Classes')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.people),
                  label: L10n.getTranslatedText(context, 'Students')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: L10n.getTranslatedText(context, 'Profile')),
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
