import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../localization/l10n.dart';

class SwipeableBanner extends StatelessWidget {
  final PageController pageController;

  const SwipeableBanner({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: pageController,
              children: [
                _AdContainer(color: Colors.purple[200]!, context: context),
                _AdContainer(color: Colors.blue[200]!, context: context),
                _AdContainer(color: Colors.green[200]!, context: context),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SmoothPageIndicator(
            controller: pageController,
            count: 3,
            effect: ExpandingDotsEffect(
              activeDotColor: Colors.purple,
              dotColor: Colors.grey[300]!,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdContainer extends StatelessWidget {
  final Color color;
  final BuildContext context;

  const _AdContainer({required this.color, required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          L10n.getTranslatedText(context, 'Clear your doubts'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${L10n.getTranslatedText(context, 'Experts ready to clear')} \n${L10n.getTranslatedText(context, 'your doubts anytime')}",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black54,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 0),
              ],
            ),
          ),
          Positioned(
            right: 5,
            top: 8,
            child: Image.asset(
              "assets/images/img.png",
              width: 140,
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
