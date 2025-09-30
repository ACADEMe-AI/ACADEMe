import 'package:flutter/material.dart';
import 'package:ACADEMe/app/components/askme_button.dart';
import 'package:ACADEMe/app/pages/ask_me/screens/ask_me_screen.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'community_chat_screen.dart';

class MyCommunityScreen extends StatelessWidget {
  const MyCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ASKMeButton(
      showFAB: true,
      onFABPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AskMeScreen()),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AcademeTheme.appColor,
          elevation: 0,
          title: Text(
            L10n.getTranslatedText(context, 'Community'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Search functionality can be added later
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AcademeTheme.appColor.withOpacity(0.1),
                Colors.white,
              ],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 20),
              _buildCommunityOption(
                context,
                icon: Icons.chat_bubble,
                title: L10n.getTranslatedText(context, 'Community Chat'),
                subtitle: L10n.getTranslatedText(
                    context, 'Chat with everyone in real-time'),
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CommunityChatScreen()),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildCommunityOption(
                context,
                icon: Icons.forum,
                title: L10n.getTranslatedText(context, 'Forums'),
                subtitle:
                    L10n.getTranslatedText(context, 'Coming Soon'),
                color: Colors.purple,
                isComingSoon: true,
              ),
              const SizedBox(height: 12),
              _buildCommunityOption(
                context,
                icon: Icons.group,
                title: L10n.getTranslatedText(context, 'Study Groups'),
                subtitle:
                    L10n.getTranslatedText(context, 'Coming Soon'),
                color: Colors.green,
                isComingSoon: true,
              ),
              const SizedBox(height: 12),
              _buildCommunityOption(
                context,
                icon: Icons.event,
                title: L10n.getTranslatedText(context, 'Events'),
                subtitle:
                    L10n.getTranslatedText(context, 'Coming Soon'),
                color: Colors.orange,
                isComingSoon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AcademeTheme.appColor, AcademeTheme.appColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AcademeTheme.appColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  L10n.getTranslatedText(context, 'Welcome to Community'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            L10n.getTranslatedText(
                context, 'Connect, share, and learn together with your peers'),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isComingSoon = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isComingSoon
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          L10n.getTranslatedText(context, 'Coming Soon')),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          if (isComingSoon) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                L10n.getTranslatedText(context, 'Soon'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[800],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}