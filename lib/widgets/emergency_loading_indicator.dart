// ============================================================
// EMERGENCY LOADING INDICATOR - Polished animated loader
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Animated emergency loading indicator with pulsing emergency icon
class EmergencyLoadingIndicator extends StatefulWidget {
  final String message;

  const EmergencyLoadingIndicator({
    super.key,
    this.message = 'Locating nearby help...',
  });

  @override
  State<EmergencyLoadingIndicator> createState() =>
      _EmergencyLoadingIndicatorState();
}

class _EmergencyLoadingIndicatorState extends State<EmergencyLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.neonRed.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emergency,
              size: 48,
              color: AppColors.neonRed,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: AppTextStyles.body().copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => AnimatedDot(
                  delay: index * 200,
                  controller: _pulseController,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual animated dot for loading indicator
class AnimatedDot extends StatelessWidget {
  final int delay;
  final AnimationController controller;

  const AnimatedDot({
    super.key,
    required this.delay,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.4, end: 1.0).animate(
          CurvedAnimation(
            parent: controller,
            curve: Interval(
              delay / 600,
              (delay + 200) / 600,
              curve: Curves.easeInOut,
            ),
          ),
        ),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.neonRed,
          ),
        ),
      ),
    );
  }
}
