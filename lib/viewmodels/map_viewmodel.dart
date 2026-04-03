// ============================================================
// MAP VIEWMODEL - Live volunteer location tracking
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/location_service.dart';
import '../models/volunteer.dart';

enum MapState { idle, loading, success, empty, error, locationPermissionDenied }

/// MapViewModel manages live volunteer location display
/// - Fetches volunteers with location sharing enabled
/// - Calculates distances from user
/// - Handles periodic location updates (polling)
/// - Manages location permissions
class MapViewModel extends ChangeNotifier {
  MapViewModel();

  // ---- State ----
  MapState _state = MapState.idle;
  List<Volunteer> _volunteers = [];
  String? _errorMessage;
  LocationErrorType? _locationErrorType;
  bool _isInitialized = false;
  String? _currentVolunteerId;
  bool _isLocationSharingEnabled = false;

  // ---- Location tracking ----
  double? _userLatitude;
  double? _userLongitude;
  DateTime? _lastLocationUpdate;

  // ---- Timer for periodic updates ----
  Timer? _locationUpdateTimer;
  static const Duration _defaultUpdateInterval = Duration(seconds: 45);

  // ---- Getters ----
  MapState get state => _state;
  List<Volunteer> get volunteers => _volunteers;
  String? get errorMessage => _errorMessage;
  
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  String? get currentVolunteerId => _currentVolunteerId;

  bool get isLoading => _state == MapState.loading;
  bool get hasError => _state == MapState.error;
  bool get hasLocationPermissionError =>
      _state == MapState.locationPermissionDenied;
  bool get hasLocation => _userLatitude != null && _userLongitude != null;
  bool get isEmpty => _state == MapState.empty;

  /// Get volunteers highlighted (emergency-skilled)
  /// Emergency skills: Medical, Fire, Emergency, First Aid, etc.
  List<Volunteer> get emergencyVolunteers => _volunteers
      .where((v) =>
          v.skills.any((skill) =>
              ['medical', 'fire', 'emergency', 'first aid', 'cardiac', 'rescue']
                  .any((keyword) =>
                      skill.toLowerCase().contains(keyword.toLowerCase()))))
      .toList();

  /// Calculate distance from user to volunteer
  double? getDistanceToVolunteer(Volunteer volunteer) {
    if (!hasLocation || volunteer.latitude == null || volunteer.longitude == null) {
      return null;
    }
    return LocationService.calculateDistance(
      _userLatitude!,
      _userLongitude!,
      volunteer.latitude!,
      volunteer.longitude!,
    );
  }

  /// Sort volunteers by distance
  List<Volunteer> getVolunteersSortedByDistance() {
    final sorted = [..._volunteers];
    sorted.sort((a, b) {
      final distA = getDistanceToVolunteer(a) ?? double.infinity;
      final distB = getDistanceToVolunteer(b) ?? double.infinity;
      return distA.compareTo(distB);
    });
    return sorted;
  }

  /// Initialize map view
  /// 1. Request location permission
  /// 2. Get current user location
  /// 3. Fetch volunteers with location
  /// 4. Start periodic update timer
  Future<void> initialize() async {
    if (_isInitialized) return;
    _currentVolunteerId = await _loadStoredVolunteerId();
    _isLocationSharingEnabled = await _loadLocationSharingStatus();
    await loadVolunteers();
    _startLocationUpdateTimer();
    _isInitialized = true;
  }

  /// Load volunteers with location sharing enabled
  Future<void> loadVolunteers() async {
    // Get user location first
    await _fetchUserLocation(setLoadingState: _volunteers.isEmpty);

    if (_state == MapState.locationPermissionDenied) {
      return;
    }

    _state = MapState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.instance.fetchVolunteersWithLocation(
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
    );

    if (result.isFailure) {
      _setError(result.error ?? 'Failed to load volunteers');
      return;
    }

    _volunteers = (result.data ?? [])
        .where((volunteer) => volunteer.hasLiveLocationAvailable)
        .toList();

    if (_volunteers.isEmpty) {
      _state = MapState.empty;
    } else {
      _state = MapState.success;
    }
    notifyListeners();
  }

  /// Refresh volunteers location data
  Future<void> refresh() async {
    await loadVolunteers();
  }

  /// Set user location manually (for testing/override)
  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    notifyListeners();
  }

  /// Fetch current user location
  Future<void> _fetchUserLocation({bool setLoadingState = true}) async {
    final previousState = _state;
    if (setLoadingState) {
      _state = MapState.loading;
      notifyListeners();
    }

    final result = await LocationService.instance.getCurrentLocation();

    if (result.isFailure) {
      _locationErrorType = result.errorType;
      _state = result.errorType == LocationErrorType.permissionDenied ||
              result.errorType == LocationErrorType.permissionDeniedForever
          ? MapState.locationPermissionDenied
          : MapState.error;
      _errorMessage = LocationService.getErrorMessage(_locationErrorType);
      notifyListeners();
      return;
    }

    _userLatitude = result.location!.latitude;
    _userLongitude = result.location!.longitude;
    _lastLocationUpdate = DateTime.now();
    if (!setLoadingState && previousState != MapState.loading) {
      _state = previousState;
    }

    if (_isLocationSharingEnabled &&
        _currentVolunteerId != null &&
        _currentVolunteerId!.isNotEmpty) {
      unawaited(updateMyLocation(_currentVolunteerId!));
    }
  }

  /// Update user location to backend (broadcast current location)
  Future<void> updateMyLocation(String volunteerId) async {
    if (!hasLocation) {
      // Try to get location if not already fetched
      await _fetchUserLocation();
    }

    if (!hasLocation) {
      return;
    }

    _currentVolunteerId = volunteerId;
    _isLocationSharingEnabled = true;
    await ApiService.instance.updateVolunteerLocation(
      volunteerId: volunteerId,
      latitude: _userLatitude!,
      longitude: _userLongitude!,
    );
  }

  /// Start timer for periodic location updates (polling)
  void _startLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(_defaultUpdateInterval, (_) async {
      await _fetchUserLocation(setLoadingState: false);
      final result = await ApiService.instance.fetchVolunteersWithLocation(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );
      if (result.isSuccess) {
        _volunteers = (result.data ?? [])
            .where((volunteer) => volunteer.hasLiveLocationAvailable)
            .toList();
        _state = _volunteers.isEmpty ? MapState.empty : MapState.success;
      }
      notifyListeners(); // Refresh to update distances
    });
  }

  /// Stop the timer
  void _stopLocationUpdateTimer() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = null;
  }

  /// Open location settings (if permission was denied)
  Future<void> openLocationSettings() async {
    await LocationService.instance.openLocationSettings();
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopLocationUpdateTimer();
    super.dispose();
  }

  // ---- Private Helpers ----

  void _setError(String message) {
    _state = MapState.error;
    _errorMessage = message;
    notifyListeners();
  }

  Future<String?> _loadStoredVolunteerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.volunteerIdKey);
  }

  Future<bool> _loadLocationSharingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.volunteerLocationSharingKey) ?? false;
  }
}
