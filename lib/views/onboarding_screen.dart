// ============================================================
// ONBOARDING SCREEN - 3 cinematic slides, shown on first launch
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../core/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ---- Slide content ----
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      headline: 'Emergency Response\nTakes 8–12 Minutes',
      subtext:
          'The average ambulance response time in most cities. That\'s a long time when every second counts.',
      stat: '8–12',
      statLabel: 'MINUTES',
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF1A0830)],
      accentColor: AppColors.neonRed,
      icon: Icons.timer_outlined,
    ),
    _OnboardingSlide(
      headline: 'Brain Damage\nBegins in 4',
      subtext:
          'After just 4 minutes without oxygen, irreversible brain damage begins. The gap between arrival and injury is deadly.',
      stat: '4',
      statLabel: 'MINUTES',
      gradientColors: [Color(0xFF1A0505), Color(0xFF0D1B2A)],
      accentColor: AppColors.neonOrange,
      icon: Icons.psychology_outlined,
    ),
    _OnboardingSlide(
      headline: 'Your Neighbour\nCould Save a Life',
      subtext:
          'Trained volunteers nearby can bridge the critical gap. Register your skills. Find help instantly. Save lives.',
      stat: '<90',
      statLabel: 'SECOND MATCH',
      gradientColors: [Color(0xFF051520), Color(0xFF050A1A)],
      accentColor: AppColors.neonGreen,
      icon: Icons.people_outline,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingCompletedKey, true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // ---- Page view ----
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) =>
                _OnboardingPage(slide: _slides[index]),
          ),

          // ---- Bottom controls ----
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                28,
                20,
                28,
                MediaQuery.of(context).padding.bottom + 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.darkBg.withOpacity(0.95),
                  ],
                ),
              ),
              child: Row(
                children: [
                  // ---- Skip button ----
                  GestureDetector(
                    onTap: _completeOnboarding,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Skip',
                        style: AppTextStyles.body()
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // ---- Page indicators ----
                  Row(
                    children: List.generate(_slides.length, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? _slides[_currentPage].accentColor
                              : AppColors.textMuted.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _slides[_currentPage]
                                        .accentColor
                                        .withOpacity(0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : [],
                        ),
                      );
                    }),
                  ),

                  const Spacer(),

                  // ---- Next / Get Started button ----
                  GestureDetector(
                    onTap: _nextPage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 12),
                      decoration: BoxDecoration(
                        color: _slides[_currentPage].accentColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _slides[_currentPage]
                                .accentColor
                                .withOpacity(0.4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next →',
                        style: AppTextStyles.button().copyWith(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Individual slide ----
class _OnboardingPage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _OnboardingPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // ---- Giant icon ----
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accentColor.withOpacity(0.15),
                    border: Border.all(
                      color: slide.accentColor.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(slide.icon, color: slide.accentColor, size: 44),
                ),
              ),

              const SizedBox(height: 40),

              // ---- Giant stat ----
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: ShaderMask(
                  shaderCallback: (bounds) => RadialGradient(
                    colors: [slide.accentColor, slide.accentColor.withOpacity(0.6)],
                  ).createShader(bounds),
                  child: Text(
                    slide.stat,
                    style: AppTextStyles.displayHero().copyWith(
                      fontSize: 88,
                      color: Colors.white,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              FadeSlideIn(
                delay: const Duration(milliseconds: 250),
                child: Text(
                  slide.statLabel,
                  style: AppTextStyles.caption().copyWith(
                    color: slide.accentColor,
                    letterSpacing: 4,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 44),

              // ---- Headline ----
              FadeSlideIn(
                delay: const Duration(milliseconds: 350),
                child: Text(
                  slide.headline,
                  style: AppTextStyles.headline1().copyWith(fontSize: 30),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16),

              // ---- Subtext ----
              FadeSlideIn(
                delay: const Duration(milliseconds: 450),
                child: Text(
                  slide.subtext,
                  style: AppTextStyles.body(),
                  textAlign: TextAlign.center,
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Slide data model ----
class _OnboardingSlide {
  final String headline;
  final String subtext;
  final String stat;
  final String statLabel;
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData icon;

  const _OnboardingSlide({
    required this.headline,
    required this.subtext,
    required this.stat,
    required this.statLabel,
    required this.gradientColors,
    required this.accentColor,
    required this.icon,
  });
}
