// ============================================================
// VOLUNTEER MODEL - Core data entity
// ============================================================

class Volunteer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String locality;
  final String city;
  final String state;
  final List<String> skills;
  final String availability;
  final bool isActive;
  final DateTime? registeredAt;
  
  /// Geolocation data (optional - for emergency matching)
  final double? latitude;
  final double? longitude;
  
  /// Distance in kilometers (calculated during emergency matching)
  final double? distanceKm;

  const Volunteer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.locality,
    required this.city,
    required this.state,
    required this.skills,
    required this.availability,
    this.isActive = true,
    this.registeredAt,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  // ---- JSON Deserialization ----
  factory Volunteer.fromJson(Map<String, dynamic> json) {
    return Volunteer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      locality: json['locality']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      skills: _parseStringList(json['skills']),
      availability: json['availability']?.toString() ?? 'Unknown',
      isActive: json['is_active'] as bool? ?? true,
      registeredAt: json['registered_at'] != null
          ? DateTime.tryParse(json['registered_at'].toString())
          : null,
      latitude: json['latitude'] is num ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] is num ? (json['longitude'] as num).toDouble() : null,
      distanceKm: json['distance_km'] is num ? (json['distance_km'] as num).toDouble() : null,
    );
  }

  // ---- JSON Serialization ----
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      'locality': locality,
      'city': city,
      'state': state,
      'skills': skills,
      'availability': availability,
      'is_active': isActive,
      if (registeredAt != null) 'registered_at': registeredAt!.toIso8601String(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (distanceKm != null) 'distance_km': distanceKm,
    };
  }

  /// Primary skill shown on card
  String get primarySkill =>
      skills.isNotEmpty ? skills.first : 'General Volunteer';

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
