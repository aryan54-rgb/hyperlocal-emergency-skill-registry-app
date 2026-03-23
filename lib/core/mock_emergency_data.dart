// ============================================================
// MOCK EMERGENCY DATA - Fallback for demo when backend unavailable
// ============================================================

import '../models/volunteer.dart';

/// Configuration toggle for mock data mode
bool useMockEmergencyData = false;

/// Generate realistic mock responders for demo purposes
/// Includes varying distances, skills, availability, and active status
class MockEmergencyData {
  static List<Volunteer> generateMockResponders({
    required String emergencyType,
    required double userLatitude,
    required double userLongitude,
    int count = 5,
  }) {
    final responders = <Volunteer>[
      Volunteer(
        id: 'mock_001',
        name: 'Rajesh Kumar',
        phone: '+919876543210',
        email: 'rajesh@example.com',
        locality: 'MG Road',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['First Aid', 'CPR', 'Emergency Response'],
        availability: 'available_now',
        isActive: true,
        latitude: userLatitude + 0.001,
        longitude: userLongitude + 0.001,
        distanceKm: 0.5,
      ),
      Volunteer(
        id: 'mock_002',
        name: 'Priya Sharma',
        phone: '+919876543211',
        email: 'priya@example.com',
        locality: 'Indiranagar',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Trauma Care', 'Emergency Response'],
        availability: 'available_now',
        isActive: true,
        latitude: userLatitude + 0.002,
        longitude: userLongitude - 0.002,
        distanceKm: 1.2,
      ),
      Volunteer(
        id: 'mock_003',
        name: 'Amit Patel',
        phone: '+919876543212',
        email: 'amit@example.com',
        locality: 'Whitefield',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Fire Safety', 'Emergency Response', 'CPR'],
        availability: 'within_30_min',
        isActive: true,
        latitude: userLatitude - 0.002,
        longitude: userLongitude + 0.003,
        distanceKm: 1.8,
      ),
      Volunteer(
        id: 'mock_004',
        name: 'Meera Reddy',
        phone: '+919876543213',
        email: 'meera@example.com',
        locality: 'Marathahalli',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Women Safety', 'Emergency Response'],
        availability: 'within_30_min',
        isActive: false,
        latitude: userLatitude + 0.003,
        longitude: userLongitude + 0.002,
        distanceKm: 2.1,
      ),
      Volunteer(
        id: 'mock_005',
        name: 'Vikram Singh',
        phone: '+919876543214',
        email: 'vikram@example.com',
        locality: 'Koramangala',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['First Aid', 'Transport Assistance'],
        availability: 'available',
        isActive: true,
        latitude: userLatitude - 0.003,
        longitude: userLongitude - 0.001,
        distanceKm: 2.5,
      ),
    ];

    // Return subset if count is less than total
    return responders.take(count).toList();
  }

  /// Check if emergency type is valid for mock generation
  static bool isValidEmergencyType(String type) {
    const validTypes = [
      'Medical',
      'Fire',
      'Transport',
      'Women Safety',
      'Elderly Help',
      'Other',
    ];
    return validTypes.contains(type);
  }

  /// Get mock data with realistic delay to simulate API call
  static Future<List<Volunteer>> getMockRespondersWithDelay({
    required String emergencyType,
    required double latitude,
    required double longitude,
    Duration delay = const Duration(seconds: 2),
  }) async {
    await Future.delayed(delay);
    return generateMockResponders(
      emergencyType: emergencyType,
      userLatitude: latitude,
      userLongitude: longitude,
    );
  }
}
