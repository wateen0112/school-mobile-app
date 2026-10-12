import 'dart:ui';

import 'package:flutter/material.dart';

class AnimatedContainer extends StatefulWidget {
  const AnimatedContainer({
    super.key,
    required this.child,
    this.delay = 0,
    this.duration = const Duration(milliseconds: 500),
    this.animationType = AnimationType.fadeScale,
  });

  final Widget child;
  final int delay;
  final Duration duration;
  final AnimationType animationType;

  @override
  State<AnimatedContainer> createState() => _AnimatedContainerState();
}

class _AnimatedContainerState extends State<AnimatedContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAnimated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Initialize animation based on type
    switch (widget.animationType) {
      case AnimationType.fadeScale:
        _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );
        break;
      case AnimationType.fadeUp:
        _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );
        break;
      case AnimationType.slideLeft:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );
        break;
      case AnimationType.slideRight:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );
        break;
      case AnimationType.blurFade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void animateIfNotAnimated() {
    if (!_isAnimated) {
      _isAnimated = true;
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Start animation when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      animateIfNotAnimated();
    });

    switch (widget.animationType) {
      case AnimationType.fadeScale:
        return _buildFadeScaleAnimation();
      case AnimationType.fadeUp:
        return _buildFadeUpAnimation();
      case AnimationType.slideLeft:
        return _buildSlideLeftAnimation();
      case AnimationType.slideRight:
        return _buildSlideRightAnimation();
      case AnimationType.blurFade:
        return _buildBlurFadeAnimation();
    }
  }

  Widget _buildFadeScaleAnimation() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: _animation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildFadeUpAnimation() {
    final translateY = (1 - _animation.value) * 50;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, translateY),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildSlideLeftAnimation() {
    final slideX = (1 - _animation.value) * -50;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(slideX, 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildSlideRightAnimation() {
    final slideX = (1 - _animation.value) * 50;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(slideX, 0),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  Widget _buildBlurFadeAnimation() {
    final blur = (1 - _animation.value) * 4;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

enum AnimationType {
  fadeScale,
  fadeUp,
  slideLeft,
  slideRight,
  blurFade,
}
