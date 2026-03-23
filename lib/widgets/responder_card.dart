// ============================================================
// RESPONDER CARD - Displays individual volunteer/responder info
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../models/volunteer.dart';

class ResponderCard extends StatelessWidget {
  final Volunteer responder;
  final int rank; // Position in list (1st, 2nd, etc) - optional
  final String? rankBadge; // Custom badge text (e.g. "#1", "#2")
  final String? semanticsLabel; // Accessibility label

  const ResponderCard({
    super.key,
    required this.responder,
    this.rank = 0,
    this.rankBadge,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final distance = responder.distanceKm;
    final distanceText = distance != null
        ? '${distance.toStringAsFixed(1)} km away'
        : 'Distance unknown';

    final cardWidget = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _getRankBorderColor(),
          width: rank > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header: Name, Badge, Distance ----
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar (Initials)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppGradients.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    responder.initials,
                    style: AppTextStyles.headline3()
                        .copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            responder.name,
                            style: AppTextStyles.bodyBold()
                                .copyWith(color: AppColors.textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (rank > 0 || rankBadge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRankColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              rankBadge ?? '#$rank',
                              style: AppTextStyles.caption().copyWith(
                                color: _getRankColor(),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: AppTextStyles.caption()
                              .copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Active Status Badge
              if (responder.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: AppTextStyles.caption().copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // ---- Location Info ----
          if (responder.locality.isNotEmpty)
            Row(
              children: [
                Icon(Icons.place_outlined,
                    size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    responder.locality,
                    style: AppTextStyles.caption()
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 10),

          // ---- Skills ----
          if (responder.skills.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: responder.skills.take(3).map((skill) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neonBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.neonBlue.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    skill,
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.neonBlue,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 10),

          // ---- Availability ----
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.darkBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  _formatAvailability(responder.availability),
                  style: AppTextStyles.caption()
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ---- Action Buttons ----
          Row(
            children: [
              // Call Button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone_outlined, size: 18),
                  label: const Text('CALL'),
                  onPressed: () => _launchCall(responder.phone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // WhatsApp Button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('WHATSAPP'),
                  onPressed: () => _launchWhatsApp(responder.phone),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Wrap with Semantics if label provided for accessibility
    if (semanticsLabel != null) {
      return Semantics(
        label: semanticsLabel,
        child: cardWidget,
      );
    }
    return cardWidget;
  }

  /// Get border color based on rank position
  Color _getRankBorderColor() {
    // Check if rankBadge is provided first
    if (rankBadge != null) {
      if (rankBadge == '#1') return const Color(0xFFFFD700);
      if (rankBadge == '#2') return const Color(0xFFC0C0C0);
      if (rankBadge == '#3') return const Color(0xFFCD7F32);
    }
    
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.darkDivider;
    }
  }

  /// Get rank badge color
  Color _getRankColor() {
    // Check if rankBadge is provided first
    if (rankBadge != null) {
      if (rankBadge == '#1') return const Color(0xFFFFD700);
      if (rankBadge == '#2') return const Color(0xFFC0C0C0);
      if (rankBadge == '#3') return const Color(0xFFCD7F32);
    }
    
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  /// Format availability status for display
  String _formatAvailability(String availability) {
    switch (availability.toLowerCase()) {
      case 'available_now':
      case 'available now':
        return 'Available Now';
      case 'within_30_min':
      case 'within 30 minutes':
        return 'Within 30m';
      case 'available':
        return 'Available';
      case 'busy':
        return 'Busy';
      case 'offline':
        return 'Offline';
      default:
        return availability;
    }
  }

  /// Launch phone call
  Future<void> _launchCall(String phone) async {
    final sanitizedPhone = _sanitizePhone(phone);
    final uri = Uri(scheme: 'tel', path: sanitizedPhone);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // Error logged internally
    }
  }

  /// Launch WhatsApp chat
  Future<void> _launchWhatsApp(String phone) async {
    final sanitizedPhone = _sanitizePhone(phone);
    final message = 'Hi! I need emergency assistance for a ${_getEmergencyTypeDisplay()}';

    try {
      final waLink = Uri.parse(
        'https://wa.me/$sanitizedPhone?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(waLink)) {
        await launchUrl(waLink, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to WhatsApp URI scheme
        final fallbackUri = Uri.parse('whatsapp://send?phone=$sanitizedPhone&text=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(fallbackUri)) {
          await launchUrl(fallbackUri);
        }
      }
    } catch (e) {
      // Error logged internally
    }
  }

  /// Sanitize phone number: remove all non-digits, ensure format is valid
  String _sanitizePhone(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // Ensure Indian format (10 digits or 91 + 10 digits)
    if (digits.length == 10) {
      digits = '91$digits'; // Add country code for India
    } else if (digits.length == 12 && digits.startsWith('91')) {
      // Already has country code, keep as is
    }

    return digits;
  }

  /// Placeholder for emergency type display - can be passed as parameter if needed
  String _getEmergencyTypeDisplay() {
    return 'emergency';
  }
}

/// Also export a list view widget for displaying multiple responders
class RespondersList extends StatelessWidget {
  final List<Volunteer> responders;
  final bool showRanks;

  const RespondersList({
    super.key,
    required this.responders,
    this.showRanks = true,
  });

  @override
  Widget build(BuildContext context) {
    if (responders.isEmpty) {
      return Center(
        child: Text(
          'No responders found',
          style: AppTextStyles.caption()
              .copyWith(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: responders.length,
      itemBuilder: (context, index) {
        return ResponderCard(
          responder: responders[index],
          rank: showRanks ? index + 1 : 0,
        );
      },
    );
  }
}
