import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Register volunteer
  Future<Map<String, dynamic>> registerVolunteer({
    required String name,
    required String phone,
    String? email,
    required String locality,
    required String city,
    required String state,
    required List<String> skills,
    required String availability,
    required bool consent,
  }) async {
    final response = await _client.rpc(
      'register_volunteer',
      params: {
        'p_name': name,
        'p_phone': phone,
        'p_email': email,
        'p_locality': locality,
        'p_city': city,
        'p_state': state,
        'p_skills': skills,
        'p_availability': availability,
        'p_consent': consent,
      },
    );

    return response;
  }

  // Search volunteers
  Future<Map<String, dynamic>> searchVolunteers({
    required String locality,
    required String skill,
  }) async {
    final response = await _client.rpc(
      'search_volunteers',
      params: {
        'p_locality': locality,
        'p_skill': skill,
      },
    );

    return response;
  }

  // Dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.rpc('get_dashboard_stats');
    return response;
  }
}
