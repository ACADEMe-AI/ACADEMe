import 'package:flutter/material.dart';
import '../models/overview_model.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';

class OverviewHeader extends StatelessWidget {
  final double height;
  final double width;
  final OverviewModel model;
  final VoidCallback onBackPressed;

  const OverviewHeader({
    super.key,
    required this.height,
    required this.width,
    required this.model,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height * 0.38,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF967EF6), Color(0xFFE8DAF9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.05,
          vertical: height * 0.05,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: onBackPressed,
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    L10n.getTranslatedText(context, 'Topic details'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.bookmark_border, color: Colors.black),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: width * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.02),
                    Text(
                      model.isLoading
                          ? "${L10n.getTranslatedText(context, 'Loading')}..."
                          : model.topicTitle,
                      style: TextStyle(
                        fontSize: width * 0.08,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: height * 0.01),
                    Text(
                      model.isLoading
                          ? "${L10n.getTranslatedText(context, 'Fetching topic details')}..."
                          : model.topicDescription,
                      style: TextStyle(
                        fontSize: width * 0.04,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressSection extends StatelessWidget {
  final double height;
  final double width;
  final OverviewModel model;

  const ProgressSection({
    super.key,
    required this.height,
    required this.width,
    required this.model,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.getTranslatedText(context, 'Your Progress'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.005),
          Text(
              "${model.completedSubtopics}/${model.totalSubtopics} ${L10n.getTranslatedText(context, 'Modules')}"),
          SizedBox(height: height * 0.01),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: model.progressPercentage,
              color: AcademeTheme.appColor,
              backgroundColor: const Color(0xFFE8E5FB),
              minHeight: height * 0.012,
            ),
          ),
          SizedBox(height: height * 0.02),
          const Divider(color: Colors.grey, thickness: 0.5),
          SizedBox(height: height * 0.005),
        ],
      ),
    );
  }
}

class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}
