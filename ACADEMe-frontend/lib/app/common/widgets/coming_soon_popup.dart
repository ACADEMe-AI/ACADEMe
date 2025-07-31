import 'package:flutter/material.dart';
import 'package:ACADEMe/academe_theme.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:lottie/lottie.dart';

class ComingSoonPopup extends StatefulWidget {
  final String featureName;
  final IconData? icon;
  final String? description;
  final String? lottieAsset;

  const ComingSoonPopup({
    super.key,
    required this.featureName,
    this.icon,
    this.description,
    this.lottieAsset,
  });

  @override
  State<ComingSoonPopup> createState() => _ComingSoonPopupState();
}

class _ComingSoonPopupState extends State<ComingSoonPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation or Icon
              if (widget.lottieAsset != null)
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Lottie.asset(
                    widget.lottieAsset!,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AcademeTheme.appColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon ?? Icons.star,
                    size: 50,
                    color: AcademeTheme.appColor,
                  ),
                ),

              const SizedBox(height: 20),

              // Coming Soon Title
              Text(
                L10n.getTranslatedText(context, 'Coming Soon!'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AcademeTheme.appColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Feature Name
              Text(
                widget.featureName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                widget.description ??
                    L10n.getTranslatedText(context, 'We\'re working hard to bring you this awesome feature! 🚀'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Fun progress bar
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.6 * 0.75, // 75% progress
                      height: 8,
                      decoration: BoxDecoration(
                        color: AcademeTheme.appColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: -2,
                      child: Text(
                        '75%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AcademeTheme.appColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.notifications, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                L10n.getTranslatedText(context, 'We\'ll let you know when it\'s ready! 🎉'),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: AcademeTheme.appColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AcademeTheme.appColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    L10n.getTranslatedText(context, 'Got it! 👍'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Close button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  L10n.getTranslatedText(context, 'Close'),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
