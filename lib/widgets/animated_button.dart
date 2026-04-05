// ============================================================
// ANIMATED BUTTON - Glow on hover, bounce on tap, shadow motion
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

class AnimatedGradientButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final List<Color> colors;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final String? semanticLabel;

  const AnimatedGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.colors = const [AppColors.neonRed, AppColors.neonPurple],
    this.icon,
    this.isLoading = false,
    this.width,
    this.semanticLabel,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onPressed == null || widget.isLoading;

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      enabled: !disabled,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: disabled ? null : _onTapDown,
          onTapUp: disabled ? null : _onTapUp,
          onTapCancel: disabled ? null : _onTapCancel,
          onTap: disabled ? null : widget.onPressed,
          child: AnimatedBuilder(
            animation: _scale,
            builder: (context, child) => Transform.scale(
              scale: _scale.value,
              child: child,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: widget.width,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
              decoration: BoxDecoration(
                gradient: disabled
                    ? LinearGradient(
                        colors: widget.colors
                            .map((c) => c.withOpacity(0.4))
                            .toList(),
                      )
                    : LinearGradient(colors: widget.colors),
                borderRadius: BorderRadius.circular(18),
                boxShadow: disabled
                    ? []
                    : [
                        BoxShadow(
                          color: widget.colors.first
                              .withOpacity(_isHovered ? 0.6 : 0.35),
                          blurRadius: _isHovered ? 24 : 14,
                          spreadRadius: _isHovered ? 3 : 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: AppTextStyles.button().copyWith(
                      color: Colors.white,
                      shadows: disabled
                          ? []
                          : [
                              Shadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 8,
                              )
                            ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Outlined Ghost Button ----
class OutlinedAnimatedButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;

  const OutlinedAnimatedButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = AppColors.neonBlue,
    this.icon,
  });

  @override
  State<OutlinedAnimatedButton> createState() => _OutlinedAnimatedButtonState();
}

class _OutlinedAnimatedButtonState extends State<OutlinedAnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
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
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          decoration: BoxDecoration(
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(18),
            color: widget.color.withOpacity(0.08),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 20),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: AppTextStyles.button().copyWith(color: widget.color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
