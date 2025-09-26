import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../academe_theme.dart';
import '../../localization/l10n.dart';
import '../../localization/language_provider.dart';
import 'student_analytics.dart';
import 'teacher_content.dart';
import 'live_classes.dart';
import 'teacher_settings.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  TeacherDashboardState createState() => TeacherDashboardState();
}

class TeacherDashboardState extends State<TeacherDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AcademeTheme.appColor,
        title: Text(
          L10n.getTranslatedText(context, 'Teacher Dashboard'),
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              text: L10n.getTranslatedText(context, 'Analytics'),
              icon: Icon(Icons.analytics),
            ),
            Tab(
              text: L10n.getTranslatedText(context, 'Content'),
              icon: Icon(Icons.content_copy),
            ),
            Tab(
              text: L10n.getTranslatedText(context, 'Live Classes'),
              icon: Icon(Icons.video_call),
            ),
            Tab(
              text: L10n.getTranslatedText(context, 'Settings'),
              icon: Icon(Icons.settings),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StudentAnalytics(),
          TeacherContent(),
          LiveClasses(),
          TeacherSettings(),
        ],
      ),
    );
  }
}
