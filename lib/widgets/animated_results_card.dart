// ============================================================
// ANIMATED RESULTS CARD - Staggered entry animation for responders
// ============================================================

import 'package:flutter/material.dart';

/// Wraps a child widget and animates it in with a staggered delay
class AnimatedResultCard extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const AnimatedResultCard({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<AnimatedResultCard> createState() => _AnimatedResultCardState();
}

class _AnimatedResultCardState extends State<AnimatedResultCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

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
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut)),
      child: FadeTransition(
        opacity: _controller,
        child: widget.child,
      ),
    );
  }
}

/// Displays a list of animated result cards with staggered timing
class AnimatedResultsList extends StatelessWidget {
  final List<Widget> children;
  final Duration staggerDuration;

  const AnimatedResultsList({
    super.key,
    required this.children,
    this.staggerDuration = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        children.length,
        (index) => AnimatedResultCard(
          delay: Duration(
            milliseconds: index * staggerDuration.inMilliseconds,
          ),
          child: children[index],
        ),
      ),
    );
  }
}
