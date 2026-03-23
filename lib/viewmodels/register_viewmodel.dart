// ============================================================
// REGISTER VIEWMODEL - Manages registration form state & API
// ============================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/location_service.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';

enum RegisterState { idle, loading, success, error }

class RegisterViewModel extends ChangeNotifier {
  RegisterState _state = RegisterState.idle;
  String? _errorMessage;
  RegisterResponse? _lastResponse;
  bool _shakeForm = false;

  // ---- Location auto-fill state ----
  bool _isGettingLocation = false;
  bool _locationPermissionError = false;
  String? _locationErrorMessage;
  double? _latitude;
  double? _longitude;

  RegisterState get state => _state;
  String? get errorMessage => _errorMessage;
  RegisterResponse? get lastResponse => _lastResponse;
  bool get shakeForm => _shakeForm;
  bool get isLoading => _state == RegisterState.loading;
  bool get isGettingLocation => _isGettingLocation;
  bool get locationPermissionError => _locationPermissionError;
  String? get locationErrorMessage => _locationErrorMessage;
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  // ---- Form field values ----
  String name = '';
  String phone = '';
  String email = '';
  String locality = '';
  String city = '';
  String selectedState = '';
  Set<String> selectedSkills = {};
  String availability = 'available_now';
  bool consentGiven = false;

  void toggleSkill(String skill) {
    if (selectedSkills.contains(skill)) {
      selectedSkills.remove(skill);
    } else {
      selectedSkills.add(skill);
    }
    notifyListeners();
  }

  void setAvailability(String value) {
    availability = value;
    notifyListeners();
  }

  void setConsent(bool value) {
    consentGiven = value;
    notifyListeners();
  }

  /// Validate all required fields; returns false and triggers shake if invalid.
  bool validate() {
    if (name.trim().isEmpty ||
        phone.trim().isEmpty ||
        locality.trim().isEmpty ||
        city.trim().isEmpty ||
        selectedState.trim().isEmpty ||
        selectedSkills.isEmpty ||
        availability.isEmpty ||
        !consentGiven) {
      _triggerShake();
      return false;
    }
    return true;
  }

  void _triggerShake() {
    _shakeForm = true;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 600), () {
      _shakeForm = false;
      notifyListeners();
    });
  }

  /// Call the registration API.
  Future<void> register() async {
    if (!validate()) return;

    _state = RegisterState.loading;
    _errorMessage = null;
    notifyListeners();

    final request = RegisterRequest(
      name: name.trim(),
      phone: phone.trim(),
      email: email.trim().isEmpty ? null : email.trim(),
      locality: locality.trim(),
      city: city.trim(),
      state: selectedState.trim(),
      skills: selectedSkills.toList(),
      availability: mapAvailabilityToDb(availability),
      consentGiven: consentGiven,
      latitude: _latitude,
      longitude: _longitude,
    );

    final result = await ApiService.instance.registerVolunteer(request);

    if (result.isSuccess) {
      _lastResponse = result.data;
      _state = RegisterState.success;
    } else {
      _errorMessage = result.error;
      _state = RegisterState.error;
    }
    notifyListeners();
  }

  /// Reset so user can register again.
  void reset() {
    _state = RegisterState.idle;
    _errorMessage = null;
    _lastResponse = null;
    _shakeForm = false;
    _isGettingLocation = false;
    _locationPermissionError = false;
    _locationErrorMessage = null;
    _latitude = null;
    _longitude = null;
    name = '';
    phone = '';
    email = '';
    locality = '';
    city = '';
    selectedState = '';
    selectedSkills = {};
    availability = '';
    consentGiven = false;
    notifyListeners();
  }

  /// Fetch current location and auto-fill location fields
  /// 1. Gets GPS coordinates
  /// 2. Reverse geocodes to get address
  /// 3. Auto-fills locality, city, state in form
  /// 4. Saves latitude and longitude for API
  Future<void> autoFillLocationFromGPS() async {
    _isGettingLocation = true;
    _locationPermissionError = false;
    _locationErrorMessage = null;
    notifyListeners();

    try {
      // ---- Step 1: Get current location ----
      final locationResult = await LocationService.instance.getCurrentLocation();

      if (locationResult.isFailure) {
        _locationPermissionError = locationResult.errorType == LocationErrorType.permissionDenied ||
            locationResult.errorType == LocationErrorType.permissionDeniedForever;
        _locationErrorMessage = LocationService.getErrorMessage(locationResult.errorType);
        _isGettingLocation = false;
        notifyListeners();
        return;
      }

      final location = locationResult.location!;
      _latitude = location.latitude;
      _longitude = location.longitude;

      // ---- Step 2: Reverse geocode coordinates to address ----
      final addressResult = await LocationService.instance.reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      if (addressResult.isFailure) {
        _locationErrorMessage = addressResult.error ?? 'Failed to get address details';
        _isGettingLocation = false;
        notifyListeners();
        return;
      }

      final address = addressResult.address!;

      // ---- Step 3: Auto-fill form fields ----
      if (address.locality != null && address.locality!.isNotEmpty) {
        locality = address.locality!;
      }
      if (address.city != null && address.city!.isNotEmpty) {
        city = address.city!;
      }
      if (address.state != null && address.state!.isNotEmpty) {
        selectedState = address.state!;
      }

      _isGettingLocation = false;
      _locationErrorMessage = null;
      notifyListeners();
    } catch (e) {
      _locationErrorMessage = 'Error getting location: ${e.toString()}';
      _isGettingLocation = false;
      notifyListeners();
    }
  }
}
String mapAvailabilityToDb(String uiValue) {
  switch (uiValue) {
    case 'Available Now':
      return 'available_now';
    case 'Within 30 Minutes':
      return 'within_30_min';
    case 'Busy':
      return 'busy';
    default:
      return 'available_now';
  }
}
