// ============================================================
// GLOWING CARD - Glassmorphism card with lift on hover/scroll
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

class GlowingCard extends StatefulWidget {
  final Widget child;
  final List<Color>? glowColors;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool animateIn;

  const GlowingCard({
    super.key,
    required this.child,
    this.glowColors,
    this.padding,
    this.borderRadius = 20,
    this.animateIn = true,
  });

  @override
  State<GlowingCard> createState() => _GlowingCardState();
}

class _GlowingCardState extends State<GlowingCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _elevation;
  late Animation<double> _glowOpacity;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _elevation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.4).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onEnter(_) {
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onExit(_) {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColors ??
        [AppColors.neonBlue, AppColors.neonPurple];

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _hoverController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_elevation.value),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                color: AppColors.darkCard,
                border: Border.all(
                  color: _isHovered
                      ? glow.first.withOpacity(0.5)
                      : AppColors.glassBorder.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: glow.first.withOpacity(_glowOpacity.value),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Padding(
            padding: widget.padding ?? const EdgeInsets.all(20),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ---- Gradient Stat Card ----
class GradientStatCard extends StatelessWidget {
  final String title;
  final Widget statWidget;
  final String subtitle;
  final List<Color> colors;
  final IconData icon;

  const GradientStatCard({
    super.key,
    required this.title,
    required this.statWidget,
    required this.subtitle,
    required this.colors,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withOpacity(0.15)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.first.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.first.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: colors.first, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTextStyles.caption().copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          statWidget,
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption().copyWith(
              color: colors.first.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
