// ============================================================
// REQUEST MODELS - Outgoing API request payloads
// ============================================================

/// Payload for POST /api/volunteers/register
class RegisterRequest {
  final String name;
  final String phone;
  final String locality;
  final String city;
  final String state;
  final List<String> skills;
  final String availability;
  final bool consentGiven;
  final double? latitude;  // Geolocation data (optional - for location-based services)
  final double? longitude;

  const RegisterRequest({
    required this.name,
    required this.phone,
    required this.locality,
    required this.city,
    required this.state,
    required this.skills,
    required this.availability,
    required this.consentGiven,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'locality': locality,
      'city': city,
      'state': state,
      'skills': skills,
      'availability': availability,
      'consent_given': consentGiven,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

/// Payload for GET /api/volunteers/search
class SearchRequest {
  final String locality;
  final String emergencyType;

  const SearchRequest({
    required this.locality,
    required this.emergencyType,
  });

  Map<String, String> toQueryParams() => {
        'locality': locality,
        'emergency_type': emergencyType,
      };
}

/// Payload for POST /api/emergency/match (smart emergency matching)
/// Sends user's geolocation + emergency type to find nearest responders
class EmergencyMatchRequest {
  final double latitude;
  final double longitude;
  final String emergencyType;
  final double radiusKm; // Search radius in kilometers (optional, default 5km)

  const EmergencyMatchRequest({
    required this.latitude,
    required this.longitude,
    required this.emergencyType,
    this.radiusKm = 5.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'emergency_type': emergencyType,
      'radius_km': radiusKm,
    };
  }
}

/// Payload for POST /api/emergency/broadcast
/// Sends one emergency alert to multiple nearby responders at once
class EmergencyBroadcastRequestPayload {
  final String emergencyType;
  final double latitude;
  final double longitude;
  final List<String> responderIds;

  const EmergencyBroadcastRequestPayload({
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.responderIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'emergency_type': emergencyType,
      'latitude': latitude,
      'longitude': longitude,
      'responder_ids': responderIds,
    };
  }
}
