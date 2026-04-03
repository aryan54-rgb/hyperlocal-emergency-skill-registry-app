// ============================================================
// VOLUNTEER MODEL - Core data entity
// ============================================================

class Volunteer {
  final String id;
  final String name;
  final String phone;
  final String locality;
  final String city;
  final String state;
  final List<String> skills;
  final String availability;
  final bool consentGiven;
  final DateTime? createdAt;

  /// Geolocation data (optional - for emergency matching)
  final double? latitude;
  final double? longitude;
  final DateTime? lastUpdated;

  /// Distance in kilometers (calculated during emergency matching)
  final double? distanceKm;

  /// Privacy flag: Whether volunteer has enabled location sharing
  final bool isLocationShared;

  const Volunteer({
    required this.id,
    required this.name,
    required this.phone,
    required this.locality,
    required this.city,
    required this.state,
    required this.skills,
    required this.availability,
    required this.consentGiven,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.distanceKm,
    this.isLocationShared = false,
  });

  // ---- JSON Deserialization ----
  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      locality: json['locality']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      skills: _parseStringList(json['skills']),
      availability: json['availability']?.toString() ?? 'available_now',
      consentGiven: json['consent_given'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString())
          : null,
      distanceKm: json['distance_km'] is num ? (json['distance_km'] as num).toDouble() : null,
      isLocationShared: json['is_location_shared'] as bool? ?? false,
    );
  }

  // ---- JSON Serialization ----
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'locality': locality,
      'city': city,
      'state': state,
      'skills': skills,
      'availability': availability,
      'consent_given': consentGiven,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (lastUpdated != null) 'last_updated': lastUpdated!.toIso8601String(),
      if (distanceKm != null) 'distance_km': distanceKm,
      'is_location_shared': isLocationShared,
    };
  }

  /// Primary skill shown on card
  String get primarySkill =>
      skills.isNotEmpty ? skills.first : 'General Volunteer';

  /// Whether coordinate data exists for this volunteer.
  bool get hasValidLocation => latitude != null && longitude != null;

  /// Whether this volunteer should appear on live-map surfaces.
  bool get hasLiveLocationAvailable => isLocationShared && hasValidLocation;

  /// Formatted skills string
  String get skillsDisplay => skills.join(' • ');

  /// Initials for avatar
  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  @override
  String toString() => 'Volunteer($id, $name, $locality)';
}
