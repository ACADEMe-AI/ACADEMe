import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ACADEMe/app/auth/auth_service.dart';
import 'package:ACADEMe/app/pages/ask_me/screens/ask_me_screen.dart';
import 'package:ACADEMe/app/pages/progress/screens/progress_screen.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../../../../started/pages/login_view.dart';
import '../controllers/home_controller.dart';

class HomepageDrawer extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onProfileTap;
  final VoidCallback onCourseTap;

  const HomepageDrawer({
    super.key,
    required this.onClose,
    required this.onProfileTap,
    required this.onCourseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeController>(
      builder: (context, controller, child) {
        return FutureBuilder<Map<String, String?>>(
          future: controller.getUserDetails(),
          builder: (context, snapshot) {
            final String name = snapshot.data?['name'] ?? 'User';
            final String photoUrl =
                snapshot.data?['photo_url'] ?? 'assets/design_course/userImage.png';

            return Container(
              width: MediaQuery.of(context).size.width * 0.75,
              height: MediaQuery.of(context).size.height * 1,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo aligned slightly to the left
                  Padding(
                    padding: const EdgeInsets.only(top: 40, left: 0),
                    child: SizedBox(
                      height: 60,
                      width: 300,
                      child: Image.asset(
                        'assets/academe/academe_logo.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Drawer Items with Navigation
                  _buildDrawerItem(
                      Icons.bookmark, L10n.getTranslatedText(context, 'Bookmarks'),
                          () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => const BookmarksScreen(),
                        //   ),
                        // );
                      }),
                  _buildDrawerItem(
                      Icons.person, L10n.getTranslatedText(context, 'Profile'), () {
                    onProfileTap();
                    onClose();
                  }),
                  _buildDrawerItem(
                    Icons.menu_book,
                    L10n.getTranslatedText(context, 'My Courses'),
                        () {
                      onCourseTap(); // Navigates to the function you want
                      onClose();
                    },
                  ),
                  _buildDrawerItem(Icons.show_chart,
                      L10n.getTranslatedText(context, 'My Progress'), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProgressScreen(),
                          ),
                        );
                      }),
                  _buildDrawerItem(Icons.headset_mic, "ASKMe", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AskMeScreen(),
                      ),
                    );
                  }),
                  _buildDrawerItem(
                      Icons.settings, L10n.getTranslatedText(context, 'Settings'),
                          () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => const SettingsScreen(),
                        //   ),
                        // );
                      }),
                  _buildDrawerItem(Icons.help_outline,
                      L10n.getTranslatedText(context, 'Get Help'), () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (context) => const HelpScreen(),
                        //   ),
                        // );
                      }),
                  const Spacer(),
                  // User Profile Section
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            onProfileTap();
                            onClose();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.blueAccent, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: photoUrl.startsWith('http')
                                  ? NetworkImage(photoUrl) as ImageProvider
                                  : AssetImage(photoUrl),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.logout,
                              color: Colors.redAccent, size: 28),
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LogInView()),
        );
      }
    } catch (e) {
      // Error handling without print statements
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${L10n.getTranslatedText(context, 'Logout failed')}: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color.fromARGB(255, 214, 238, 242),
          highlightColor: const Color.fromARGB(255, 166, 221, 239),
          child: ListTile(
            leading: Icon(icon, color: Colors.black, size: 28),
            title: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }
}
