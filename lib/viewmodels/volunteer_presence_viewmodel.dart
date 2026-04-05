import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/location_service.dart';

class VolunteerPresenceViewModel extends ChangeNotifier {
  String? _volunteerId;
  String? _volunteerName;
  String _availability = 'available_now';
  bool _isLocationSharingEnabled = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  String? get volunteerId => _volunteerId;
  String? get volunteerName => _volunteerName;
  String get availability => _availability;
  bool get isLocationSharingEnabled => _isLocationSharingEnabled;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  bool get hasVolunteerProfile =>
      _volunteerId != null && _volunteerId!.trim().isNotEmpty;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _volunteerId = prefs.getString(AppConstants.volunteerIdKey);
    _availability = prefs.getString(AppConstants.volunteerAvailabilityKey) ??
        'available_now';
    _isLocationSharingEnabled =
        prefs.getBool(AppConstants.volunteerLocationSharingKey) ?? false;

    if (hasVolunteerProfile) {
      final result =
          await ApiService.instance.fetchVolunteerProfile(volunteerId: _volunteerId!);
      if (result.isSuccess) {
        final data = result.data!;
        _volunteerName = data['name']?.toString();
        _availability = data['availability']?.toString() ?? _availability;
        _isLocationSharingEnabled =
            data['is_location_shared'] as bool? ?? _isLocationSharingEnabled;
        await _persistLocalState();
      } else {
        _errorMessage = result.error;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateAvailability(String nextAvailability) async {
    if (!hasVolunteerProfile || _isSaving) {
      return;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    final shouldShareLocation = nextAvailability != 'busy';
    final updateResult = await ApiService.instance.updateVolunteerAvailability(
      volunteerId: _volunteerId!,
      availability: nextAvailability,
      isLocationShared: shouldShareLocation,
    );

    if (updateResult.isFailure) {
      _isSaving = false;
      _errorMessage = updateResult.error;
      notifyListeners();
      return;
    }

    final toggleResult = await ApiService.instance.toggleLocationSharing(
      volunteerId: _volunteerId!,
      isLocationShared: shouldShareLocation,
    );

    if (toggleResult.isFailure) {
      _isSaving = false;
      _errorMessage = toggleResult.error;
      notifyListeners();
      return;
    }

    if (shouldShareLocation) {
      final locationResult = await LocationService.instance.getCurrentLocation();
      if (locationResult.isSuccess) {
        await ApiService.instance.updateVolunteerLocation(
          volunteerId: _volunteerId!,
          latitude: locationResult.location!.latitude,
          longitude: locationResult.location!.longitude,
        );
      } else {
        _errorMessage = LocationService.getErrorMessage(locationResult.errorType);
      }
    }

    _availability = nextAvailability;
    _isLocationSharingEnabled = shouldShareLocation;
    await _persistLocalState();

    _isSaving = false;
    notifyListeners();
  }

  Future<void> _persistLocalState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.volunteerAvailabilityKey, _availability);
    await prefs.setBool(
      AppConstants.volunteerLocationSharingKey,
      _isLocationSharingEnabled,
    );
  }
}
