// widgets/community_widgets.dart
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import '../models/community_model.dart';
import '../controllers/community_controller.dart';
import 'package:ACADEMe/academe_theme.dart';

class CommunitySearchBar extends StatefulWidget {
  final CommunityController controller;

  const CommunitySearchBar({
    super.key,
    required this.controller,
  });

  @override
  State<CommunitySearchBar> createState() => _CommunitySearchBarState();
}

class _CommunitySearchBarState extends State<CommunitySearchBar> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(20),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  widget.controller.searchCommunities(value);
                },
                decoration: InputDecoration(
                  hintText: L10n.getTranslatedText(
                      context, 'Search Communities or topics'),
                  border: InputBorder.none,
                ),
              ),
            ),
            const Icon(Icons.filter_list, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class CommunityTabBar extends StatelessWidget {
  final CommunityController controller;

  const CommunityTabBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final AutoSizeGroup tabTextGroup = AutoSizeGroup();

    return Container(
      color: Colors.white,
      child: TabBar(
        indicatorColor: Colors.blue,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.black,
        indicatorSize: TabBarIndicatorSize.tab,
        onTap: (index) {
          controller.changeTab(index);
        },
        tabs: [
          _buildSynchronizedTab(context, 'Forums', tabTextGroup),
          _buildSynchronizedTab(context, 'Groups', tabTextGroup),
          _buildSynchronizedTab(context, 'Communities', tabTextGroup),
        ],
      ),
    );
  }

  Widget _buildSynchronizedTab(
      BuildContext context, String labelKey, AutoSizeGroup group) {
    return Tab(
      child: AutoSizeText(
        L10n.getTranslatedText(context, labelKey),
        maxLines: 1,
        group: group, // Ensures all tabs shrink together
        style: const TextStyle(fontSize: 16),
        minFontSize: 12, // Prevents text from becoming unreadable
        textAlign: TextAlign.center,
      ),
    );
  }
}

class CommunityList extends StatelessWidget {
  final CommunityController controller;

  const CommunityList({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: controller.communities.length,
      itemBuilder: (context, index) {
        final community = controller.communities[index];
        return CommunityCard(community: community);
      },
    );
  }
}

class CommunityCard extends StatelessWidget {
  final CommunityModel community;

  const CommunityCard({
    super.key,
    required this.community,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: community.color,
          child: Icon(community.icon, color: Colors.white),
        ),
        title: Text(
          L10n.getTranslatedText(context, community.title),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
            L10n.getTranslatedText(context, 'Begin your journey with us!')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups, color: Colors.grey),
            const SizedBox(width: 4),
            Text(community.members),
          ],
        ),
      ),
    );
  }
}

class CommunityAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CommunityAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          AcademeTheme.appColor, // Using theme color instead of hardcoded
      automaticallyImplyLeading: false,
      elevation: 0,
      flexibleSpace: Padding(
        padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const Icon(Icons.groups, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    L10n.getTranslatedText(context, 'My Communities'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);
}
