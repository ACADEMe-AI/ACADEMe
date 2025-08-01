import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChatSession {
  final String title;
  final String timestamp;

  ChatSession({required this.title, required this.timestamp});
}

class ChatHistoryDrawer extends StatelessWidget {
  final List<ChatSession> chatHistory;
  final Function(ChatSession) onSelectChat;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  const ChatHistoryDrawer({
    super.key,
    required this.chatHistory,
    required this.onSelectChat,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Drawer(
        child: Column(
          children: [
            // Header with Profile Picture, Username, and Search Bar
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AcademeTheme.appColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
                child: FutureBuilder<Map<String, String?>>(
                  future: _getUserDetails(),
                  builder: (context, snapshot) {
                    final String name = snapshot.data?['name'] ?? 'User';
                    final String? photoUrl = snapshot.data?['photo_url'];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for Profile Picture and Username
                        Row(
                          children: [
                            // Profile Picture
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: photoUrl != null && photoUrl.isNotEmpty
                                  ? ClipOval(
                                child: Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  width: 60,
                                  height: 60,
                                  errorBuilder: (context, error, stackTrace) {
                                    // Return empty container on error, showing just white circle
                                    return Container();
                                  },
                                ),
                              )
                                  : Container(), // Empty container for white circle
                            ),
                            const SizedBox(width: 20),
                            // Username
                            Text(
                              name,
                              style: TextStyle(
                                fontFamily: 'poppins',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 27,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: L10n.getTranslatedText(
                                  context, 'Search Chat History...'),
                              border: InputBorder.none,
                              icon: Icon(Icons.search,
                                  color: AcademeTheme.appColor),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            // Chat History Feature Coming Soon
            _buildOption(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timeline dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimelineDot(true),
                _buildTimelineLine(),
                _buildTimelineDot(true),
                _buildTimelineLine(),
                _buildTimelineDot(false),
              ],
            ),
            const SizedBox(height: 30),
            Icon(
              Icons.schedule,
              size: 50,
              color: AcademeTheme.appColor.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              L10n.getTranslatedText(context, 'Chat History'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AcademeTheme.appColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.getTranslatedText(context, 'In Development'),
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              L10n.getTranslatedText(context, 'We\'re building something amazing\nfor your chat experience'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineDot(bool isCompleted) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? AcademeTheme.appColor
            : Colors.grey.withOpacity(0.3),
      ),
    );
  }

  Widget _buildTimelineLine() {
    return Container(
      width: 30,
      height: 2,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Future<Map<String, String?>> _getUserDetails() async {
    final String? name = await _secureStorage.read(key: 'name');
    final String? photoUrl = await _secureStorage.read(key: 'photo_url');
    return {
      'name': name,
      'photo_url': photoUrl,
    };
  }
}