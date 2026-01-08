import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

class ElasticCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const ElasticCard({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<ElasticCard> createState() => _ElasticCardState();
}

class _ElasticCardState extends State<ElasticCard>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 1.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animatePress() {
    _controller.reset();
    final simulation = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 500, damping: 15),
      0.0,
      1.0,
      0.0,
    );
    _controller.animateWith(simulation);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _animatePress();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.95 + (_animation.value * 0.05),
            child: widget.child,
          );
        },
      ),
    );
  }
}

class RippleEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? rippleColor;

  const RippleEffect({
    super.key,
    required this.child,
    this.onTap,
    this.rippleColor,
  });

  @override
  State<RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _tapPosition = details.localPosition;
        });
        _controller.forward().then((_) => _controller.reset());
      },
      onTap: widget.onTap,
      child: CustomPaint(
        painter: _RipplePainter(
          animation: _animation,
          tapPosition: _tapPosition,
          color: widget.rippleColor ?? Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: widget.child,
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset? tapPosition;
  final Color color;

  _RipplePainter({
    required this.animation,
    this.tapPosition,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (tapPosition != null && animation.value > 0) {
      final paint = Paint()
        ..color = color.withOpacity(1 - animation.value)
        ..style = PaintingStyle.fill;

      final radius = size.width * animation.value;
      canvas.drawCircle(tapPosition!, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CustomSlideTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Offset end;

  const CustomSlideTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  });

  @override
  State<CustomSlideTransition> createState() => _CustomSlideTransitionState();
}

class _CustomSlideTransitionState extends State<CustomSlideTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _offsetAnimation = Tween<Offset>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}