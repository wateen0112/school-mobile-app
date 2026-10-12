import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// School-themed splash screen with animated opening sequence
///
/// Shows a school-related animation sequence that plays once on app startup.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onComplete});

  /// Callback when splash animation completes
  final VoidCallback? onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animation states
  late final Animation<double> _overallOpacity;
  late final Animation<double> _bookSlide;
  late final Animation<double> _booksStackScale;
  late final Animation<double> _penSpin;
  late final Animation<double> _graduationCapFade;
  late final Animation<double> _titleFade;

  @override
  void initState() {
    super.initState();

    // Animation controller - shorter duration for a cleaner experience
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Overall fade animation
    _overallOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Book sliding in from bottom
    _bookSlide = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    // Books stack scaling up
    _booksStackScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
      ),
    );

    // Pen spinning animation
    _penSpin = Tween<double>(begin: -0.5, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Graduation cap fading in
    _graduationCapFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    // Title fading in
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    // Start animation once
    _controller.forward();

    // Complete when animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.promoGradient,
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _overallOpacity.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      // Animated books stack
                      Transform.translate(
                        offset: Offset(0, _bookSlide.value),
                        child: Transform.scale(
                          scale: _booksStackScale.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Book 1 - Blue
                              _buildBook(
                                color: AppTheme.primaryLight,
                                width: 40,
                                height: 60,
                                depth: 10,
                                rotation: 0.1,
                              ),
                              // Book 2 - Purple
                              Transform.translate(
                                offset: const Offset(5, 0),
                                child: _buildBook(
                                  color: AppTheme.purple,
                                  width: 40,
                                  height: 60,
                                  depth: 10,
                                  rotation: -0.1,
                                ),
                              ),
                              // Book 3 - Coral
                              Transform.translate(
                                offset: const Offset(-5, 0),
                                child: _buildBook(
                                  color: AppTheme.coral,
                                  width: 40,
                                  height: 60,
                                  depth: 10,
                                  rotation: 0.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Graduation cap appearing
                      Opacity(
                        opacity: _graduationCapFade.value,
                        child: Transform.rotate(
                          angle: _penSpin.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Pencil/pen representing writing/study
                              Container(
                                width: 30,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppTheme.coral,
                                  borderRadius: BorderRadius.circular(5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.shadowTint
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Pencil tip
                                    Positioned(
                                      left: 0,
                                      child: Container(
                                        width: 0,
                                        height: 0,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.coral,
                                            width: 0,
                                          ),
                                        ),
                                        child: ClipPath(
                                          clipper: _PencilTipClipper(),
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            color: AppTheme.coral,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Graduation cap
                              Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppTheme.ink,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // Cap tassel
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: AppTheme.coral,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    // Cap board
                                    Container(
                                      width: 40,
                                      height: 15,
                                      color: AppTheme.ink,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Animated title
                      Opacity(
                        opacity: _titleFade.value,
                        child: Text(
                          'YallaCode',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: AppTheme.cardSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _titleFade.value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'School Management',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.cardSurface.withValues(alpha: 0.9),
                                  letterSpacing: 1,
                                ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Build a stylized book widget
  Widget _buildBook({
    required Color color,
    required double width,
    required double height,
    required double depth,
    double rotation = 0,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Book cover
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowTint.withValues(alpha: 0.2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Book title indicator
                  Container(
                    width: width - 8,
                    height: 4,
                    color: AppTheme.cardSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: width - 12,
                    height: 2,
                    color: AppTheme.cardSurface.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
          ),
          // Book spine (depth effect)
          Positioned(
            left: width - 4,
            child: Container(
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color.darken(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clipper for pencil tip
class _PencilTipClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height / 2);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height / 2);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Extension for darkening colors
extension _ColorExtensions on Color {
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withLightness(hsl.lightness - amount).toColor();
  }
}
