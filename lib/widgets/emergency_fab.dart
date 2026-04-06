// ============================================================
// EMERGENCY FAB - Floating red pulsing emergency trigger button
// Shows nearest available volunteers on tap
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/api_service.dart';
import '../core/location_service.dart';
import '../models/volunteer.dart';
import 'responder_card.dart';

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
            const Icon(Icons.emergency, color: AppColors.neonRed, size: 28),
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
                  const Icon(Icons.phone, color: AppColors.neonRed, size: 20),
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
              _findAndShowNearbyVolunteers();
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

  /// Get the user's location, fetch nearby volunteers, calculate distances,
  /// filter for available ones, sort by distance, and show in a bottom sheet.
  Future<void> _findAndShowNearbyVolunteers() async {
    if (!mounted) return;

    // Show loading bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (sheetContext) => _NearbyVolunteersSheet(
        onFullEmergencyTap: widget.onConfirm,
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

// ==========================================================================
// NEARBY VOLUNTEERS BOTTOM SHEET - Shows nearest available volunteers
// ==========================================================================

class _NearbyVolunteersSheet extends StatefulWidget {
  final VoidCallback onFullEmergencyTap;

  const _NearbyVolunteersSheet({required this.onFullEmergencyTap});

  @override
  State<_NearbyVolunteersSheet> createState() => _NearbyVolunteersSheetState();
}

class _NearbyVolunteersSheetState extends State<_NearbyVolunteersSheet>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<Volunteer> _nearbyVolunteers = [];
  double? _userLat;
  double? _userLng;

  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _loadNearbyVolunteers();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbyVolunteers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Step 1: Get user's current location
    final locResult = await LocationService.instance.getCurrentLocation();

    if (!mounted) return;

    if (locResult.isFailure) {
      // Fallback: use a default location (Bangalore)
      _userLat = 12.9716;
      _userLng = 77.5946;
    } else {
      _userLat = locResult.location!.latitude;
      _userLng = locResult.location!.longitude;
    }

    // Step 2: Fetch REAL volunteers from the Supabase database
    final result = await ApiService.instance.fetchVolunteersWithLocation(
      userLatitude: _userLat,
      userLongitude: _userLng,
    );

    if (!mounted) return;

    if (result.isFailure) {
      setState(() {
        _isLoading = false;
        _errorMessage = result.error ?? 'Failed to load volunteers from the database.';
      });
      return;
    }

    final allVolunteers = result.data ?? [];

    // Step 3: Calculate distance for each volunteer using Haversine formula
    final volunteersWithDistance = allVolunteers.map((v) {
      final distance = _calculateDistanceKm(
        _userLat!,
        _userLng!,
        v.latitude ?? _userLat!,
        v.longitude ?? _userLng!,
      );
      return Volunteer(
        id: v.id,
        name: v.name,
        phone: v.phone,
        locality: v.locality,
        city: v.city,
        state: v.state,
        skills: v.skills,
        availability: v.availability,
        consentGiven: v.consentGiven,
        latitude: v.latitude,
        longitude: v.longitude,
        lastUpdated: v.lastUpdated,
        distanceKm: distance,
        isLocationShared: v.isLocationShared,
      );
    }).toList();

    // Step 4: Filter only available volunteers (not busy/offline)
    final availableVolunteers = volunteersWithDistance.where((v) {
      final avail = v.availability.toLowerCase();
      return avail != 'busy' && avail != 'offline';
    }).toList();

    // Step 5: Sort by distance (nearest first)
    availableVolunteers.sort((a, b) {
      final da = a.distanceKm ?? double.maxFinite;
      final db = b.distanceKm ?? double.maxFinite;
      return da.compareTo(db);
    });

    if (!mounted) return;

    setState(() {
      _nearbyVolunteers = availableVolunteers;
      _isLoading = false;
      if (availableVolunteers.isEmpty) {
        _errorMessage = 'No available volunteers found nearby in the database.';
      }
    });
  }

  /// Haversine formula to calculate distance between two GPS coordinates
  double _calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.darkBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Drag handle ----
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ---- Header ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.neonRed, Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonRed.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEARBY VOLUNTEERS',
                        style: AppTextStyles.headline3().copyWith(
                          color: AppColors.neonRed,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isLoading
                            ? 'Scanning your area...'
                            : '${_nearbyVolunteers.length} available near you',
                        style: AppTextStyles.caption().copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.darkDivider, height: 1),

          // ---- Content ----
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null && _nearbyVolunteers.isEmpty)
            _buildEmptyState()
          else
            _buildVolunteerList(),

          // ---- Footer: Full Emergency Request link ----
          Padding(
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomPadding + 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('OPEN FULL EMERGENCY REQUEST'),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onFullEmergencyTap();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.neonBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: AppColors.neonBlue.withOpacity(0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          // Pulsing location icon
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              final scale = 1.0 + (_shimmerController.value * 0.15);
              final opacity = 0.5 + (_shimmerController.value * 0.5);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.neonRed.withOpacity(0.15),
                    border: Border.all(
                      color: AppColors.neonRed.withOpacity(opacity * 0.4),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.my_location,
                    color: AppColors.neonRed.withOpacity(opacity),
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Locating nearby volunteers...',
            style: AppTextStyles.bodyBold().copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Getting your GPS position and scanning the area',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Skeleton cards
          ...List.generate(3, (i) => _buildSkeletonCard()),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, _) {
        final shimmerOpacity = 0.04 + (_shimmerController.value * 0.06);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.darkCard.withOpacity(shimmerOpacity * 10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkDivider),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppColors.textMuted.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No volunteers nearby',
            style: AppTextStyles.headline3().copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No available volunteers were found in your area. Try the full emergency request for more options.',
            style: AppTextStyles.caption().copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerList() {
    return Flexible(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        shrinkWrap: true,
        itemCount: _nearbyVolunteers.length,
        itemBuilder: (context, index) {
          final volunteer = _nearbyVolunteers[index];
          final rankBadges = ['#1', '#2', '#3'];
          return ResponderCard(
            responder: volunteer,
            rankBadge: index < rankBadges.length ? rankBadges[index] : null,
            semanticsLabel:
                'Volunteer ${index + 1}: ${volunteer.name}, ${volunteer.distanceKm?.toStringAsFixed(1) ?? "?"} km away',
          );
        },
      ),
    );
  }
}
