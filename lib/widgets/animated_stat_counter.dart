// ============================================================
// ANIMATED STAT COUNTER - Count-up animation for stats
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

class AnimatedStatCounter extends StatefulWidget {
  final int end;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;

  const AnimatedStatCounter({
    super.key,
    required this.end,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 1800),
  });

  @override
  State<AnimatedStatCounter> createState() => _AnimatedStatCounterState();
}

class _AnimatedStatCounterState extends State<AnimatedStatCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<double>(begin: 0, end: widget.end.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    // Delay start slightly so it's visible to user
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
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
      builder: (context, _) {
        final value = _animation.value.toInt();
        return Text(
          '${widget.prefix}${_formatNumber(value)}${widget.suffix}',
          style: widget.style ?? AppTextStyles.statNumber(),
        );
      },
    );
  }

  /// Formats large numbers with commas: 2400 -> 2,400
  String _formatNumber(int n) {
    if (n < 1000) return n.toString();
    final str = n.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if ((str.length - i) % 3 == 0 && i != 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}

// ---- Inline stat display (label + counter) ----
class StatCounterTile extends StatelessWidget {
  final int value;
  final String suffix;
  final String prefix;
  final String label;
  final List<Color> gradient;

  const StatCounterTile({
    super.key,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    required this.label,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: gradient,
          ).createShader(bounds),
          child: AnimatedStatCounter(
            end: value,
            suffix: suffix,
            prefix: prefix,
            style: AppTextStyles.statNumber().copyWith(color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
