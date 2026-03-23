// ============================================================
// REGISTER SCREEN - Volunteer registration with full validation
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../core/location_service.dart';
import '../viewmodels/register_viewmodel.dart';
import '../widgets/animated_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late ConfettiController _confetti;

  // Text controllers for form fields
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 4));
  }

  @override
  void dispose() {
    _confetti.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _localityCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(RegisterViewModel vm) async {
    // Sync auto-filled location from viewmodel to text controllers
    if (vm.locality.isNotEmpty && _localityCtrl.text.isEmpty) {
      _localityCtrl.text = vm.locality;
    }
    if (vm.city.isNotEmpty && _cityCtrl.text.isEmpty) {
      _cityCtrl.text = vm.city;
    }
    if (vm.selectedState.isNotEmpty && _stateCtrl.text.isEmpty) {
      _stateCtrl.text = vm.selectedState;
    }

    // Sync all controller values to VM
    vm.name = _nameCtrl.text;
    vm.phone = _phoneCtrl.text;
    vm.email = _emailCtrl.text;
    vm.locality = _localityCtrl.text;
    vm.city = _cityCtrl.text;
    vm.selectedState = _stateCtrl.text;

    await vm.register();

    if (vm.state == RegisterState.success) {
      _confetti.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterViewModel(),
      child: Consumer<RegisterViewModel>(
        builder: (context, vm, _) {
          // Sync auto-filled location to text controllers in real-time
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (vm.locality.isNotEmpty && _localityCtrl.text.isEmpty) {
              _localityCtrl.text = vm.locality;
            }
            if (vm.city.isNotEmpty && _cityCtrl.text.isEmpty) {
              _cityCtrl.text = vm.city;
            }
            if (vm.selectedState.isNotEmpty && _stateCtrl.text.isEmpty) {
              _stateCtrl.text = vm.selectedState;
            }
          });

          // Show success overlay
          if (vm.state == RegisterState.success) {
            return _SuccessScreen(
              confetti: _confetti,
              onReset: () {
                vm.reset();
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _emailCtrl.clear();
                _localityCtrl.clear();
                _cityCtrl.clear();
                _stateCtrl.clear();
              },
            );
          }

          return Scaffold(
            backgroundColor: AppColors.darkBg,
            appBar: AppBar(
              title: const Text('REGISTER AS VOLUNTEER'),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Stack(
              children: [
                ShakeWidget(
                  shake: vm.shakeForm,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        // ---- Section: Personal Info ----
                        const FadeSlideIn(
                          child: _SectionLabel(
                              label: 'PERSONAL INFORMATION',
                              icon: Icons.person_outline),
                        ),
                        const SizedBox(height: 12),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 80),
                          child: _GlowTextField(
                            controller: _nameCtrl,
                            label: 'Full Name *',
                            icon: Icons.badge_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 120),
                          child: _GlowTextField(
                            controller: _phoneCtrl,
                            label: 'Phone Number *',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Phone is required';
                              }
                              if (v.trim().length < 8) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 160),
                          child: _GlowTextField(
                            controller: _emailCtrl,
                            label: 'Email (Optional)',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ---- Section: Location ----
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 200),
                          child: _SectionLabel(
                              label: 'LOCATION',
                              icon: Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 12),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 220),
                          child: _GlowTextField(
                            controller: _localityCtrl,
                            label: 'Locality / Neighbourhood *',
                            icon: Icons.map_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Locality is required'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ---- Auto-fill Location Button ----
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 230),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                            child: AnimatedGradientButton(
                              label: vm.isGettingLocation
                                  ? 'GETTING YOUR LOCATION...'
                                  : 'USE MY CURRENT LOCATION',
                              icon: Icons.my_location_outlined,
                              isLoading: vm.isGettingLocation,
                              colors: const [AppColors.neonBlue, Color(0xFF00A8FF)],
                              onPressed: vm.isGettingLocation ? null : () => vm.autoFillLocationFromGPS(),
                              semanticLabel: 'Auto-fill location fields using GPS coordinates',
                            ),
                          ),
                        ),

                        // ---- Location Error Message ----
                        if (vm.locationErrorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: FadeSlideIn(
                              delay: const Duration(milliseconds: 240),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.neonRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppColors.neonRed.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppColors.neonRed,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        vm.locationErrorMessage!,
                                        style: AppTextStyles.caption().copyWith(
                                          color: AppColors.neonRed,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    if (vm.locationPermissionError)
                                      GestureDetector(
                                        onTap: () => LocationService.instance.openLocationSettings(),
                                        child: Padding(
                                          padding: const EdgeInsets.only(left: 8),
                                          child: Text(
                                            'Settings',
                                            style: AppTextStyles.caption().copyWith(
                                              color: AppColors.neonBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: FadeSlideIn(
                                delay: const Duration(milliseconds: 240),
                                child: _GlowTextField(
                                  controller: _cityCtrl,
                                  label: 'City *',
                                  icon: Icons.location_city_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: FadeSlideIn(
                                delay: const Duration(milliseconds: 260),
                                child: _GlowTextField(
                                  controller: _stateCtrl,
                                  label: 'State *',
                                  icon: Icons.flag_outlined,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // ---- Section: Skills ----
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 280),
                          child: _SectionLabel(
                              label: 'SKILLS & TRAINING',
                              icon: Icons.stars_outlined),
                        ),
                        const SizedBox(height: 6),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 290),
                          child: Text(
                            'Select all that apply *',
                            style: AppTextStyles.caption(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 300),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AppConstants.availableSkills.map((skill) {
                              final isSelected =
                                  vm.selectedSkills.contains(skill);
                              return GestureDetector(
                                onTap: () => vm.toggleSkill(skill),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? AppGradients.primary
                                        : null,
                                    color:
                                        isSelected ? null : AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.neonRed
                                          : AppColors.darkDivider,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.neonRed
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Text(
                                    skill,
                                    style: AppTextStyles.caption().copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ---- Section: Availability ----
                        const FadeSlideIn(
                          delay: Duration(milliseconds: 360),
                          child: _SectionLabel(
                              label: 'AVAILABILITY',
                              icon: Icons.schedule_outlined),
                        ),
                        const SizedBox(height: 12),

                        FadeSlideIn(
                          delay: const Duration(milliseconds: 380),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.darkSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.darkDivider),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: vm.availability.isEmpty
                                    ? null
                                    : vm.availability,
                                hint: Text(
                                  'Select availability *',
                                  style: AppTextStyles.body().copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                isExpanded: true,
                                dropdownColor: AppColors.darkSurface,
                                style: AppTextStyles.body()
                                    .copyWith(color: AppColors.textPrimary),
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.textMuted),
                                items: AppConstants.availabilityOptions.map((option) {
                                  return DropdownMenuItem<String>(
                                    value: option['value'],
                                    child: Text(option['label']!),
                                  );
                                }).toList(),

                                onChanged: (v) {
                                  if (v != null) vm.setAvailability(v);
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ---- Consent ----
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 400),
                          child: GestureDetector(
                            onTap: () => vm.setConsent(!vm.consentGiven),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: vm.consentGiven
                                    ? AppColors.neonGreen.withOpacity(0.08)
                                    : AppColors.darkCard,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: vm.consentGiven
                                      ? AppColors.neonGreen.withOpacity(0.4)
                                      : AppColors.darkDivider,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: vm.consentGiven,
                                    onChanged: (v) => vm.setConsent(v ?? false),
                                    activeColor: AppColors.neonGreen,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'I consent to having my information shared with people searching for emergency help in my area. I understand this is a voluntary service and NOT a replacement for calling 112.',
                                      style: AppTextStyles.body()
                                          .copyWith(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ---- Error message ----
                        if (vm.state == RegisterState.error)
                          FadeSlideIn(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.neonRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppColors.neonRed.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppColors.neonRed, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      vm.errorMessage ?? 'An error occurred.',
                                      style: AppTextStyles.body()
                                          .copyWith(color: AppColors.neonRed),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // ---- Submit button ----
                        FadeSlideIn(
                          delay: const Duration(milliseconds: 440),
                          child: SizedBox(
                            width: double.infinity,
                            child: AnimatedGradientButton(
                              label: 'REGISTER NOW',
                              icon: Icons.check_circle_outline,
                              isLoading: vm.isLoading,
                              onPressed:
                                  vm.isLoading ? null : () => _submit(vm),
                              width: double.infinity,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---- Success Screen ----
class _SuccessScreen extends StatelessWidget {
  final ConfettiController confetti;
  final VoidCallback onReset;

  const _SuccessScreen({required this.confetti, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          // ---- Confetti ----
          ConfettiWidget(
            confettiController: confetti,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              AppColors.neonRed,
              AppColors.neonGreen,
              AppColors.neonBlue,
              AppColors.neonCyan,
              AppColors.neonPurple,
              Colors.white,
            ],
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.1,
          ),

          // ---- Content ----
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleFadeIn(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppGradients.success,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonGreen.withOpacity(0.4),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 56),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'YOU\'RE REGISTERED!',
                      style: AppTextStyles.headline1().copyWith(fontSize: 28),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'You are now part of the emergency response network. Someone nearby may need your skill one day — and you\'ll be ready.',
                      style: AppTextStyles.body(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 500),
                    child: AnimatedGradientButton(
                      label: 'BACK TO HOME',
                      icon: Icons.home_outlined,
                      colors: AppGradients.success.colors,
                      onPressed: () => Navigator.popUntil(
                          context, ModalRoute.withName('/home')),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 580),
                    child: OutlinedAnimatedButton(
                      label: 'REGISTER ANOTHER',
                      color: AppColors.neonBlue,
                      onPressed: onReset,
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

// ---- Glow text field ----
class _GlowTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final bool obscureText = false;

  const _GlowTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  @override
  State<_GlowTextField> createState() => _GlowTextFieldState();
}

class _GlowTextFieldState extends State<_GlowTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: AppColors.neonBlue.withOpacity(0.3),
                    blurRadius: 14,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          obscureText: widget.obscureText,
          style: AppTextStyles.body().copyWith(color: AppColors.textPrimary),
          validator: widget.validator,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(
              widget.icon,
              color: _focused ? AppColors.neonBlue : AppColors.textMuted,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Section label ----
class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.neonRed, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColors.neonRed,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
