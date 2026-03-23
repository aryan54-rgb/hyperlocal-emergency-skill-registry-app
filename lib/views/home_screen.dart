// ============================================================
// HOME SCREEN - Full-screen immersive hero with animated stats
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_stat_counter.dart';
import '../widgets/emergency_fab.dart';
import '../widgets/support_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // ---- Headline typing animation controller ----
  late AnimationController _headlineController;
  late Animation<int> _charCount;

  static const String _headline = 'HELP IS CLOSER\nTHAN YOU THINK';

  @override
  void initState() {
    super.initState();
    _headlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _charCount = IntTween(begin: 0, end: _headline.length).animate(
      CurvedAnimation(parent: _headlineController, curve: Curves.easeOut),
    );
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _headlineController.forward();
    });
  }

  @override
  void dispose() {
    _headlineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: AnimatedGradientBackground(
        child: Stack(
          children: [
            // ---- Glow orb decorations ----
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonRed.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.neonBlue.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ---- Main content ----
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.only(
                  top: safeTop + 20,
                  left: 24,
                  right: 24,
                  bottom: safeBottom + 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ---- Top bar ----
                    FadeSlideIn(
                      child: Row(
                        children: [
                          // App logo mark
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.emergency,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'EMERGENCY REGISTRY',
                            style: AppTextStyles.caption().copyWith(
                              letterSpacing: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined,
                                color: AppColors.textSecondary),
                            onPressed: () => Navigator.pushNamed(context, '/settings'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ---- Hero Headline (typewriter) ----
                    AnimatedBuilder(
                      animation: _charCount,
                      builder: (context, _) {
                        return ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                            colors: [
                              Colors.white,
                              AppColors.textSecondary,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ).createShader(bounds),
                          child: Text(
                            _headline.substring(0, _charCount.value),
                            style: AppTextStyles.displayHero().copyWith(
                              color: Colors.white,
                              fontSize: 38,
                              shadows: [
                                Shadow(
                                  color: AppColors.neonRed.withOpacity(0.3),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // ---- Subheading ----
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 900),
                      child: Text(
                        'Trained neighbours. Critical 5–10 minutes. Real impact.',
                        style: AppTextStyles.body().copyWith(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // ---- Stat Counters ----
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            StatCounterTile(
                              value: 2400,
                              suffix: '+',
                              label: 'Volunteers',
                              gradient: [AppColors.neonRed, AppColors.neonPink],
                            ),
                            _VerticalDivider(),
                            StatCounterTile(
                              value: 90,
                              prefix: '<',
                              suffix: 's',
                              label: 'Response',
                              gradient: [AppColors.neonBlue, AppColors.neonCyan],
                            ),
                            _VerticalDivider(),
                            StatCounterTile(
                              value: 38,
                              label: 'Cities',
                              gradient: [AppColors.neonGreen, AppColors.neonCyan],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ---- Primary CTA: Register ----
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 700),
                      child: SizedBox(
                        width: double.infinity,
                        child: AnimatedGradientButton(
                          label: 'REGISTER AS VOLUNTEER',
                          icon: Icons.person_add_outlined,
                          colors: const [AppColors.neonRed, AppColors.neonPurple],
                          onPressed: () =>
                              Navigator.pushNamed(context, '/register'),
                          semanticLabel: 'Register as a volunteer',
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ---- Secondary CTA: Find Help ----
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 800),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedAnimatedButton(
                          label: 'FIND EMERGENCY HELP',
                          icon: Icons.search_outlined,
                          color: AppColors.neonBlue,
                          onPressed: () =>
                              Navigator.pushNamed(context, '/search'),
                        ),
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ---- Impact Dashboard Link ----
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 950),
                      child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/dashboard'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.neonGreen.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.bar_chart_rounded,
                                  color: AppColors.neonGreen,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Impact Dashboard',
                                      style: AppTextStyles.bodyBold(),
                                    ),
                                    Text(
                                      'See how we\'re making a difference',
                                      style: AppTextStyles.caption(),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ---- Floating Emergency FAB ----
            Positioned(
              bottom: safeBottom + 24,
              right: 24,
              child: EmergencyFAB(
                onConfirm: () => Navigator.pushNamed(context, '/emergency-request'),
              ),
            ),

            // ---- Floating Support Button ----
            Positioned(
              bottom: safeBottom + 24,
              left: 24,
              child: _SupportFAB(),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 44,
        color: AppColors.darkDivider,
      );
}

class _SupportFAB extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => SupportModal.show(context),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkCard,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(
              color: AppColors.neonBlue.withOpacity(0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: const Icon(
          Icons.help_outline,
          color: AppColors.neonBlue,
          size: 22,
        ),
      ),
    );
  }
}
