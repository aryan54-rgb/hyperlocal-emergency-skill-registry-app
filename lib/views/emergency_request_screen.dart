// ============================================================
// EMERGENCY REQUEST SCREEN - Fast, panic-friendly interface
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import '../core/location_service.dart';
import '../viewmodels/emergency_viewmodel.dart';
import '../models/volunteer.dart';
import '../widgets/animated_button.dart';
import '../widgets/responder_card.dart';
import '../widgets/emergency_loading_indicator.dart';
import '../widgets/animated_results_card.dart';

class EmergencyRequestScreen extends StatefulWidget {
  const EmergencyRequestScreen({super.key});

  @override
  State<EmergencyRequestScreen> createState() => _EmergencyRequestScreenState();
}

class _EmergencyRequestScreenState extends State<EmergencyRequestScreen> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EmergencyViewModel(),
      child: Consumer<EmergencyViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.darkBg,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Header ----
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppGradients.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.emergency,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'EMERGENCY HELP',
                              style: AppTextStyles.headline2().copyWith(
                                color: AppColors.neonRed,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: AppColors.textSecondary),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ---- Warning Banner ----
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.neonRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.neonRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone,
                                color: AppColors.neonRed, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Call 112 first for life-threatening emergencies.',
                                style: AppTextStyles.bodyBold().copyWith(
                                  color: AppColors.neonRed,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ---- Safety Disclaimer ----
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: AppColors.darkDivider),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'This app supports civic response and does not replace ambulance, police, or fire services.',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ---- Emergency Type Selection ----
                      Text(
                        'What type of help do you need?',
                        style: AppTextStyles.headline3()
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),

                      // Emergency type buttons grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: AppConstants.emergencyTypes.length,
                        itemBuilder: (context, index) {
                          final emergencyType =
                              AppConstants.emergencyTypes[index];
                          final isSelected =
                              vm.selectedEmergencyType == emergencyType;
                          final metadata =
                              AppConstants.getEmergencyMetadata(emergencyType);

                          return _EmergencyTypeCard(
                            type: emergencyType,
                            icon: metadata['icon'] ?? 'help',
                            isSelected: isSelected,
                            onTap: () => vm.setEmergencyType(emergencyType),
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // ---- Location Status ----
                      if (vm.hasLocation)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.neonBlue.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.neonBlue, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Location detected',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.neonBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ---- Main CTA Button + Loading State ----
                      if (vm.state == EmergencyState.idle)
                        SizedBox(
                          width: double.infinity,
                          child: AnimatedGradientButton(
                            label: 'FIND NEARBY HELP',
                            icon: Icons.location_on_outlined,
                            isLoading: false,
                            colors: const [
                              AppColors.neonRed,
                              Color(0xFFFF6B00),
                            ],
                            onPressed: vm.selectedEmergencyType == null
                                ? null
                                : vm.submitEmergencyRequest,
                            semanticLabel: 'Find nearby volunteer responders based on your emergency type and location',
                          ),
                        )
                      else if (vm.isLoading)
                        EmergencyLoadingIndicator(
                          message: vm.state == EmergencyState.gettingLocation
                              ? 'Getting your location...'
                              : 'Finding nearby help...',
                        ),

                      // ---- Error State ----
                      if (vm.state == EmergencyState.error)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.neonRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.neonRed.withOpacity(0.3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppColors.neonRed,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Could not find help',
                                          style: AppTextStyles.bodyBold()
                                              .copyWith(
                                            color: AppColors.neonRed,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    vm.errorMessage ??
                                        'An error occurred. Please try again.',
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // ---- Permission Error Actions ----
                            if (vm.isLocationPermissionError)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.settings),
                                  label: const Text('OPEN SETTINGS'),
                                  onPressed: () {
                                    LocationService.instance
                                        .openLocationSettings();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonBlue,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              )
                            else
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('TRY AGAIN'),
                                  onPressed: vm.retry,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neonRed,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),

                      // ---- Empty State ----
                      if (vm.state == EmergencyState.empty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.darkCard,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 48,
                                    color: AppColors.textMuted.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No volunteers nearby',
                                    style: AppTextStyles.headline3()
                                        .copyWith(color: AppColors.textSecondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No one is available in your area right now. Call 112 for emergency services or try a different help type.',
                                    style: AppTextStyles.caption().copyWith(
                                      color: AppColors.textMuted,
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.phone),
                                    label: const Text('CALL 112'),
                                    onPressed: () async {
                                      // Call emergency number
                                      final uri = Uri(scheme: 'tel', path: '112');
                                      if (await canLaunchUrl(uri)) {
                                        await launchUrl(uri);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.neonRed,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('TRY AGAIN'),
                                    onPressed: vm.retry,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.neonBlue,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                      // ---- Results Section ----
                      if (vm.state == EmergencyState.success)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedResultCard(
                              child: Text(
                                'Responders near you (sorted by priority)',
                                style: AppTextStyles.headline3()
                                    .copyWith(color: AppColors.textPrimary),
                                semanticsLabel: 'Results sorted by active status, availability, and distance',
                              ),
                            ),
                            const SizedBox(height: 16),
                            _RespondersList(
                              responders: vm.getTopResponders(5),
                              animated: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Emergency type selection card
class _EmergencyTypeCard extends StatelessWidget {
  final String type;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmergencyTypeCard({
    required this.type,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.neonRed.withOpacity(0.2)
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.neonRed
                : AppColors.darkDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconData(icon),
              size: 32,
              color: isSelected ? AppColors.neonRed : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                type,
                textAlign: TextAlign.center,
                style: AppTextStyles.button().copyWith(
                  color: isSelected
                      ? AppColors.neonRed
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'medical_services': Icons.medical_services_outlined,
      'local_fire_department': Icons.local_fire_department_outlined,
      'directions_car': Icons.directions_car_outlined,
      'security': Icons.security_outlined,
      'accessibility': Icons.accessibility_outlined,
      'help': Icons.help_outline,
    };
    return iconMap[iconName] ?? Icons.help_outline;
  }
}

/// Responders list with optional animation for demo polish
class _RespondersList extends StatelessWidget {
  final List<Volunteer> responders;
  final bool animated;

  const _RespondersList({
    required this.responders,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final listWidget = RespondersList(responders: responders);

    if (!animated) {
      return listWidget;
    }

    // Build individual responder cards with staggered animation
    if (responders.isEmpty) {
      return listWidget;
    }

    return AnimatedResultsList(
      staggerDuration: const Duration(milliseconds: 100),
      children: List.generate(
        responders.length,
        (index) {
          final responder = responders[index];
          return ResponderCard(
            responder: responder,
            rankBadge: _getRankBadge(index),
            semanticsLabel:
                'Responder ${index + 1}: ${responder.name}, ${responder.distanceKm?.toStringAsFixed(1) ?? "?"} km away',
          );
        },
      ),
    );
  }

  String? _getRankBadge(int index) {
    const badges = ['#1', '#2', '#3'];
    return index < badges.length ? badges[index] : null;
  }
}
