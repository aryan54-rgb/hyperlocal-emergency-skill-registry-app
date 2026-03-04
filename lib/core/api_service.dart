// ============================================================
// API SERVICE - Supabase RPC client with structured error handling
// ============================================================

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';
import '../models/volunteer.dart';

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
      return ApiResult.failure(
        'Failed to load dashboard stats',
        ApiErrorType.unknown,
      );
    }
  }
}
