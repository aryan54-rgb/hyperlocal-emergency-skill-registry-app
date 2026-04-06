// ============================================================
// MAP VIEWMODEL - Real-time live volunteer location tracking
// ============================================================
// Architecture:
//   OUTBOUND: GPS position stream → Supabase (my location)
//   INBOUND:  Supabase Realtime stream → Map markers (others)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/location_service.dart';
import '../models/volunteer.dart';

enum MapState { idle, loading, success, empty, error, locationPermissionDenied }

/// MapViewModel manages the real-time live volunteer map.
///
/// Two concurrent streams power the map:
/// 1. **GPS stream** (outbound): Continuously tracks the user's position
///    and pushes updates to Supabase so other users see them move.
/// 2. **Realtime stream** (inbound): Subscribes to Supabase Realtime
///    so volunteer markers update instantly when anyone moves.
///
/// A fallback polling timer fires every 10s if no Realtime event
/// has been received in the last 15s (network resilience).
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

  // ---- Live tracking state ----
  bool _isLive = false;
  DateTime? _lastRealtimeEvent;

  // ---- Stream subscriptions ----
  StreamSubscription<LocationResult>? _gpsSubscription;
  StreamSubscription<List<Volunteer>>? _realtimeSubscription;
  Timer? _fallbackPollTimer;
  DateTime? _lastSupabasePush;

  // ---- Configuration ----
  static const Duration _minPushInterval = Duration(seconds: 5);
  static const Duration _fallbackPollInterval = Duration(seconds: 10);
  static const Duration _realtimeStaleThreshold = Duration(seconds: 15);

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

  /// Whether the map is currently receiving real-time updates.
  bool get isLive => _isLive;

  /// Timestamp of the last Realtime/stream event received.
  DateTime? get lastRealtimeEvent => _lastRealtimeEvent;

  /// Get volunteers with emergency-related skills.
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

  // ============================================================
  // INITIALIZATION
  // ============================================================

  /// Initialize the live map:
  /// 1. Load stored volunteer ID and preferences
  /// 2. Get initial user location (one-shot)
  /// 3. Start GPS position stream (outbound)
  /// 4. Start Supabase Realtime stream (inbound)
  /// 5. Start fallback polling timer
  Future<void> initialize() async {
    if (_isInitialized) return;

    _state = MapState.loading;
    notifyListeners();

    _currentVolunteerId = await _loadStoredVolunteerId();
    _isLocationSharingEnabled = await _loadLocationSharingStatus();

    // Get initial position (one-shot, best effort)
    await _fetchUserLocationOnce();

    // Start all live streams
    _startGpsStream();
    _startRealtimeSubscription();
    _startFallbackPollTimer();

    _isInitialized = true;
  }

  // ============================================================
  // OUTBOUND: GPS Stream → Supabase
  // ============================================================

  /// Start continuous GPS position tracking.
  /// Each new position updates local state and pushes to Supabase.
  void _startGpsStream() {
    _gpsSubscription?.cancel();
    _gpsSubscription = LocationService.instance
        .getPositionStream(distanceFilter: 10)
        .listen(
      (location) {
        _userLatitude = location.latitude;
        _userLongitude = location.longitude;
        _lastLocationUpdate = DateTime.now();
        notifyListeners();

        // Push to Supabase (throttled to max 1 per 5 seconds)
        _pushLocationToSupabase();
      },
      onError: (error) {
        debugPrint('[MapViewModel] GPS stream error: $error');
        // Don't set error state — GPS errors are non-fatal
        // The map still works with Realtime data from other users
      },
    );
  }

  /// Push the current user location to Supabase, throttled.
  void _pushLocationToSupabase() {
    if (!_isLocationSharingEnabled ||
        _currentVolunteerId == null ||
        _currentVolunteerId!.isEmpty ||
        !hasLocation) {
      return;
    }

    // Throttle: Don't push more than once per _minPushInterval
    final now = DateTime.now();
    if (_lastSupabasePush != null &&
        now.difference(_lastSupabasePush!) < _minPushInterval) {
      return;
    }
    _lastSupabasePush = now;

    // Fire-and-forget — don't await, don't block the stream
    ApiService.instance.updateVolunteerLocationDirect(
      volunteerId: _currentVolunteerId!,
      latitude: _userLatitude!,
      longitude: _userLongitude!,
    );
  }

  // ============================================================
  // INBOUND: Supabase Realtime → Map markers
  // ============================================================

  /// Subscribe to Supabase Realtime volunteer location changes.
  /// Each emission replaces the entire volunteer list with fresh data.
  void _startRealtimeSubscription() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = ApiService.instance
        .subscribeToVolunteerLocations(
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
        )
        .listen(
      (volunteers) {
        _volunteers = volunteers
            .where((v) => v.hasValidLocation)
            .toList();

        _isLive = true;
        _lastRealtimeEvent = DateTime.now();

        if (_volunteers.isEmpty) {
          _state = MapState.empty;
        } else {
          _state = MapState.success;
        }
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[MapViewModel] Realtime stream error: $error');
        _isLive = false;
        notifyListeners();
        // Don't set error state — fallback poll will pick up the slack
      },
    );
  }

  // ============================================================
  // FALLBACK POLLING (resilience)
  // ============================================================

  /// Fallback polling timer that fires every 10s BUT only actually
  /// fetches data if no Realtime event was received in the last 15s.
  /// This provides resilience if the WebSocket drops.
  void _startFallbackPollTimer() {
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = Timer.periodic(_fallbackPollInterval, (_) async {
      // Only poll if Realtime seems stale
      if (_lastRealtimeEvent != null &&
          DateTime.now().difference(_lastRealtimeEvent!) < _realtimeStaleThreshold) {
        return; // Realtime is working fine, skip polling
      }

      debugPrint('[MapViewModel] Realtime stale — fallback polling...');
      _isLive = false;
      notifyListeners();

      final result = await ApiService.instance.fetchVolunteersWithLocation(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
      );
      if (result.isSuccess) {
        _volunteers = (result.data ?? [])
            .where((volunteer) => volunteer.hasValidLocation)
            .toList();
        _state = _volunteers.isEmpty ? MapState.empty : MapState.success;
        _lastRealtimeEvent = DateTime.now();
        notifyListeners();
      }
    });
  }

  // ============================================================
  // PUBLIC API
  // ============================================================

  /// Manual refresh — re-fetches data and restarts streams.
  Future<void> refresh() async {
    _state = MapState.loading;
    notifyListeners();

    await _fetchUserLocationOnce();

    // Restart Realtime subscription (reconnects WebSocket)
    _startRealtimeSubscription();

    // Also do an immediate fetch for instant feedback
    final result = await ApiService.instance.fetchVolunteersWithLocation(
      userLatitude: _userLatitude,
      userLongitude: _userLongitude,
    );
    if (result.isSuccess) {
      _volunteers = (result.data ?? [])
          .where((volunteer) => volunteer.hasValidLocation)
          .toList();
      _state = _volunteers.isEmpty ? MapState.empty : MapState.success;
    } else {
      _setError(result.error ?? 'Failed to load volunteers');
    }
    notifyListeners();
  }

  /// Load volunteers (initial fetch, also used as fallback).
  Future<void> loadVolunteers() async {
    await _fetchUserLocationOnce();

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
        .where((volunteer) => volunteer.hasValidLocation)
        .toList();

    if (_volunteers.isEmpty) {
      _state = MapState.empty;
    } else {
      _state = MapState.success;
    }
    notifyListeners();
  }

  /// Set user location manually (for testing/override)
  void setUserLocation(double latitude, double longitude) {
    _userLatitude = latitude;
    _userLongitude = longitude;
    notifyListeners();
  }

  /// Update user location to backend (broadcast current location)
  Future<void> updateMyLocation(String volunteerId) async {
    if (!hasLocation) {
      await _fetchUserLocationOnce();
    }

    if (!hasLocation) return;

    _currentVolunteerId = volunteerId;
    _isLocationSharingEnabled = true;
    await ApiService.instance.updateVolunteerLocationDirect(
      volunteerId: volunteerId,
      latitude: _userLatitude!,
      longitude: _userLongitude!,
    );
  }

  /// Open location settings (if permission was denied)
  Future<void> openLocationSettings() async {
    await LocationService.instance.openLocationSettings();
  }

  // ============================================================
  // LIFECYCLE
  // ============================================================

  /// Pause all streams (call when map screen is not visible)
  void pause() {
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _fallbackPollTimer?.cancel();
    _fallbackPollTimer = null;
    _isLive = false;
  }

  /// Resume all streams (call when map screen becomes visible again)
  void resume() {
    _startGpsStream();
    _startRealtimeSubscription();
    _startFallbackPollTimer();
  }

  @override
  void dispose() {
    pause();
    super.dispose();
  }

  // ============================================================
  // PRIVATE HELPERS
  // ============================================================

  void _setError(String message) {
    _state = MapState.error;
    _errorMessage = message;
    notifyListeners();
  }

  /// One-shot location fetch for initial position.
  Future<void> _fetchUserLocationOnce() async {
    final result = await LocationService.instance.getCurrentLocation();

    if (result.isFailure) {
      _locationErrorType = result.errorType;
      debugPrint(
        '[MapViewModel] Location error: ${LocationService.getErrorMessage(_locationErrorType)}',
      );
      return;
    }

    _userLatitude = result.location!.latitude;
    _userLongitude = result.location!.longitude;
    _lastLocationUpdate = DateTime.now();
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
