// ============================================================
// EMERGENCY FAB - Floating red pulsing emergency trigger button
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';

class EmergencyFAB extends StatefulWidget {
  final VoidCallback onConfirm;

  const EmergencyFAB({super.key, required this.onConfirm});

  @override
  State<EmergencyFAB> createState() => _EmergencyFABState();
}

class _EmergencyFABState extends State<EmergencyFAB>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 1.0, end: 1.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressed() {
    HapticFeedback.heavyImpact();
    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppColors.neonRed.withOpacity(0.5)),
        ),
        title: Row(
          children: [
            Icon(Icons.emergency, color: AppColors.neonRed, size: 28),
            const SizedBox(width: 12),
            Text(
              'EMERGENCY',
              style: AppTextStyles.headline3().copyWith(
                color: AppColors.neonRed,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.neonRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: AppColors.neonRed, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ALWAYS call 112 first in a life-threatening emergency!',
                      style: AppTextStyles.bodyBold().copyWith(
                        color: AppColors.neonRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Have you already called 112?',
              style: AppTextStyles.body().copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'This app helps you find nearby trained volunteers. It does NOT replace emergency services.',
              style: AppTextStyles.caption()
                  .copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Go Back',
              style: AppTextStyles.button()
                  .copyWith(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(context);
              widget.onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'YES, FIND HELP',
              style: AppTextStyles.button().copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Emergency Quick Trigger',
      button: true,
      hint: 'Tap to find emergency help nearby',
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ---- Pulse rings ----
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => Transform.scale(
                scale: _pulseScale.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonRed
                        .withOpacity(_pulseOpacity.value * 0.6),
                  ),
                ),
              ),
            ),
            // ---- FAB button ----
            GestureDetector(
              onTap: _onPressed,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [Color(0xFFFF4444), AppColors.neonRed],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.neonRed.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
