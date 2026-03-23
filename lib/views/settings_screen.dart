// ============================================================
// SETTINGS SCREEN - Accessibility + preferences + about
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../viewmodels/app_settings_viewmodel.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppSettingsViewModel>();

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- Appearance ----
          const FadeSlideIn(
            child: _SettingsSectionHeader(
                label: 'APPEARANCE', icon: Icons.palette_outlined),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme across the app',
                  value: vm.isDarkMode,
                  onChanged: vm.setDarkMode,
                  color: AppColors.neonPurple,
                ),
                const _CardDivider(),
                _ToggleTile(
                  icon: Icons.contrast_outlined,
                  title: 'High Contrast',
                  subtitle: 'Increase contrast for readability',
                  value: vm.highContrast,
                  onChanged: vm.setHighContrast,
                  color: AppColors.neonCyan,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---- Accessibility ----
          const FadeSlideIn(
            delay: Duration(milliseconds: 140),
            child: _SettingsSectionHeader(
                label: 'ACCESSIBILITY', icon: Icons.accessibility_new_rounded),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _SettingsCard(
              children: [
                _ToggleTile(
                  icon: Icons.format_size_rounded,
                  title: 'Large Text',
                  subtitle: 'Increase text size throughout the app',
                  value: vm.largeText,
                  onChanged: vm.setLargeText,
                  color: AppColors.neonGreen,
                ),
                const _CardDivider(),
                _ToggleTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Receive emergency alerts (demo)',
                  value: vm.notificationsEnabled,
                  onChanged: vm.setNotifications,
                  color: AppColors.neonOrange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ---- About ----
          const FadeSlideIn(
            delay: Duration(milliseconds: 240),
            child: _SettingsSectionHeader(
                label: 'ABOUT', icon: Icons.info_outline_rounded),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
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
                            child: const Icon(Icons.emergency,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppConstants.appName,
                                style: AppTextStyles.bodyBold(),
                              ),
                              Text(
                                'v${AppConstants.appVersion}',
                                style: AppTextStyles.caption(),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A hyperlocal emergency skill registry connecting trained volunteers with people in need during the critical 5–10 minute window before professional help arrives.',
                        style: AppTextStyles.body().copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ---- Team ----
          const FadeSlideIn(
            delay: Duration(milliseconds: 320),
            child: _SettingsSectionHeader(
                label: 'TEAM', icon: Icons.group_outlined),
          ),
          const SizedBox(height: 12),

          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: _SettingsCard(
              children: Column(
                children: AppConstants.teamMembers.asMap().entries.map((entry) {
                  final i = entry.key;
                  final member = entry.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _gradientForIndex(i),
                              ),
                              child: Center(
                                child: Text(
                                  member['name']!
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join(),
                                  style: AppTextStyles.caption().copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(member['name']!,
                                    style: AppTextStyles.bodyBold()
                                        .copyWith(fontSize: 14)),
                                Text(
                                  member['role']!,
                                  style: AppTextStyles.caption().copyWith(
                                    color: _colorForIndex(i),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (i < AppConstants.teamMembers.length - 1)
                        const _CardDivider(),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // ---- Footer ----
          FadeSlideIn(
            delay: const Duration(milliseconds: 400),
            child: Center(
              child: Column(
                children: [
                  Text(
                    AppConstants.teamName,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built to save lives',
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.neonRed.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static LinearGradient _gradientForIndex(int i) {
    const gradients = [
      AppGradients.primary,
      AppGradients.blue,
      AppGradients.success,
      AppGradients.warning,
    ];
    return gradients[i % gradients.length];
  }

  static Color _colorForIndex(int i) {
    const colors = [
      AppColors.neonRed,
      AppColors.neonBlue,
      AppColors.neonGreen,
      AppColors.neonOrange,
    ];
    return colors[i % colors.length];
  }
}

// ---- Sub-components ----

class _SettingsSectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SettingsSectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonBlue, size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.neonBlue,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final dynamic children; // Widget or List<Widget>

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkDivider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: children is Widget ? children : Column(children: children as List<Widget>),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$title toggle, ${value ? 'on' : 'off'}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold().copyWith(fontSize: 14)),
                  Text(subtitle, style: AppTextStyles.caption()),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        color: AppColors.darkDivider,
        indent: 16,
        endIndent: 16,
      );
}
