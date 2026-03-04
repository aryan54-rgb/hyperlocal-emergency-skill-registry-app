// ============================================================
// REQUEST MODELS - Outgoing API request payloads
// ============================================================

/// Payload for POST /api/volunteers/register
class RegisterRequest {
  final String name;
  final String phone;
  final String? email;
  final String locality;
  final String city;
  final String state;
  final List<String> skills;
  final String availability;
  final bool consentGiven;

  const RegisterRequest({
    required this.name,
    required this.phone,
    this.email,
    required this.locality,
    required this.city,
    required this.state,
    required this.skills,
    required this.availability,
    required this.consentGiven,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      if (email != null && email!.isNotEmpty) 'email': email,
      'locality': locality,
      'city': city,
      'state': state,
      'skills': skills,
      'availability': availability,
      'consent_given': consentGiven,
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
