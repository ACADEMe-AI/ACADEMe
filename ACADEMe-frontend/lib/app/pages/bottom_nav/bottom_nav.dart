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

// Teacher-specific screens (placeholders for now)
class TeacherHomeScreen extends StatelessWidget {
  final Function() onProfileTap;
  final Function() onContentTap;
  final int selectedIndex;
  
  const TeacherHomeScreen({
    super.key,
    required this.onProfileTap,
    required this.onContentTap,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Dashboard'),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 80, color: AcademeTheme.appColor),
            SizedBox(height: 20),
            Text(
              'Welcome Teacher!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Manage your classes and content from here',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherContentScreen extends StatelessWidget {
  const TeacherContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Content Management'),
          backgroundColor: AcademeTheme.appColor,
          bottom: TabBar(
            tabs: [
              Tab(text: "My Content"),
              Tab(text: "Self Study Material"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Teacher's Content Tab
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upload_file, size: 80, color: AcademeTheme.appColor),
                  SizedBox(height: 20),
                  Text(
                    'My Uploaded Content',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'View and upload your teaching materials',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement content upload
                    },
                    icon: Icon(Icons.add),
                    label: Text('Upload Content'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcademeTheme.appColor,
                    ),
                  ),
                ],
              ),
            ),
            // Self Study Material Tab
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 80, color: AcademeTheme.appColor),
                  SizedBox(height: 20),
                  Text(
                    'Self Study Material',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Browse available study materials',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherLiveClassesScreen extends StatelessWidget {
  const TeacherLiveClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Live Classes & Recordings'),
          backgroundColor: AcademeTheme.appColor,
          bottom: TabBar(
            tabs: [
              Tab(text: "Schedule Classes"),
              Tab(text: "Recordings"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Schedule Classes Tab
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.schedule, size: 80, color: AcademeTheme.appColor),
                  SizedBox(height: 20),
                  Text(
                    'Schedule Classes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Schedule and manage your live classes',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement class scheduling
                    },
                    icon: Icon(Icons.add),
                    label: Text('Schedule New Class'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AcademeTheme.appColor,
                    ),
                  ),
                ],
              ),
            ),
            // Recordings Tab
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 80, color: AcademeTheme.appColor),
                  SizedBox(height: 20),
                  Text(
                    'Class Recordings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AcademeTheme.appColor,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'View all your recorded lectures',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherStudentManagementScreen extends StatelessWidget {
  const TeacherStudentManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Management'),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: AcademeTheme.appColor),
            SizedBox(height: 20),
            Text(
              'Student Management',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'View students class-wise with detailed analytics',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              '• View all classes you are allotted to\n• Click on any class to see student details\n• View individual student progress and quiz scores',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Teacher Profile'),
        backgroundColor: AcademeTheme.appColor,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 80, color: AcademeTheme.appColor),
            SizedBox(height: 20),
            Text(
              'Teacher Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Manage your profile and teaching preferences',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  icon: Icon(Icons.content_copy),
                  label: L10n.getTranslatedText(context, 'Content')),
              BottomNavigationBarItem(
                  icon: Icon(Icons.video_call),
                  label: L10n.getTranslatedText(context, 'Live Classes')),
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