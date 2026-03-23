// ============================================================
// LOCATION SERVICE - Geolocation & Permission abstraction
// ============================================================

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

/// Represents errors encountered during location operations
enum LocationErrorType {
  permissionDenied,        // User denied location permission
  permissionDeniedForever, // Permission denied permanently (needs settings)
  locationServiceDisabled, // Device location services disabled
  timeout,                 // Location request timed out
  unknown,                 // Unknown error
}

/// Represents a successful location result
class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
  });

  @override
  String toString() => 'Location($latitude, $longitude)';
}

/// Represents a reverse geocoded address result
class ReverseGeocodeResult {
  final String? locality;       // Neighborhood / area
  final String? city;           // City / municipality
  final String? state;          // State / province
  final String? country;        // Country
  final String? postalCode;     // Postal/ZIP code

  const ReverseGeocodeResult({
    this.locality,
    this.city,
    this.state,
    this.country,
    this.postalCode,
  });

  /// Check if result has at least minimal address data
  bool get hasValidData => (locality != null && locality!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      (state != null && state!.isNotEmpty);

  @override
  String toString() => 'Address($locality, $city, $state, $country)';
}

/// Result wrapper for reverse geocode operations
/// Either [address] is non-null or [error] is non-null
class ReverseGeocodeApiResult {
  final ReverseGeocodeResult? address;
  final String? error;
  final LocationErrorType? errorType;

  const ReverseGeocodeApiResult.success(this.address)
      : error = null,
        errorType = null;

  const ReverseGeocodeApiResult.failure(this.error, this.errorType)
      : address = null;

  bool get isSuccess => address != null;
  bool get isFailure => error != null;
}

/// Result wrapper for location operations
/// Either [location] is non-null or [error] is non-null
class LocationApiResult {
  final LocationResult? location;
  final String? error;
  final LocationErrorType? errorType;

  const LocationApiResult.success(this.location)
      : error = null,
        errorType = null;

  const LocationApiResult.failure(this.error, this.errorType)
      : location = null;

  bool get isSuccess => location != null;
  bool get isFailure => error != null;
}

/// Lightweight location service with clean permission & geolocation handling
/// No UI logic - returns clean error states for views to handle
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Request location permission from user
  /// Returns true if permission granted, false otherwise
  Future<bool> requestLocationPermission() async {
    try {
      final permission = await Geolocator.requestPermission();

      switch (permission) {
        case LocationPermission.denied:
        case LocationPermission.deniedForever:
          return false;

        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          return true;
      }
    } catch (e) {
      print('Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permission is already granted
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  /// Check if location services are enabled on device
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      // Error checking location service
      return false;
    }
  }

  /// Get current device location with comprehensive error handling
  /// Returns LocationApiResult with either location or error details
  Future<LocationApiResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationApiResult.failure(
          'Location services are disabled on this device',
          LocationErrorType.locationServiceDisabled,
        );
      }

      // Check if permission is granted
      final hasPermission = await hasLocationPermission();
      if (!hasPermission) {
        // Try to request permission
        final permGranted = await requestLocationPermission();
        if (!permGranted) {
          return LocationApiResult.failure(
            'Location permission denied',
            LocationErrorType.permissionDenied,
          );
        }
      }

      // Fetch current location with timeout
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: timeout,
        ).timeout(timeout);

        return LocationApiResult.success(
          LocationResult(
            latitude: position.latitude,
            longitude: position.longitude,
            accuracy: position.accuracy,
            altitude: position.altitude,
          ),
        );
      } on TimeoutException {
        return LocationApiResult.failure(
          'Location request timed out after ${timeout.inSeconds}s',
          LocationErrorType.timeout,
        );
      }
    } catch (e) {
      // Error logged internally
      return LocationApiResult.failure(
        'Failed to get location: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  /// Open app settings to allow user to enable location
  /// Useful when permission is denied or services are disabled
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
        print('Error opening location settings: $e');
    }
  }

  /// Calculate distance between two coordinates in kilometers
  /// Useful for sorting responders by distance
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert meters to km
  }

  /// Reverse geocode coordinates (lat/lng) into an address
  /// Returns locality, city, state, country from Geographic coordinates
  /// Useful for auto-filling location fields in registration or search
  Future<ReverseGeocodeApiResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) {
        return ReverseGeocodeApiResult.failure(
          'No address found for this location',
          LocationErrorType.unknown,
        );
      }

      final place = placemarks.first;
      final result = ReverseGeocodeResult(
        locality: place.thoroughfare ?? place.subLocality,
        city: place.locality ?? place.administrativeArea,
        state: place.administrativeArea,
        country: place.country,
        postalCode: place.postalCode,
      );

      if (!result.hasValidData) {
        return ReverseGeocodeApiResult.failure(
          'Incomplete address information',
          LocationErrorType.unknown,
        );
      }

      return ReverseGeocodeApiResult.success(result);
    } catch (e) {
      return ReverseGeocodeApiResult.failure(
        'Failed to get address: ${e.toString()}',
        LocationErrorType.unknown,
      );
    }
  }

  /// Get user-friendly error message for location errors
  static String getErrorMessage(LocationErrorType? errorType) {
    switch (errorType) {
      case LocationErrorType.permissionDenied:
        return 'Location permission is required to find nearby help';
      case LocationErrorType.permissionDeniedForever:
        return 'Location permission was denied. Please enable it in app settings';
      case LocationErrorType.locationServiceDisabled:
        return 'Please enable location services on your device';
      case LocationErrorType.timeout:
        return 'Location request timed out. Please try again';
      case LocationErrorType.unknown:
        return 'Unable to determine your location. Please try again';
      default:
        return 'An unknown error occurred';
    }
  }
}
