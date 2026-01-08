import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

extension AnimationExtensions on Widget {
  Widget slideInFromLeft({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .slideX(begin: -1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }

  Widget slideInFromRight({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .slideX(begin: 1, duration: 400.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 300.ms);
  }

  Widget slideInFromBottom({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .slideY(begin: 1, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 400.ms);
  }

  Widget bounceIn({Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .scale(begin: const Offset(0.8, 0.8), duration: 600.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 400.ms);
  }

  Widget staggeredFadeIn(int index, {Duration baseDelay = Duration.zero}) {
    return animate(delay: baseDelay + Duration(milliseconds: index * 100))
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOutCubic);
  }

  Widget pulseOnTap() {
    return animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
      duration: 1000.ms,
      curve: Curves.easeInOut,
    );
  }

  Widget shimmerEffect() {
    return animate(
      onPlay: (controller) => controller.repeat(),
    ).shimmer(
      duration: 1500.ms,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget countUp(double value, {Duration delay = Duration.zero}) {
    return animate(delay: delay)
        .custom(
          duration: 1000.ms,
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Text(
              (value * value).toStringAsFixed(0),
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        );
  }
}

class StaggeredGrid extends StatelessWidget {
  final List<Widget> children;
  final Duration baseDelay;

  const StaggeredGrid({
    super.key,
    required this.children,
    this.baseDelay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children
          .asMap()
          .entries
          .map((entry) => entry.value.staggeredFadeIn(
                entry.key,
                baseDelay: baseDelay,
              ))
          .toList(),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final double value;
  final String suffix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value.toStringAsFixed(0)}${widget.suffix}',
          style: widget.style,
        );
      },
    );
  }
}

class FloatingActionButtonAnimated extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String? label;

  const FloatingActionButtonAnimated({
    super.key,
    required this.onPressed,
    required this.icon,
    this.label,
  });

  @override
  State<FloatingActionButtonAnimated> createState() => _FloatingActionButtonAnimatedState();
}

class _FloatingActionButtonAnimatedState extends State<FloatingActionButtonAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () {
                _controller.forward().then((_) {
                  _controller.reverse();
                  widget.onPressed();
                });
              },
              icon: widget.icon,
              label: widget.label != null ? Text(widget.label!) : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}