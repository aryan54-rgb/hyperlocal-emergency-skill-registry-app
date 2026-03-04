// ============================================================
// SEARCH SCREEN - Find emergency volunteers nearby
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/animations.dart';
import '../core/constants.dart';
import '../models/volunteer.dart';
import '../viewmodels/search_viewmodel.dart';
import '../widgets/animated_button.dart';
import '../widgets/glowing_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _localityCtrl = TextEditingController();

  @override
  void dispose() {
    _localityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SearchViewModel(),
      child: Consumer<SearchViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.darkBg,
            appBar: AppBar(
              title: const Text('FIND EMERGENCY HELP'),
              backgroundColor: Colors.transparent,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: Column(
              children: [
                // ---- Search Form ----
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                    border: const Border(
                      bottom: BorderSide(color: AppColors.darkDivider),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ---- Disclaimer ----
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.neonRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.neonRed.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.emergency,
                                color: AppColors.neonRed, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Call 112 first for life-threatening emergencies!',
                                style: AppTextStyles.caption().copyWith(
                                  color: AppColors.neonRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---- Locality field ----
                      TextField(
                        controller: _localityCtrl,
                        onChanged: (v) => vm.locality = v,
                        style: AppTextStyles.body()
                            .copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Your Locality / Neighbourhood',
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: AppColors.textMuted, size: 20),
                          filled: true,
                          fillColor: AppColors.darkCard,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.darkDivider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: AppColors.darkDivider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.neonBlue, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ---- Emergency type dropdown ----
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkDivider),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: vm.emergencyType.isEmpty
                                ? null
                                : vm.emergencyType,
                            hint: Text(
                              'Select Required Skill',
                              style: AppTextStyles.body()
                                  .copyWith(color: AppColors.textMuted),
                            ),
                            isExpanded: true,
                            dropdownColor: AppColors.darkCard,
                            style: AppTextStyles.body()
                                .copyWith(color: AppColors.textPrimary),
                            icon: const Icon(Icons.keyboard_arrow_down,
                                color: AppColors.textMuted),
                            items: AppConstants.availableSkills.map((t) {
                              return DropdownMenuItem(
                                  value: t, child: Text(t));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) vm.setEmergencyType(v);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- Search button ----
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedGradientButton(
                          label: 'FIND VOLUNTEERS',
                          icon: Icons.search_rounded,
                          isLoading: vm.isLoading,
                          colors: const [
                            AppColors.neonBlue,
                            AppColors.neonPurple
                          ],
                          onPressed: (vm.isLoading ||
                                  vm.locality.trim().isEmpty ||
                                  vm.emergencyType.isEmpty)
                              ? null
                              : vm.search,
                        ),
                      ),
                    ],
                  ),
                ),

                // ---- Results ----
                Expanded(
                  child: _SearchResults(vm: vm),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---- Search results area ----
class _SearchResults extends StatelessWidget {
  final SearchViewModel vm;

  const _SearchResults({required this.vm});

  @override
  Widget build(BuildContext context) {
    switch (vm.state) {
      case SearchState.idle:
        return _IdleState();

      case SearchState.loading:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.neonBlue),
              SizedBox(height: 16),
              Text(
                'Searching nearby volunteers...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        );

      case SearchState.empty:
        return _EmptyState(vm: vm);

      case SearchState.error:
        return _ErrorState(vm: vm);

      case SearchState.success:
        return _VolunteerList(volunteers: vm.volunteers);
    }
  }
}

class _IdleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded,
              size: 64, color: AppColors.textMuted.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Enter your locality and\nemergency type to search',
            style: AppTextStyles.body(),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final SearchViewModel vm;

  const _EmptyState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ---- Animated illustration ----
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Icon(
              Icons.person_search_rounded,
              size: 80,
              color: AppColors.neonOrange.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No volunteers found nearby',
            style: AppTextStyles.headline3(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No trained volunteers were found in "${vm.locality}" for this emergency type. Try a wider area or different emergency type.',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          OutlinedAnimatedButton(
            label: 'TRY AGAIN',
            icon: Icons.refresh,
            color: AppColors.neonOrange,
            onPressed: vm.search,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final SearchViewModel vm;

  const _ErrorState({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, v, child) =>
                  Opacity(opacity: v, child: child),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: AppColors.neonRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something Went Wrong',
              style: AppTextStyles.headline3(),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'An unexpected error occurred.',
              style: AppTextStyles.body(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AnimatedGradientButton(
              label: 'RETRY',
              icon: Icons.refresh_rounded,
              colors: [AppColors.neonRed, AppColors.neonOrange],
              onPressed: vm.search,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Volunteer results list ----
class _VolunteerList extends StatelessWidget {
  final List<Volunteer> volunteers;

  const _VolunteerList({required this.volunteers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            '${volunteers.length} VOLUNTEER${volunteers.length != 1 ? 'S' : ''} FOUND',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.neonGreen,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: volunteers.length,
            itemBuilder: (context, index) {
              return FadeSlideIn(
                delay: AppAnimations.stagger(index),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _VolunteerCard(volunteer: volunteers[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---- Volunteer card ----
class _VolunteerCard extends StatelessWidget {
  final Volunteer volunteer;

  const _VolunteerCard({required this.volunteer});

  @override
  Widget build(BuildContext context) {
    return GlowingCard(
      glowColors: [AppColors.neonBlue, AppColors.neonCyan],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Avatar ----
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.blue,
            ),
            child: Center(
              child: Text(
                volunteer.initials,
                style: AppTextStyles.bodyBold().copyWith(fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // ---- Info ----
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(volunteer.name, style: AppTextStyles.bodyBold()),
                const SizedBox(height: 4),
                // Skills
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: volunteer.skills.take(3).map((s) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.neonBlue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.neonBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        s,
                        style: AppTextStyles.caption()
                            .copyWith(color: AppColors.neonCyan, fontSize: 10),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.textMuted, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      volunteer.locality,
                      style: AppTextStyles.caption(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ---- Call button ----
          Column(
            children: [
              Semantics(
                label: 'Call ${volunteer.name}',
                button: true,
                child: GestureDetector(
                  onTap: () {
                    // Show phone number
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: AppColors.darkSurface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text('Contact ${volunteer.name}',
                            style: AppTextStyles.headline3()),
                        content: Row(
                          children: [
                            const Icon(Icons.phone,
                                color: AppColors.neonGreen),
                            const SizedBox(width: 10),
                            Text(volunteer.phone,
                                style: AppTextStyles.headline3().copyWith(
                                  color: AppColors.neonGreen,
                                  fontSize: 20,
                                )),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppGradients.success,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.neonGreen.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.phone, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: volunteer.isActive
                      ? AppColors.neonGreen.withOpacity(0.15)
                      : AppColors.textMuted.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  volunteer.isActive ? 'ACTIVE' : 'BUSY',
                  style: AppTextStyles.caption().copyWith(
                    color: volunteer.isActive
                        ? AppColors.neonGreen
                        : AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
