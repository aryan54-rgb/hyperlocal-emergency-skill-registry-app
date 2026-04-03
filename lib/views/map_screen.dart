import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';
import '../models/volunteer.dart';
import '../viewmodels/map_viewmodel.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _hasFitCamera = false;
  Set<String> _lastMarkerIds = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MapViewModel>().initialize();
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers(MapViewModel viewModel) {
    return viewModel.volunteers
        .where((volunteer) => volunteer.hasLiveLocationAvailable)
        .map((volunteer) {
      final distance = viewModel.getDistanceToVolunteer(volunteer);
      final isEmergencySkilled = viewModel.emergencyVolunteers
          .any((candidate) => candidate.id == volunteer.id);

      return Marker(
        markerId: MarkerId(volunteer.id),
        position: LatLng(volunteer.latitude!, volunteer.longitude!),
        infoWindow: InfoWindow(
          title: volunteer.name,
          snippet: _buildMarkerSnippet(volunteer, distance),
          onTap: () => _showVolunteerDetail(volunteer, distance),
        ),
        icon: isEmergencySkilled
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }).toSet();
  }

  String _buildMarkerSnippet(Volunteer volunteer, double? distance) {
    final skillText =
        volunteer.skills.isNotEmpty ? volunteer.skills.first : 'Volunteer';
    final distanceText = distance != null
        ? '${distance.toStringAsFixed(1)} km away'
        : 'Distance unavailable';
    return '$skillText • $distanceText';
  }

  void _showVolunteerDetail(Volunteer volunteer, double? distance) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _VolunteerDetailSheet(
        volunteer: volunteer,
        distance: distance,
      ),
    );
  }

  void _scheduleCameraFit(Set<Marker> markers, MapViewModel viewModel) {
    final currentIds = markers.map((marker) => marker.markerId.value).toSet();
    final markerSetChanged = currentIds.length != _lastMarkerIds.length ||
        !currentIds.containsAll(_lastMarkerIds);

    if (!_hasFitCamera || markerSetChanged) {
      _lastMarkerIds = currentIds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _fitCameraToPoints(markers, viewModel);
      });
    }
  }

  Future<void> _fitCameraToPoints(
    Set<Marker> markers,
    MapViewModel viewModel,
  ) async {
    final controller = _mapController;
    if (controller == null) return;

    final points = <LatLng>[
      if (viewModel.hasLocation)
        LatLng(viewModel.userLatitude!, viewModel.userLongitude!),
      ...markers.map((marker) => marker.position),
    ];

    if (points.isEmpty) return;

    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 14),
        ),
      );
      _hasFitCamera = true;
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        72,
      ),
    );
    _hasFitCamera = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Live Volunteer Map',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Consumer<MapViewModel>(
        builder: (context, viewModel, _) {
          final markers = _buildMarkers(viewModel);

          if (viewModel.state == MapState.locationPermissionDenied) {
            return _PermissionState(
              message:
                  viewModel.errorMessage ?? 'Enable location to view nearby help.',
              onPressed: viewModel.openLocationSettings,
            );
          }

          if (viewModel.state == MapState.error) {
            return _ErrorState(
              message: viewModel.errorMessage ?? 'Failed to load volunteer map.',
              onRetry: viewModel.refresh,
            );
          }

          if (viewModel.state == MapState.loading && viewModel.volunteers.isEmpty) {
            return const _LoadingState();
          }

          if (viewModel.state == MapState.empty) {
            return _EmptyState(onRefresh: viewModel.refresh);
          }

          if (kIsWeb) {
            return _WebMapFallback(viewModel: viewModel);
          }

          _scheduleCameraFit(markers, viewModel);

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _scheduleCameraFit(markers, viewModel);
                },
                initialCameraPosition: CameraPosition(
                  target: viewModel.hasLocation
                      ? LatLng(viewModel.userLatitude!, viewModel.userLongitude!)
                      : const LatLng(20.5937, 78.9629),
                  zoom: 12,
                ),
                markers: markers,
                myLocationEnabled: viewModel.hasLocation,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: false,
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _MapSummaryBar(viewModel: viewModel),
              ),
              Positioned(
                left: 16,
                right: 88,
                bottom: 16,
                child: _NearestVolunteersCard(viewModel: viewModel),
              ),
              Positioned(
                right: 16,
                bottom: 24,
                child: FloatingActionButton(
                  onPressed: viewModel.isLoading ? null : viewModel.refresh,
                  backgroundColor: AppColors.neonBlue,
                  child: viewModel.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.refresh, color: AppColors.darkBg),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WebMapFallback extends StatelessWidget {
  const _WebMapFallback({required this.viewModel});

  final MapViewModel viewModel;

  Future<void> _openVolunteerInMaps(Volunteer volunteer) async {
    if (volunteer.latitude == null || volunteer.longitude == null) {
      return;
    }

    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${volunteer.latitude},${volunteer.longitude}',
    );
    await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final volunteers = viewModel.getVolunteersSortedByDistance();

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.neonBlue.withOpacity(0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.map_outlined, color: AppColors.neonBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Live map preview is limited on web',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'This browser build does not have the Google Maps JavaScript API configured yet. You can still browse nearby volunteers and open their coordinates in Google Maps.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${volunteers.length} volunteers currently sharing location',
                  style: const TextStyle(
                    color: AppColors.neonBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final volunteer in volunteers)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.glassBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            volunteer.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (viewModel.getDistanceToVolunteer(volunteer) != null)
                          Text(
                            '${viewModel.getDistanceToVolunteer(volunteer)!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: AppColors.neonBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${volunteer.locality}, ${volunteer.city}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: volunteer.skills.take(3).map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.neonBlue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: AppColors.neonBlue,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _openVolunteerInMaps(volunteer),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.neonBlue,
                              foregroundColor: AppColors.darkBg,
                            ),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                      ],
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

class _MapSummaryBar extends StatelessWidget {
  const _MapSummaryBar({required this.viewModel});

  final MapViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final updatedText = viewModel.lastLocationUpdate != null
        ? 'Updated ${TimeOfDay.fromDateTime(viewModel.lastLocationUpdate!).format(context)}'
        : 'Waiting for location';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${viewModel.volunteers.length} volunteers nearby',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.location_on, color: AppColors.neonBlue, size: 18),
              const SizedBox(width: 4),
              const Text(
                'Regular',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.location_on, color: AppColors.neonRed, size: 18),
              const SizedBox(width: 4),
              const Text(
                'Emergency',
                style: TextStyle(color: AppColors.neonRed, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${viewModel.emergencyVolunteers.length} emergency-skilled volunteers • $updatedText',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _NearestVolunteersCard extends StatelessWidget {
  const _NearestVolunteersCard({required this.viewModel});

  final MapViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final volunteers = viewModel.getVolunteersSortedByDistance().take(3).toList();
    if (volunteers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonBlue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nearest volunteers',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (final volunteer in volunteers)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _VolunteerListTile(
                volunteer: volunteer,
                distance: viewModel.getDistanceToVolunteer(volunteer),
              ),
            ),
        ],
      ),
    );
  }
}

class _VolunteerListTile extends StatelessWidget {
  const _VolunteerListTile({
    required this.volunteer,
    required this.distance,
  });

  final Volunteer volunteer;
  final double? distance;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.neonBlue.withOpacity(0.85),
                AppColors.neonBlue.withOpacity(0.35),
              ],
            ),
          ),
          child: Center(
            child: Text(
              volunteer.initials,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                volunteer.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                distance != null
                    ? '${distance!.toStringAsFixed(1)} km • ${volunteer.primarySkill}'
                    : volunteer.primarySkill,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonBlue),
          ),
          SizedBox(height: 18),
          Text(
            'Loading live volunteer map...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionState extends StatelessWidget {
  const _PermissionState({
    required this.message,
    required this.onPressed,
  });

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessageCard(
      icon: Icons.location_off,
      title: 'Location Permission Required',
      message: message,
      actionLabel: 'Open Settings',
      onPressed: onPressed,
      accentColor: AppColors.neonRed,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessageCard(
      icon: Icons.error_outline,
      title: 'Unable to Load the Map',
      message: message,
      actionLabel: 'Retry',
      onPressed: onRetry,
      accentColor: AppColors.neonRed,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _CenteredMessageCard(
      icon: Icons.map_outlined,
      title: 'No Volunteers Sharing Live Location',
      message: 'No volunteers sharing live location.',
      actionLabel: 'Refresh',
      onPressed: onRefresh,
      accentColor: AppColors.neonBlue,
    );
  }
}

class _CenteredMessageCard extends StatelessWidget {
  const _CenteredMessageCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 54),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: AppColors.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolunteerDetailSheet extends StatelessWidget {
  const _VolunteerDetailSheet({
    required this.volunteer,
    this.distance,
  });

  final Volunteer volunteer;
  final double? distance;

  Future<void> _contactVolunteer() async {
    final uri = Uri(scheme: 'tel', path: volunteer.phone);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withOpacity(0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.neonBlue.withOpacity(0.25)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.neonBlue.withOpacity(0.8),
                          AppColors.neonBlue.withOpacity(0.35),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        volunteer.initials,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          distance != null
                              ? '${distance!.toStringAsFixed(1)} km away'
                              : volunteer.locality,
                          style: const TextStyle(
                            color: AppColors.neonBlue,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Skills',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: volunteer.skills.map((skill) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.neonBlue.withOpacity(0.25),
                      ),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _DetailMetric(
                      label: 'Availability',
                      value: volunteer.availability,
                    ),
                  ),
                  Expanded(
                    child: _DetailMetric(
                      label: 'Location',
                      value:
                          '${volunteer.locality}, ${volunteer.city}'.trim(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await _contactVolunteer();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    foregroundColor: AppColors.darkBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text(
                    'Contact Volunteer',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
