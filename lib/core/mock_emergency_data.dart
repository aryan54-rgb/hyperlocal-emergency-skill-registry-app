// ============================================================
// MOCK EMERGENCY DATA - Fallback for demo when backend unavailable
// ============================================================

import 'dart:async';
import 'dart:math';
import '../models/volunteer.dart';

/// Configuration toggle for mock data mode.
/// Set to true to use demo data when backend is not available.
bool useMockEmergencyData = false;

/// Generate realistic mock responders for demo purposes
/// Includes varying distances, skills, and availability
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
        locality: 'MG Road',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['First Aid', 'CPR Certified', 'Emergency Driver'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude + 0.001,
        longitude: userLongitude + 0.001,
        distanceKm: 0.5,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'mock_002',
        name: 'Priya Sharma',
        phone: '+919876543211',
        locality: 'Indiranagar',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Trauma Care', 'Medical Professional'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude + 0.002,
        longitude: userLongitude - 0.002,
        distanceKm: 1.2,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'mock_003',
        name: 'Amit Patel',
        phone: '+919876543212',
        locality: 'Whitefield',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Fire Safety', 'Rescue Support', 'CPR Certified'],
        availability: 'within_30_min',
        consentGiven: true,
        latitude: userLatitude - 0.002,
        longitude: userLongitude + 0.003,
        distanceKm: 1.8,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'mock_004',
        name: 'Meera Reddy',
        phone: '+919876543213',
        locality: 'Marathahalli',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Trusted Local Volunteer', 'Escort Support'],
        availability: 'within_30_min',
        consentGiven: true,
        latitude: userLatitude + 0.003,
        longitude: userLongitude + 0.002,
        distanceKm: 2.1,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'mock_005',
        name: 'Vikram Singh',
        phone: '+919876543214',
        locality: 'Koramangala',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['First Aid', 'Vehicle Owner'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude - 0.003,
        longitude: userLongitude - 0.001,
        distanceKm: 2.5,
        isLocationShared: true,
      ),
    ];

    // Return subset if count is less than total
    return responders.take(count).toList();
  }

  /// Generate mock volunteers specifically for the Live Volunteer Map.
  /// These volunteers have valid coordinates spread around the user's location
  /// and isLocationShared = true so they pass all filters.
  static List<Volunteer> generateMockMapVolunteers({
    required double userLatitude,
    required double userLongitude,
  }) {
    return <Volunteer>[
      Volunteer(
        id: 'map_vol_001',
        name: 'Dr. Ananya Iyer',
        phone: '+919812340001',
        locality: 'Koramangala',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Medical Professional', 'CPR Certified', 'First Aid'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude + 0.0025,
        longitude: userLongitude - 0.0015,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_002',
        name: 'Ravi Deshmukh',
        phone: '+919812340002',
        locality: 'Indiranagar',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Firefighter', 'Rescue Support'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude - 0.0018,
        longitude: userLongitude + 0.0022,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_003',
        name: 'Sneha Kulkarni',
        phone: '+919812340003',
        locality: 'HSR Layout',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Nurse / Paramedic', 'Basic Life Support'],
        availability: 'within_30_min',
        consentGiven: true,
        latitude: userLatitude + 0.0012,
        longitude: userLongitude + 0.0030,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_004',
        name: 'Arjun Mehta',
        phone: '+919812340004',
        locality: 'Whitefield',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Emergency Driver', 'Vehicle Owner'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude - 0.0035,
        longitude: userLongitude - 0.0020,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_005',
        name: 'Fatima Sheikh',
        phone: '+919812340005',
        locality: 'MG Road',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Trusted Local Volunteer', 'First Aid', 'Escort Support'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude + 0.0040,
        longitude: userLongitude + 0.0010,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_006',
        name: 'Karan Joshi',
        phone: '+919812340006',
        locality: 'Electronic City',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Fire Safety', 'AED Operation'],
        availability: 'within_30_min',
        consentGiven: true,
        latitude: userLatitude - 0.0050,
        longitude: userLongitude + 0.0045,
        isLocationShared: true,
      ),
      Volunteer(
        id: 'map_vol_007',
        name: 'Lakshmi Nair',
        phone: '+919812340007',
        locality: 'Jayanagar',
        city: 'Bangalore',
        state: 'Karnataka',
        skills: ['Caregiver', 'Mental Health First Aid'],
        availability: 'available_now',
        consentGiven: true,
        latitude: userLatitude + 0.0008,
        longitude: userLongitude - 0.0038,
        isLocationShared: true,
      ),
    ];
  }

  // ============================================================
  // MOCK REAL-TIME STREAM - Simulates live volunteer movement
  // ============================================================

  /// Returns a stream that emits updated volunteer positions every
  /// [interval] seconds, simulating real-time movement.
  ///
  /// Each emission slightly drifts each volunteer's lat/lng to mimic
  /// someone walking around. Great for demoing without a Supabase backend.
  static Stream<List<Volunteer>> mockVolunteerLocationStream({
    required double userLatitude,
    required double userLongitude,
    Duration interval = const Duration(seconds: 3),
  }) {
    final rng = Random();
    List<Volunteer> current = generateMockMapVolunteers(
      userLatitude: userLatitude,
      userLongitude: userLongitude,
    );

    return Stream.periodic(interval, (tick) {
      // Drift each volunteer's position slightly (simulates walking)
      current = current.map((v) {
        // Random drift: ±0.00005 degrees ≈ ±5 meters
        final latDrift = (rng.nextDouble() - 0.5) * 0.0001;
        final lngDrift = (rng.nextDouble() - 0.5) * 0.0001;
        return Volunteer(
          id: v.id,
          name: v.name,
          phone: v.phone,
          locality: v.locality,
          city: v.city,
          state: v.state,
          skills: v.skills,
          availability: v.availability,
          consentGiven: v.consentGiven,
          latitude: (v.latitude ?? 0) + latDrift,
          longitude: (v.longitude ?? 0) + lngDrift,
          lastUpdated: DateTime.now(),
          isLocationShared: true,
        );
      }).toList();
      return current;
    });
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
