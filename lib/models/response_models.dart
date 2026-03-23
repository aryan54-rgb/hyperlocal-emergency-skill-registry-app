// ============================================================
// RESPONSE MODELS - Incoming API response structures
// ============================================================

import 'volunteer.dart';

/// Response from POST /api/volunteers/register
class RegisterResponse {
  final bool success;
  final String message;
  final String? volunteerId;

  const RegisterResponse({
    required this.success,
    required this.message,
    this.volunteerId,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] as bool? ?? true,
      message: json['message']?.toString() ?? 'Registration successful!',
      volunteerId: json['volunteer_id']?.toString() ??
          json['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        if (volunteerId != null) 'volunteer_id': volunteerId,
      };
}

/// Response from GET /api/volunteers/search
class SearchResponse {
  final List<Volunteer> volunteers;
  final int? total;
  final String? message;

  const SearchResponse({
    required this.volunteers,
    this.total,
    this.message,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    // Handle both { volunteers: [...] } and direct array responses
    List<dynamic> rawList = [];
    if (json['volunteers'] is List) {
      rawList = json['volunteers'] as List<dynamic>;
    } else if (json['data'] is List) {
      rawList = json['data'] as List<dynamic>;
    } else if (json['results'] is List) {
      rawList = json['results'] as List<dynamic>;
    }

    return SearchResponse(
      volunteers: rawList
          .map((e) => Volunteer.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawList.length,
      message: json['message']?.toString(),
    );
  }

  bool get isEmpty => volunteers.isEmpty;
  int get count => volunteers.length;
}

/// Response from POST /api/emergency/match
/// Sorted by distance (nearest first) and availability
class EmergencyMatchResponse {
  final List<Volunteer> responders; // Already sorted by distance + availability
  final int? total;
  final String? message;
  final double? userLatitude;
  final double? userLongitude;
  final String? emergencyType;

  const EmergencyMatchResponse({
    required this.responders,
    this.total,
    this.message,
    this.userLatitude,
    this.userLongitude,
    this.emergencyType,
  });

  factory EmergencyMatchResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> rawList = [];
    if (json['responders'] is List) {
      rawList = json['responders'] as List<dynamic>;
    } else if (json['data'] is List) {
      rawList = json['data'] as List<dynamic>;
    } else if (json['results'] is List) {
      rawList = json['results'] as List<dynamic>;
    }

    return EmergencyMatchResponse(
      responders: rawList
          .map((e) => Volunteer.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? rawList.length,
      message: json['message']?.toString(),
      userLatitude: json['user_latitude'] is num ? (json['user_latitude'] as num).toDouble() : null,
      userLongitude: json['user_longitude'] is num ? (json['user_longitude'] as num).toDouble() : null,
      emergencyType: json['emergency_type']?.toString(),
    );
  }

  bool get isEmpty => responders.isEmpty;
  int get count => responders.length;
  
  /// Get top N responders sorted by distance
  List<Volunteer> getTopResponders(int limit) => responders.take(limit).toList();
}

/// Stats for the Impact Dashboard (mock-ready structure)
class DashboardStats {
  final int totalVolunteers;
  final int totalMatches;
  final String avgResponseTime;
  final int activeNearby;
  final int citiesCovered;

  const DashboardStats({
    required this.totalVolunteers,
    required this.totalMatches,
    required this.avgResponseTime,
    required this.activeNearby,
    required this.citiesCovered,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVolunteers: json['total_volunteers'] as int? ?? 0,
      totalMatches: json['total_matches'] as int? ?? 0,
      avgResponseTime: json['avg_response_time']?.toString() ?? 'N/A',
      activeNearby: json['active_nearby'] as int? ?? 0,
      citiesCovered: json['cities_covered'] as int? ?? 0,
    );
  }

  // ---- Mock data for demo / offline mode ----
  static DashboardStats get mock => const DashboardStats(
        totalVolunteers: 2412,
        totalMatches: 847,
        avgResponseTime: '< 90s',
        activeNearby: 23,
        citiesCovered: 38,
      );
}
