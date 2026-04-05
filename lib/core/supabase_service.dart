import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Register volunteer
  Future<Map<String, dynamic>> registerVolunteer({
    required String name,
    required String phone,
    required String locality,
    required String city,
    required String state,
    required List<String> skills,
    required String availability,
    required bool consent,
  }) async {
    final response = await _client
        .from('volunteers')
        .insert({
          'name': name.trim(),
          'phone': phone.trim(),
          'locality': locality.trim(),
          'city': city.trim(),
          'state': state.trim(),
          'skills': skills.map((skill) => skill.trim()).toList(),
          'availability': availability.trim(),
          'consent_given': consent,
        })
        .select('id, created_at')
        .single();

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
