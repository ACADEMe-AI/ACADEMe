import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this dependency if not already present
import 'package:ACADEMe/app/components/askme_button.dart';
import 'package:ACADEMe/app/pages/ask_me/screens/ask_me_screen.dart';
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
                body: Column(
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
              body: Column(
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
          ),
        );
      },
    );
  }
}