import 'package:flutter/material.dart';

/// Staggered Animation Helper
/// Creates sequential animations with delay for list items
class StaggeredAnimationHelper {
  /// Create a staggered animation config for a list
  static AnimationConfig forList({
    required int itemCount,
    Duration baseDelay = const Duration(milliseconds: 50),
    Duration animationDuration = const Duration(milliseconds: 300),
  }) {
    return AnimationConfig(
      itemCount: itemCount,
      baseDelay: baseDelay,
      animationDuration: animationDuration,
    );
  }

  /// Get delay for specific item index
  static Duration delayFor(
    int index, {
    Duration baseDelay = const Duration(milliseconds: 50),
  }) {
    return baseDelay * index;
  }
}

class AnimationConfig {
  final int itemCount;
  final Duration baseDelay;
  final Duration animationDuration;

  const AnimationConfig({
    required this.itemCount,
    required this.baseDelay,
    required this.animationDuration,
  });

  Duration delayForIndex(int index) {
    return baseDelay * index;
  }
}

/// Fade and Slide Animation Widget
/// Provides fade-in and slide-up animation
class FadeSlideAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset begin;
  final Offset end;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 300),
    this.begin = const Offset(0, 0.1),
    this.end = Offset.zero,
  });

  @override
  State<FadeSlideAnimation> createState() => _FadeSlideAnimationState();
}

class _FadeSlideAnimationState extends State<FadeSlideAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}

/// Scale Animation Widget
/// Provides scale animation (for buttons, cards, etc.)
class ScaleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double scaleBegin;
  final double scaleEnd;
  final bool autoPlay;

  const ScaleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.scaleBegin = 0,
    this.scaleEnd = 1,
    this.autoPlay = true,
  });

  @override
  State<ScaleAnimation> createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: widget.scaleBegin,
      end: widget.scaleEnd,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.autoPlay) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}

/// Shimmer Loading Animation
/// Provides shimmer effect for loading states
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final baseColor =
        widget.baseColor ?? theme.colorScheme.surfaceContainerHighest;
    final highlightColor = widget.highlightColor ?? theme.colorScheme.surface;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Pulse Animation
/// For highlighting elements (like price changes)
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1000),
    this.minScale = 0.95,
    this.maxScale = 1.05,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scaleAnimation, child: widget.child);
  }
}
