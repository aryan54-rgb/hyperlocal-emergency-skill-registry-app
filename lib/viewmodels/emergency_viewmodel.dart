// ============================================================
// EMERGENCY VIEWMODEL - Smart one-tap emergency matching
// ============================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/location_service.dart';
import '../models/request_models.dart';
import '../models/volunteer.dart';

enum EmergencyState { idle, gettingLocation, matching, success, empty, error }

/// Priority-based responder sorting & state management
class EmergencyViewModel extends ChangeNotifier {
  EmergencyState _state = EmergencyState.idle;
  List<Volunteer> _responders = [];
  String? _errorMessage;
  LocationErrorType? _locationErrorType;
  
  String? _selectedEmergencyType;
  double? _userLatitude;
  double? _userLongitude;

  // ---- Getters ----
  EmergencyState get state => _state;
  List<Volunteer> get responders => _responders;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == EmergencyState.gettingLocation || 
                        _state == EmergencyState.matching;
  bool get hasLocation => _userLatitude != null && _userLongitude != null;
  String? get selectedEmergencyType => _selectedEmergencyType;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  
  /// Check if error is due to location permission issue
  bool get isLocationPermissionError =>
      _locationErrorType == LocationErrorType.permissionDenied ||
      _locationErrorType == LocationErrorType.permissionDeniedForever;

  /// Check if error is recoverable with retry
  bool get canRetry => _state == EmergencyState.error;

  /// Set selected emergency type
  void setEmergencyType(String type) {
    if (AppConstants.emergencyTypes.contains(type)) {
      _selectedEmergencyType = type;
      notifyListeners();
    }
  }

  /// Main entry point: Submit emergency request
  /// 1. Get location from device
  /// 2. Call emergency matching API
  /// 3. Sort results by priority
  Future<void> submitEmergencyRequest() async {
    if (_selectedEmergencyType == null) {
      _setError('Please select an emergency type', ApiErrorType.validation);
      return;
    }

    // ---- Step 1: Get Location ----
    _state = EmergencyState.gettingLocation;
    _errorMessage = null;
    notifyListeners();

    final locResult = await LocationService.instance.getCurrentLocation();
    if (locResult.isFailure) {
      _locationErrorType = locResult.errorType;
      _setError(
        LocationService.getErrorMessage(_locationErrorType),
        ApiErrorType.network,
      );
      return;
    }

    _userLatitude = locResult.location!.latitude;
    _userLongitude = locResult.location!.longitude;

    // ---- Step 2: Call Emergency Matching API ----
    _state = EmergencyState.matching;
    notifyListeners();

    final matchRequest = EmergencyMatchRequest(
      latitude: _userLatitude!,
      longitude: _userLongitude!,
      emergencyType: _selectedEmergencyType!,
      radiusKm: AppConstants.emergencyMatchDefaultRadiusKm,
    );

    final result = await ApiService.instance.emergencyMatch(matchRequest);

    if (result.isFailure) {
      _setError(result.error, result.errorType);
      return;
    }

    // ---- Step 3: Sort Responders by Priority ----
    _responders = _sortRespondersByPriority(result.data!.responders);
    _state = _responders.isEmpty ? EmergencyState.empty : EmergencyState.success;
    notifyListeners();
  }

  /// Sort responders based on priority rules:
  /// 1. Active status (active volunteers first)
  /// 2. Availability priority (Always > Now > Later > Offline)
  /// 3. Distance (nearest first)
  List<Volunteer> _sortRespondersByPriority(List<Volunteer> volunteers) {
    final sorted = [...volunteers];

    sorted.sort((a, b) {
      // 1. Active status (active = higher priority)
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }

      // 2. Availability priority
      final aPriority = _getAvailabilityPriority(a.availability);
      final bPriority = _getAvailabilityPriority(b.availability);
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }

      // 3. Distance (nearest first)
      final aDistance = a.distanceKm ?? double.maxFinite;
      final bDistance = b.distanceKm ?? double.maxFinite;
      return aDistance.compareTo(bDistance);
    });

    return sorted;
  }

  /// Get numeric priority for availability status
  /// Lower number = higher priority (sorts first)
  int _getAvailabilityPriority(String availability) {
    switch (availability.toLowerCase()) {
      case 'available_now':
      case 'available now':
        return 1; // Highest priority
      case 'within_30_min':
      case 'within 30 minutes':
        return 2;
      case 'available':
        return 3;
      case 'busy':
      case 'offline':
        return 4; // Lowest priority
      default:
        return 5;
    }
  }

  /// Retry the last emergency request
  Future<void> retry() async {
    if (_selectedEmergencyType == null) {
      _setError('No emergency type selected', ApiErrorType.validation);
      return;
    }
    await submitEmergencyRequest();
  }

  /// Reset all state
  void reset() {
    _state = EmergencyState.idle;
    _responders = [];
    _errorMessage = null;
    _locationErrorType = null;
    _selectedEmergencyType = null;
    _userLatitude = null;
    _userLongitude = null;
    notifyListeners();
  }

  /// Helper to set error state
  void _setError(String? message, ApiErrorType? type) {
    _state = EmergencyState.error;
    _errorMessage = message;
    _responders = [];
    notifyListeners();
  }

  /// Get top N responders (for UI display limits)
  List<Volunteer> getTopResponders(int limit) {
    return responders.take(limit).toList();
  }
}
