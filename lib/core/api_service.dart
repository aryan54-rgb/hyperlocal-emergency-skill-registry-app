// ============================================================
// API SERVICE - Supabase RPC client with structured error handling
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';
import '../models/volunteer.dart';
import 'mock_emergency_data.dart';

/// Represents the result of any API call.
/// Either [data] is non-null or [error] is non-null.
class ApiResult<T> {
  final T? data;
  final String? error;
  final ApiErrorType? errorType;

  const ApiResult.success(this.data)
      : error = null,
        errorType = null;

  const ApiResult.failure(this.error, this.errorType)
      : data = null;

  bool get isSuccess => data != null;
  bool get isFailure => error != null;
}

/// Enum of error categories for UI differentiation
enum ApiErrorType {
  validation,
  notFound,
  server,
  network,
  unknown,
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  final SupabaseClient _client = Supabase.instance.client;

  Map<String, dynamic> _normalizeRpcResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {'data': response};
  }

  Map<String, dynamic> _sanitizeInsertPayload(Map<String, dynamic> payload) {
    return payload.map((key, value) {
      if (value is String) {
        return MapEntry(key, value.trim());
      }
      if (value is List) {
        return MapEntry(
          key,
          value
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
        );
      }
      return MapEntry(key, value);
    });
  }

  void _logFailure(String context, Object error, [StackTrace? stackTrace]) {
    debugPrint('[Supabase][$context] $error');
    if (stackTrace != null && !kReleaseMode) {
      debugPrint(stackTrace.toString());
    }
  }

  String _friendlySupabaseMessage(Object error) {
    final rawMessage = error is PostgrestException
        ? error.message.toLowerCase()
        : error.toString().toLowerCase();

    if (rawMessage.contains('consent_given') ||
        rawMessage.contains('row-level security policy')) {
      return 'Please review the consent checkbox and complete all required fields.';
    }
    if (rawMessage.contains('phone') && rawMessage.contains('duplicate')) {
      return 'This phone number is already registered.';
    }
    if (rawMessage.contains('name') && rawMessage.contains('check constraint')) {
      return 'Please enter your full name.';
    }
    if (rawMessage.contains('phone') && rawMessage.contains('check constraint')) {
      return 'Please enter a valid phone number.';
    }
    if (rawMessage.contains('locality') ||
        rawMessage.contains('city') ||
        rawMessage.contains('state')) {
      return 'Please complete your location details before registering.';
    }
    if (rawMessage.contains('skills')) {
      return 'Select at least one skill before registering.';
    }
    if (rawMessage.contains('availability')) {
      return 'Please choose your availability.';
    }
    if (rawMessage.contains('network') || rawMessage.contains('socket')) {
      return 'Please check your internet connection and try again.';
    }

    return 'We could not complete your request right now. Please try again.';
  }

  bool _volunteerMatchesEmergencyType(
    Volunteer volunteer,
    String emergencyType,
  ) {
    final requiredSkills = AppConstants.getSkillsForEmergency(emergencyType)
        .map((skill) => skill.trim().toLowerCase())
        .toSet();

    if (requiredSkills.isEmpty) {
      return true;
    }

    return volunteer.skills.any(
      (skill) => requiredSkills.contains(skill.trim().toLowerCase()),
    );
  }

  bool _volunteerMatchesSelectedSkill(
    Volunteer volunteer,
    String selectedSkill,
  ) {
    final normalizedSkill = selectedSkill.trim().toLowerCase();
    if (normalizedSkill.isEmpty) {
      return true;
    }

    return volunteer.skills.any(
      (skill) => skill.trim().toLowerCase() == normalizedSkill,
    );
  }

  // ============================================================
  // REGISTER VOLUNTEER
  // ============================================================

  Future<ApiResult<RegisterResponse>> registerVolunteer(
      RegisterRequest request) async {
    try {
      final payload = _sanitizeInsertPayload(request.toJson());
      final hasCoordinates =
          request.latitude != null && request.longitude != null;
      payload['is_location_shared'] = request.consentGiven &&
          request.availability != 'busy' &&
          hasCoordinates;
      if (hasCoordinates) {
        payload['last_updated'] = DateTime.now().toUtc().toIso8601String();
      }
      debugPrint(
        '[Supabase][registerVolunteer] inserting volunteer with phone=${payload['phone']} locality=${payload['locality']}',
      );

      final response = await _client
          .from('volunteers')
          .insert(payload)
          .select('id, created_at')
          .single();

      return ApiResult.success(
        RegisterResponse(
          success: true,
          message: 'Registration successful!',
          volunteerId: response['id']?.toString(),
        ),
      );
    } on PostgrestException catch (e) {
      _logFailure('registerVolunteer', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        e.message.toLowerCase().contains('row-level security policy')
            ? ApiErrorType.validation
            : ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Request timed out.',
        ApiErrorType.network,
      );
    } catch (e) {
      _logFailure('registerVolunteer', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  // ============================================================
  // SEARCH VOLUNTEERS
  // ============================================================

  Future<ApiResult<SearchResponse>> searchVolunteers({
    required String locality,
    required String emergencyType,
  }) async {
    try {
      final response = await _client
          .from('volunteers')
          .select(
            'id, name, phone, locality, city, state, skills, availability, consent_given, created_at, latitude, longitude, last_updated, is_location_shared',
          )
          .eq('consent_given', true)
          .ilike('locality', '%${locality.trim()}%')
          .order('created_at', ascending: false);

      final rawList = response as List<dynamic>;

      final List<Volunteer> volunteers = rawList
          .map<Volunteer>(
            (item) => Volunteer.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((volunteer) => volunteer.skills.isNotEmpty)
          .where(
            (volunteer) => _volunteerMatchesSelectedSkill(
              volunteer,
              emergencyType,
            ),
          )
          .toList();

      return ApiResult.success(
        SearchResponse(
          volunteers: volunteers,
          total: volunteers.length,
        ),
      );
    } on PostgrestException catch (e) {
      _logFailure('searchVolunteers', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('searchVolunteers', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  // ============================================================
  // SMART EMERGENCY MATCHING (One-Tap Feature)
  // ============================================================

  /// Smart emergency responder matching based on geolocation
  ///
  /// Sends user's GPS coordinates + emergency type to backend
  /// Backend returns nearest responders sorted by distance & availability
  ///
  /// Request includes:
  /// - emergency_type: Category (Medical, Fire, Transport, etc)
  /// - latitude: User's current latitude
  /// - longitude: User's current longitude
  /// - radius_km: Search radius (default 5km)
  ///
  /// Response includes:
  /// - responders: List of Volunteer objects with distanceKm calculated
  /// - total: Count of matching responders
  /// - user location echoed back for reference
  Future<ApiResult<EmergencyMatchResponse>> emergencyMatch(
    EmergencyMatchRequest request,
  ) async {
    try {
      // ---- Mock data mode for demo/testing ----
      if (useMockEmergencyData) {
        final mockResponders = MockEmergencyData.generateMockResponders(
          emergencyType: request.emergencyType,
          userLatitude: request.latitude,
          userLongitude: request.longitude,
        );
        // Simulate network delay for realistic feel
        await Future.delayed(const Duration(milliseconds: 800));
        return ApiResult.success(
          EmergencyMatchResponse(
            responders: mockResponders,
            total: mockResponders.length,
            message: 'Demo data (mock mode)',
            userLatitude: request.latitude,
            userLongitude: request.longitude,
            emergencyType: request.emergencyType,
          ),
        );
      }

      // ---- Real API call ----
      // We use the canonical location RPC that exists in the checked-in
      // Supabase schema, then match emergency categories to volunteer skills
      // in Flutter using AppConstants.emergencyTypeSkillMap.
      final response = await _client.rpc(
        'get_volunteers_with_location',
        params: {
          'p_user_latitude': request.latitude,
          'p_user_longitude': request.longitude,
          'p_radius_km': request.radiusKm,
        },
      );
      final payload = _normalizeRpcResponse(response);

      List<dynamic> rawList = [];
      if (payload['success'] == false) {
        return ApiResult.failure(
          payload['error']?.toString() ??
              'Failed to find nearby responders. Please try again shortly.',
          ApiErrorType.server,
        );
      }
      if (payload['volunteers'] is List) {
        rawList = payload['volunteers'] as List<dynamic>;
      } else if (payload['data'] is List) {
        rawList = payload['data'] as List<dynamic>;
      } else if (response is List) {
        rawList = response as List<dynamic>;
      }

      final List<Volunteer> responders = rawList
          .map<Volunteer>(
            (item) => Volunteer.fromJson(Map<String, dynamic>.from(item)),
          )
          .where(
            (volunteer) => _volunteerMatchesEmergencyType(
              volunteer,
              request.emergencyType,
            ),
          )
          .toList();

      // Return matched responders with metadata
      return ApiResult.success(
        EmergencyMatchResponse(
          responders: responders,
          total: responders.length,
          message: payload['message']?.toString(),
          userLatitude: payload['user_latitude'] is num
              ? (payload['user_latitude'] as num).toDouble()
              : request.latitude,
          userLongitude: payload['user_longitude'] is num
              ? (payload['user_longitude'] as num).toDouble()
              : request.longitude,
          emergencyType: request.emergencyType,
        ),
      );
    } on PostgrestException catch (e) {
      _logFailure('emergencyMatch', e);
      return ApiResult.failure(
        'Failed to find nearby responders. Please try again shortly.',
        ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Emergency matching request timed out. Please try again.',
        ApiErrorType.network,
      );
    } catch (e) {
      _logFailure('emergencyMatch', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  // ============================================================
  // EMERGENCY BROADCAST ALERTS
  // ============================================================

  /// Broadcast emergency alert to multiple responders.
  /// If backend endpoint is unavailable, caller may fallback to mock flow.
  Future<ApiResult<Map<String, dynamic>>> broadcastEmergencyAlerts(
    EmergencyBroadcastRequestPayload request,
  ) async {
    try {
      final response = await _client.rpc(
        'broadcast_emergency_alerts',
        params: {
          'p_emergency_type': request.emergencyType.trim(),
          'p_latitude': request.latitude,
          'p_longitude': request.longitude,
          'p_responder_ids': request.responderIds,
        },
      );

      if (response is Map<String, dynamic>) {
        return ApiResult.success(response);
      }
      if (response is Map) {
        return ApiResult.success(Map<String, dynamic>.from(response));
      }

      return const ApiResult.success({'success': true});
    } on PostgrestException catch (e) {
      _logFailure('broadcastEmergencyAlerts', e);
      return ApiResult.failure(
        'Broadcast endpoint unavailable right now.',
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('broadcastEmergencyAlerts', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  Future<ApiResult<Map<String, dynamic>>> getDashboardStats() async {
    try {
      final response = await _client.rpc('get_dashboard_stats');
      return ApiResult.success(response);
    } on PostgrestException catch (e) {
      _logFailure('getDashboardStats', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('getDashboardStats', e);
      return const ApiResult.failure(
        'Failed to load dashboard stats',
        ApiErrorType.unknown,
      );
    }
  }

  // ============================================================
  // VOLUNTEER LOCATION MANAGEMENT - Live Map Feature
  // ============================================================

  /// Update current user's location
  ///
  /// Called periodically by the user's device to send live location
  /// Body: { volunteer_id, latitude, longitude }
  ///
  /// Returns: Success message with timestamp
  Future<ApiResult<Map<String, dynamic>>> updateVolunteerLocation({
    required String volunteerId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _client.rpc(
        'update_volunteer_location',
        params: {
          'p_volunteer_id': volunteerId,
          'p_latitude': latitude,
          'p_longitude': longitude,
        },
      );
      final payload = _normalizeRpcResponse(response);

      if (payload['success'] == false) {
        return ApiResult.failure(
          payload['error']?.toString() ?? 'Failed to update location',
          ApiErrorType.server,
        );
      }
      return ApiResult.success(payload);
    } on PostgrestException catch (e) {
      _logFailure('updateVolunteerLocation', e);
      return ApiResult.failure(
        'Failed to update location right now.',
        ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Location update timed out',
        ApiErrorType.network,
      );
    } catch (e) {
      _logFailure('updateVolunteerLocation', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  /// Fetch all volunteers with their live location
  ///
  /// Returns only volunteers who have enabled location sharing
  /// Includes: name, skills, availability, latitude, longitude, distance (calculated by frontend)
  ///
  /// Optional parameters:
  /// - locality: Filter by specific locality
  /// - radiusKm: If provided with user location, only return volunteers within radius
  Future<ApiResult<List<Volunteer>>> fetchVolunteersWithLocation({
    String? locality,
    double? userLatitude,
    double? userLongitude,
    double? radiusKm,
  }) async {
    try {
      final response = await _client.rpc(
        'get_volunteers_with_location',
        params: {
          if (locality != null) 'p_locality': locality.trim(),
          if (userLatitude != null) 'p_user_latitude': userLatitude,
          if (userLongitude != null) 'p_user_longitude': userLongitude,
          if (radiusKm != null) 'p_radius_km': radiusKm,
        },
      );
      final payload = _normalizeRpcResponse(response);

      // Parse response - handle multiple formats
      List<dynamic> rawList = [];
      if (payload['success'] == false) {
        return ApiResult.failure(
          payload['error']?.toString() ?? 'Failed to fetch volunteer locations',
          ApiErrorType.server,
        );
      }
      if (payload['volunteers'] is List) {
        rawList = payload['volunteers'] as List<dynamic>;
      } else if (payload['data'] is List) {
        rawList = payload['data'] as List<dynamic>;
      } else if (response is List) {
        rawList = response as List<dynamic>;
      }

      final List<Volunteer> volunteers = rawList
          .map<Volunteer>((item) =>
              Volunteer.fromJson(Map<String, dynamic>.from(item)))
          .where((volunteer) => volunteer.hasLiveLocationAvailable)
          .toList();

      return ApiResult.success(volunteers);
    } on PostgrestException catch (e) {
      _logFailure('fetchVolunteersWithLocation', e);
      return ApiResult.failure(
        'Failed to load nearby volunteers.',
        ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Request timed out',
        ApiErrorType.network,
      );
    } catch (e) {
      _logFailure('fetchVolunteersWithLocation', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> toggleLocationSharing({
    required String volunteerId,
    required bool isLocationShared,
  }) async {
    try {
      final response = await _client.rpc(
        'toggle_location_sharing',
        params: {
          'p_volunteer_id': volunteerId,
          'p_is_location_shared': isLocationShared,
        },
      );
      final payload = _normalizeRpcResponse(response);

      if (payload['success'] == false) {
        return ApiResult.failure(
          payload['error']?.toString() ?? 'Failed to update location sharing',
          ApiErrorType.server,
        );
      }

      return ApiResult.success(payload);
    } on PostgrestException catch (e) {
      _logFailure('toggleLocationSharing', e);
      return ApiResult.failure(
        'Failed to update location sharing.',
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('toggleLocationSharing', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> fetchVolunteerProfile({
    required String volunteerId,
  }) async {
    try {
      final response = await _client.rpc(
        'get_volunteer_profile',
        params: {'p_volunteer_id': volunteerId},
      );
      final payload = _normalizeRpcResponse(response);

      if (payload['success'] == false || payload['volunteer'] == null) {
        return const ApiResult.failure(
          'Volunteer profile not found',
          ApiErrorType.notFound,
        );
      }

      return ApiResult.success(
        Map<String, dynamic>.from(payload['volunteer'] as Map),
      );
    } on PostgrestException catch (e) {
      _logFailure('fetchVolunteerProfile', e);
      return ApiResult.failure(
        'Failed to load your volunteer profile.',
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('fetchVolunteerProfile', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }

  Future<ApiResult<Map<String, dynamic>>> updateVolunteerAvailability({
    required String volunteerId,
    required String availability,
    required bool isLocationShared,
  }) async {
    try {
      final response = await _client.rpc(
        'update_volunteer_availability',
        params: {
          'p_volunteer_id': volunteerId,
          'p_availability': availability,
          'p_is_location_shared': isLocationShared,
        },
      );
      final payload = _normalizeRpcResponse(response);

      if (payload['success'] == false || payload['volunteer'] == null) {
        return const ApiResult.failure(
          'Volunteer availability could not be updated',
          ApiErrorType.notFound,
        );
      }

      return ApiResult.success(
        Map<String, dynamic>.from(payload['volunteer'] as Map),
      );
    } on PostgrestException catch (e) {
      _logFailure('updateVolunteerAvailability', e);
      return ApiResult.failure(
        'Failed to update your availability.',
        ApiErrorType.server,
      );
    } catch (e) {
      _logFailure('updateVolunteerAvailability', e);
      return ApiResult.failure(
        _friendlySupabaseMessage(e),
        ApiErrorType.unknown,
      );
    }
  }
}
