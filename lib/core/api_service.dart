// ============================================================
// API SERVICE - Supabase RPC client with structured error handling
// ============================================================

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // ============================================================
  // REGISTER VOLUNTEER
  // ============================================================

  Future<ApiResult<RegisterResponse>> registerVolunteer(
      RegisterRequest request) async {
    try {
      final response = await _client.rpc(
        'register_volunteer',
        params: {
          'p_name': request.name,
          'p_phone': request.phone,
          'p_email': request.email,
          'p_locality': request.locality,
          'p_city': request.city,
          'p_state': request.state,
          'p_skills': request.skills,
          'p_availability': request.availability,
          'p_consent': request.consentGiven,
          if (request.latitude != null) 'p_latitude': request.latitude,
          if (request.longitude != null) 'p_longitude': request.longitude,
        },
      );

      if (response['success'] == true) {
        return ApiResult.success(
          RegisterResponse(
            success: true,
            message: response['message'] ?? 'Registration successful!',
          ),
        );
      } else {
        return ApiResult.failure(
          response['error'] ?? 'Validation error',
          ApiErrorType.validation,
        );
      }
    } on PostgrestException catch (e) {
      return ApiResult.failure(
        e.message,
        ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Request timed out.',
        ApiErrorType.network,
      );
    } catch (e) {
      return ApiResult.failure(
        'Unexpected error: ${e.toString()}',
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
    final response = await _client.rpc(
      'search_volunteers',
      params: {
        'p_locality': locality.trim(),
        'p_skill': emergencyType.trim(),
      },
    );

    final rawList = response['volunteers'] as List<dynamic>? ?? [];

    final List<Volunteer> volunteers = rawList
        .map<Volunteer>((item) =>
            Volunteer.fromJson(Map<String, dynamic>.from(item)))
        .toList();

    return ApiResult.success(
      SearchResponse(volunteers: volunteers),
    );
  } on PostgrestException catch (e) {
    return ApiResult.failure(
      e.message,
      ApiErrorType.server,
    );
  } catch (e) {
    return ApiResult.failure(
      'Unexpected error: ${e.toString()}',
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
      final response = await _client.rpc(
        'emergency_match',
        params: {
          'p_emergency_type': request.emergencyType.trim(),
          'p_latitude': request.latitude,
          'p_longitude': request.longitude,
          'p_radius_km': request.radiusKm,
        },
      );

      // Parse responders list - handle multiple response formats
      List<dynamic> rawList = [];
      if (response['responders'] is List) {
        rawList = response['responders'] as List<dynamic>;
      } else if (response['data'] is List) {
        rawList = response['data'] as List<dynamic>;
      } else if (response['results'] is List) {
        rawList = response['results'] as List<dynamic>;
      }

      final List<Volunteer> responders = rawList
          .map<Volunteer>((item) =>
              Volunteer.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      // Return matched responders with metadata
      return ApiResult.success(
        EmergencyMatchResponse(
          responders: responders,
          total: response['total'] as int? ?? rawList.length,
          message: response['message']?.toString(),
          userLatitude: response['user_latitude'] is num
              ? (response['user_latitude'] as num).toDouble()
              : request.latitude,
          userLongitude: response['user_longitude'] is num
              ? (response['user_longitude'] as num).toDouble()
              : request.longitude,
          emergencyType: request.emergencyType,
        ),
      );
    } on PostgrestException catch (e) {
      return ApiResult.failure(
        'Failed to find nearby responders: ${e.message}',
        ApiErrorType.server,
      );
    } on TimeoutException {
      return const ApiResult.failure(
        'Emergency matching request timed out. Please try again.',
        ApiErrorType.network,
      );
    } catch (e) {
      return ApiResult.failure(
        'Error matching responders: ${e.toString()}',
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
      return ApiResult.failure(
        e.message,
        ApiErrorType.server,
      );
    } catch (e) {
      return const ApiResult.failure(
        'Failed to load dashboard stats',
        ApiErrorType.unknown,
      );
    }
  }
}
