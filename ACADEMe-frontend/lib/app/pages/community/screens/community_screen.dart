import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this dependency if not already present
import 'package:ACADEMe/app/components/askme_button.dart';
import 'package:ACADEMe/app/pages/ask_me/screens/ask_me_screen.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../controllers/community_controller.dart';
import '../widgets/community_widgets.dart';

class MyCommunityScreen extends StatelessWidget {
  const MyCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => CommunityController()..initialize(),
      child: Consumer<CommunityController>(
        builder: (context, controller, child) {
          return ASKMeButton(
            showFAB: true, // Show floating action button
            onFABPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AskMeScreen()),
              );
            },
            child: DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: const CommunityAppBar(),
                body: Stack(
                  children: [
                    // Original content with reduced opacity
                    Opacity(
                      opacity: 0.3,
                      child: Column(
                        children: [
                          // Fixed Search Bar
                          CommunitySearchBar(controller: controller),

                          // Fixed TabBar
                          CommunityTabBar(controller: controller),

                          // TabBarView scrolls while search bar & tab bar remain fixed
                          Expanded(
                            child: TabBarView(
                              children: [
                                Center(
                                  child: Text(
                                    L10n.getTranslatedText(context, 'Forums Section'),
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    L10n.getTranslatedText(context, 'Groups Section'),
                                  ),
                                ),
                                CommunityList(controller: controller),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Coming soon overlay
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 50,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              L10n.getTranslatedText(context, 'Coming Soon'),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              L10n.getTranslatedText(context, 'Community section will be available soon'),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle coming soon action
                                  // You can add your logic here
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AcademeTheme.appColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 3,
                                ),
                                child: Text(
                                  L10n.getTranslatedText(context, 'Stay Tuned'),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Alternative implementation without Provider (if you prefer not to use state management)
class MyCommunityScreenStateful extends StatefulWidget {
  const MyCommunityScreenStateful({super.key});

  @override
  State<MyCommunityScreenStateful> createState() => _MyCommunityScreenStatefulState();
}

class _MyCommunityScreenStatefulState extends State<MyCommunityScreenStateful> {
  late CommunityController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CommunityController();
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ASKMeButton(
          showFAB: true, // Show floating action button
          onFABPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AskMeScreen()),
            );
          },
          child: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: const CommunityAppBar(),
              body: Stack(
                children: [
                  // Original content with reduced opacity
                  Opacity(
                    opacity: 0.3,
                    child: Column(
                      children: [
                        // Fixed Search Bar
                        CommunitySearchBar(controller: _controller),

                        // Fixed TabBar
                        CommunityTabBar(controller: _controller),

                        // TabBarView scrolls while search bar & tab bar remain fixed
                        Expanded(
                          child: TabBarView(
                            children: [
                              Center(
                                child: Text(
                                  L10n.getTranslatedText(context, 'Forums Section'),
                                ),
                              ),
                              Center(
                                child: Text(
                                  L10n.getTranslatedText(context, 'Groups Section'),
                                ),
                              ),
                              CommunityList(controller: _controller),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Coming soon overlay
                  Center(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 50,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            L10n.getTranslatedText(context, 'Coming Soon'),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            L10n.getTranslatedText(context, 'Community section will be available soon'),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle coming soon action
                                // You can add your logic here
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AcademeTheme.appColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                L10n.getTranslatedText(context, 'Stay Tuned'),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}