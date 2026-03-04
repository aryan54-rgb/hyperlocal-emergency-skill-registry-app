// ============================================================
// DASHBOARD SCREEN - Impact metrics with animated counters
// ============================================================

import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../models/response_models.dart';
import '../widgets/animated_stat_counter.dart';
import '../widgets/glowing_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Using mock data — replace with API call if backend implements a stats endpoint
    final stats = DashboardStats.mock;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('IMPACT DASHBOARD'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AnimatedGradientBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ---- Hero banner ----
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.neonRed.withOpacity(0.2),
                      AppColors.neonPurple.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.neonRed.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppGradients.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.favorite_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LIVES TOUCHED',
                              style: AppTextStyles.caption().copyWith(
                                color: AppColors.neonRed,
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              'Emergency Registry Impact',
                              style: AppTextStyles.headline3(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatCounterTile(
                            value: stats.totalMatches,
                            suffix: '+',
                            label: 'Emergency\nMatches',
                            gradient: [AppColors.neonRed, AppColors.neonPink],
                          ),
                        ),
                        Expanded(
                          child: StatCounterTile(
                            value: stats.totalVolunteers,
                            suffix: '+',
                            label: 'Volunteers\nRegistered',
                            gradient: [AppColors.neonPurple, AppColors.neonBlue],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ---- Stat cards grid ----
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: Row(
                children: [
                  Expanded(
                    child: GradientStatCard(
                      title: 'RESPONSE TIME',
                      statWidget: ShaderMask(
                        shaderCallback: (bounds) => AppGradients.blue
                            .createShader(bounds),
                        child: Text(
                          stats.avgResponseTime,
                          style: AppTextStyles.statNumber()
                              .copyWith(color: Colors.white, fontSize: 28),
                        ),
                      ),
                      subtitle: 'Avg. volunteer arrival',
                      colors: [AppColors.neonBlue, AppColors.neonCyan],
                      icon: Icons.timer_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientStatCard(
                      title: 'ACTIVE NEARBY',
                      statWidget: AnimatedStatCounter(
                        end: stats.activeNearby,
                        style: AppTextStyles.statNumber()
                            .copyWith(fontSize: 28),
                      ),
                      subtitle: 'Volunteers available now',
                      colors: [AppColors.neonGreen, AppColors.neonCyan],
                      icon: Icons.people_outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            FadeSlideIn(
              delay: const Duration(milliseconds: 180),
              child: Row(
                children: [
                  Expanded(
                    child: GradientStatCard(
                      title: 'CITIES COVERED',
                      statWidget: AnimatedStatCounter(
                        end: stats.citiesCovered,
                        style: AppTextStyles.statNumber()
                            .copyWith(fontSize: 28),
                      ),
                      subtitle: 'Across the country',
                      colors: [AppColors.neonOrange, AppColors.neonRed],
                      icon: Icons.location_city_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GradientStatCard(
                      title: 'SKILL TYPES',
                      statWidget: ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.warning.createShader(bounds),
                        child: Text(
                          '14+',
                          style: AppTextStyles.statNumber()
                              .copyWith(color: Colors.white, fontSize: 28),
                        ),
                      ),
                      subtitle: 'Emergency specialisations',
                      colors: [AppColors.neonPink, AppColors.neonPurple],
                      icon: Icons.stars_outlined,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---- Progress section ----
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: Text(
                'COVERAGE PROGRESS',
                style: AppTextStyles.caption().copyWith(
                  letterSpacing: 2,
                  color: AppColors.neonBlue,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ..._progressItems.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return FadeSlideIn(
                delay: AppAnimations.stagger(i + 3, baseMs: 60),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProgressBar(
                    label: item['label'] as String,
                    value: item['value'] as double,
                    color: item['color'] as Color,
                    suffix: item['suffix'] as String,
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ---- About section ----
            FadeSlideIn(
              delay: const Duration(milliseconds: 500),
              child: GlowingCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOW IT WORKS',
                      style: AppTextStyles.caption().copyWith(
                        letterSpacing: 2,
                        color: AppColors.neonPurple,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._howItWorks.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: AppGradients.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    item['step'] as String,
                                    style: AppTextStyles.caption().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'] as String,
                                      style: AppTextStyles.bodyBold()
                                          .copyWith(fontSize: 14),
                                    ),
                                    Text(
                                      item['desc'] as String,
                                      style: AppTextStyles.caption(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _progressItems = [
    {
      'label': 'North Zone Coverage',
      'value': 0.78,
      'color': AppColors.neonBlue,
      'suffix': '78%',
    },
    {
      'label': 'South Zone Coverage',
      'value': 0.62,
      'color': AppColors.neonGreen,
      'suffix': '62%',
    },
    {
      'label': 'East Zone Coverage',
      'value': 0.45,
      'color': AppColors.neonOrange,
      'suffix': '45%',
    },
    {
      'label': 'West Zone Coverage',
      'value': 0.55,
      'color': AppColors.neonPurple,
      'suffix': '55%',
    },
  ];

  static const List<Map<String, String>> _howItWorks = [
    {
      'step': '1',
      'title': 'Volunteers Register',
      'desc': 'Trained individuals register their skills and location.',
    },
    {
      'step': '2',
      'title': 'Emergency Occurs',
      'desc': 'User enters locality and emergency type.',
    },
    {
      'step': '3',
      'title': 'Instant Match',
      'desc': 'System finds trained volunteers within <90 seconds.',
    },
    {
      'step': '4',
      'title': 'Help Arrives',
      'desc': 'Volunteer reaches victim within the critical 5–10 min window.',
    },
  ];
}

// ---- Animated progress bar ----
class _ProgressBar extends StatefulWidget {
  final String label;
  final double value;
  final Color color;
  final String suffix;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
    required this.suffix,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.label, style: AppTextStyles.body().copyWith(fontSize: 13)),
            Text(
              widget.suffix,
              style: AppTextStyles.caption()
                  .copyWith(color: widget.color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Stack(
            children: [
              // Track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.darkDivider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Fill
              FractionallySizedBox(
                widthFactor: _anim.value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [widget.color, widget.color.withOpacity(0.6)]),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
