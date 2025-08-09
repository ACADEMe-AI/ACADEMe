import 'package:flutter/material.dart';
// Import your theme and localization files
// import 'package:your_app/theme/academe_theme.dart';
// import 'package:your_app/localization/l10n.dart';

class ProgressLoadingWidget extends StatefulWidget {
  final String? primaryText;
  final String? secondaryText;
  final List<String>? motivationalTips;
  final Color? primaryColor;

  const ProgressLoadingWidget({
    Key? key,
    this.primaryText,
    this.secondaryText,
    this.motivationalTips,
    this.primaryColor,
  }) : super(key: key);

  @override
  State<ProgressLoadingWidget> createState() => _ProgressLoadingWidgetState();
}

class _ProgressLoadingWidgetState extends State<ProgressLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _fadeController;
  late AnimationController _progressController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Initialize animations
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 6.28, // 2π radians = 360 degrees
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
    _fadeController.repeat(reverse: true);
    _progressController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    _fadeController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Color get _primaryColor =>
      widget.primaryColor ?? Theme.of(context).primaryColor;

  @override
  Widget build(BuildContext context) {
    return _buildLoadingAnimation();
  }

  Widget _buildLoadingAnimation() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive sizes based on available space - Fixed type casting
        final maxHeight =
            constraints.maxHeight > 0 ? constraints.maxHeight : 400.0;
        final circleSize = (maxHeight * 0.25).clamp(100.0, 140.0).toDouble();
        final verticalSpacing = (maxHeight * 0.03).clamp(8.0, 20.0).toDouble();

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: maxHeight,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: verticalSpacing,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Main animated loading circle with gradient
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: AnimatedBuilder(
                          animation: _rotationAnimation,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      _primaryColor.withOpacity(0.2),
                                      _primaryColor,
                                      _primaryColor.withOpacity(0.8),
                                      _primaryColor.withOpacity(0.3),
                                    ],
                                    stops: const [0.0, 0.3, 0.7, 1.0],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.3),
                                      blurRadius: 25,
                                      spreadRadius: 8,
                                    ),
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.1),
                                      blurRadius: 40,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Inner circle
                                    Container(
                                      width: circleSize * 0.57,
                                      height: circleSize * 0.57,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.analytics_outlined,
                                        size: circleSize * 0.29,
                                        color: _primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: verticalSpacing * 2),

                  // Animated loading text with typing effect
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              widget.primaryText ??
                                  'Analyzing your progress...',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: verticalSpacing * 0.6),
                            Text(
                              widget.secondaryText ??
                                  'Generating personalized insights',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  SizedBox(height: verticalSpacing * 1.5),

                  // Animated progress bar
                  Container(
                    width: 180,
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: Colors.grey[300],
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Stack(
                          children: [
                            Container(
                              width: 180 * _progressAnimation.value,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor.withOpacity(0.6),
                                    _primaryColor,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  SizedBox(height: verticalSpacing * 1.2),

                  // Bouncing progress dots
                  _buildProgressDots(),

                  SizedBox(height: verticalSpacing),

                  // Motivational tips
                  _buildMotivationalTips(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            final delay = index * 0.4;
            final animationValue = (_fadeController.value + delay) % 1.0;
            final scale = 0.5 + (animationValue * 0.5);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.6),
                        _primaryColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryColor.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildMotivationalTips() {
    final tips = widget.motivationalTips ??
        [
          'Reviewing your study patterns',
          'Identifying improvement areas',
          'Creating personalized suggestions',
        ];

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        final tipIndex = (_fadeController.value * tips.length).floor();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _primaryColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: _primaryColor,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  tips[tipIndex % tips.length],
                  style: TextStyle(
                    fontSize: 12,
                    color: _primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
