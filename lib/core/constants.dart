// ============================================================
// CONSTANTS - Centralized configuration for the entire app
// ============================================================

class AppConstants {
  AppConstants._();

  // ---- API Configuration (change base URL here) ----
  static const String baseUrl = 'https://api.emergency-registry.example.com';
  static const String registerEndpoint = '/api/volunteers/register';
  static const String searchEndpoint = '/api/volunteers/search';
  static const int connectionTimeout = 15; // seconds
  static const int receiveTimeout = 15; // seconds

  // ---- App Info ----
  static const String appName = 'Emergency Skill Registry';
  static const String appVersion = '1.0.0';
  static const String contactEmail = 'support@emergency-registry.example.com';
  static const String teamName = 'Civic Tech Initiative';
  static final List<Map<String, String>> teamMembers = [
    {'name': 'Sarang Kolekar', 'role': 'Lead Developer'},
    {'name': 'Soham Kulkarni', 'role': 'UX Designer'},
    {'name': 'Aryan Surywanshi', 'role': 'Backend Engineer'},
    {'name': 'Ritobrata Baksi', 'role': 'Community Outreach'},
  ];

  // ---- Onboarding Preference Key ----
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String darkModeKey = 'dark_mode';
  static const String highContrastKey = 'high_contrast';
  static const String largeTextKey = 'large_text';
  static const String notificationsKey = 'notifications_enabled';

  // ---- Home Stats (displayed on home screen) ----
  static const int volunteersCount = 2400;
  static const int citiesCount = 38;

  // ---- Emergency Types ----
  static const List<String> emergencyTypes = [
    'Cardiac Arrest / CPR',
    'Choking',
    'Drowning',
    'Burns',
    'Severe Bleeding',
    'Fractures / Trauma',
    'Allergic Reaction',
    'Seizure',
    'Stroke',
    'Mental Health Crisis',
    'Road Accident',
    'Fire',
  ];

  // ---- Skills ----
  static const List<String> availableSkills = [
    'CPR Certified',
    'First Aid',
    'AED Operation',
    'Basic Life Support',
    'Trauma Care',
    'Drowning Rescue',
    'Fire Evacuation',
    'Mental Health First Aid',
    'Medical Professional',
    'Nurse / Paramedic',
    'Firefighter',
    'Police / Security',
    'Lifeguard',
    'Emergency Driver',
  ];

  // ---- Availability Options ----
  static const List<Map<String, String>> availabilityOptions = [
  {
    'value': 'available_now',
    'label': 'Available Now',
  },
  {
    'value': 'within_30_min',
    'label': 'Within 30 Minutes',
  },
  {
    'value': 'busy',
    'label': 'Currently Busy',
  },
];

}
