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

  // ---- Emergency Types (Simplified Categories) ----
  static const List<String> emergencyTypes = [
    'Medical',
    'Fire',
    'Transport',
    'Women Safety',
    'Elderly Help',
    'Other',
  ];

  // ---- Emergency Type Icons & Colors ----
  /// Maps emergency type to display icon name and color for UI
  static const Map<String, Map<String, String>> emergencyTypeMetadata = {
    'Medical': {
      'icon': 'medical_services',
      'color': '#FF0000',
      'description': 'Medical emergencies requiring first aid or medical expertise',
    },
    'Fire': {
      'icon': 'local_fire_department',
      'color': '#FF6B00',
      'description': 'Fire incidents and fire safety emergencies',
    },
    'Transport': {
      'icon': 'directions_car',
      'color': '#0066FF',
      'description': 'Vehicle breakdowns and transportation assistance',
    },
    'Women Safety': {
      'icon': 'security',
      'color': '#FF1493',
      'description': 'Women safety support and escort assistance',
    },
    'Elderly Help': {
      'icon': 'accessibility',
      'color': '#8B7355',
      'description': 'Assistance for elderly citizens with daily needs',
    },
    'Other': {
      'icon': 'help',
      'color': '#808080',
      'description': 'Other community assistance needs',
    },
  };

  // ---- Skills ----
  static const List<String> availableSkills = [
    // Medical Skills
    'CPR Certified',
    'First Aid',
    'Medical Professional',
    'Nurse / Paramedic',
    
    // Emergency Response Skills
    'Firefighter',
    'Fire Safety',
    'Rescue Support',
    
    // Transport Skills
    'Emergency Driver',
    'Vehicle Repair',
    'Vehicle Owner',
    
    // Safety & Support Skills
    'Trusted Local Volunteer',
    'Escort Support',
    'Caregiver',
    
    // General Skills
    'AED Operation',
    'Basic Life Support',
    'Trauma Care',
    'Police / Security',
    'Lifeguard',
    'Mental Health First Aid',
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

  // ---- Emergency Matching Configuration ----
  static const double emergencyMatchDefaultRadiusKm = 5.0;
  static const int emergencyMatchMaxResponders = 10;
  static const int emergencyMatchTopRespodersToShow = 5;
  static const int emergencyMatchLocationTimeoutSeconds = 30;

  // ---- Mock Data Configuration ----
  /// TO ENABLE DEMO MODE: Open lib/core/mock_emergency_data.dart
  /// and change: useMockEmergencyData = false; → useMockEmergencyData = true;
  /// This allows testing without backend endpoint ready
  /// Mock data generates 5 realistic responders with varying distances/skills
  /// Backend endpoint is tracked: Returns EmergencyMatchResponse as specified

  // ---- Centralized Emergency Type → Skill Mapping ----
  /// Maps each emergency type to required/preferred volunteer skills
  /// Backend will match volunteers having ANY of these skills
  static const Map<String, List<String>> emergencyTypeSkillMap = {
    'Medical': [
      'CPR Certified',
      'First Aid',
      'Medical Professional',
      'Nurse / Paramedic',
      'Basic Life Support',
    ],
    'Fire': [
      'Firefighter',
      'Fire Safety',
      'Rescue Support',
    ],
    'Transport': [
      'Emergency Driver',
      'Vehicle Owner',
      'Vehicle Repair',
    ],
    'Women Safety': [
      'Trusted Local Volunteer',
      'Escort Support',
      'Police / Security',
    ],
    'Elderly Help': [
      'Caregiver',
      'First Aid',
      'Trusted Local Volunteer',
    ],
    'Other': [
      'Trusted Local Volunteer',
      'CPR Certified',
      'First Aid',
    ],
  };

  // ---- Helper Methods ----
  
  /// Get required skills for a given emergency type
  /// Returns empty list if emergency type is not found
  static List<String> getSkillsForEmergency(String emergencyType) {
    return emergencyTypeSkillMap[emergencyType] ?? [];
  }

  /// Get metadata (icon, color, description) for an emergency type
  /// Returns default 'Other' metadata if type not found
  static Map<String, String> getEmergencyMetadata(String emergencyType) {
    return emergencyTypeMetadata[emergencyType] ?? emergencyTypeMetadata['Other']!;
  }

  /// Check if a volunteer has any of the required skills for an emergency
  static bool volunteserHasRequiredSkill(
    List<String> volunteerSkills,
    String emergencyType,
  ) {
    final requiredSkills = getSkillsForEmergency(emergencyType);
    return volunteerSkills.any((skill) => requiredSkills.contains(skill));
  }

}
