// ============================================================
// EMERGENCY BROADCAST MODELS - Alert request + responder status
// ============================================================

import 'volunteer.dart';

enum ResponderAlertStatus { pending, accepted }

class EmergencyResponderAlert {
  final Volunteer responder;
  final ResponderAlertStatus status;

  const EmergencyResponderAlert({
    required this.responder,
    this.status = ResponderAlertStatus.pending,
  });

  EmergencyResponderAlert copyWith({
    Volunteer? responder,
    ResponderAlertStatus? status,
  }) {
    return EmergencyResponderAlert(
      responder: responder ?? this.responder,
      status: status ?? this.status,
    );
  }
}

class EmergencyBroadcastRequest {
  final String id;
  final String emergencyType;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final List<EmergencyResponderAlert> responderAlerts;

  const EmergencyBroadcastRequest({
    required this.id,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.responderAlerts,
  });

  int get notifiedCount => responderAlerts.length;

  EmergencyResponderAlert? get acceptedAlert {
    for (final alert in responderAlerts) {
      if (alert.status == ResponderAlertStatus.accepted) {
        return alert;
      }
    }
    return null;
  }

  EmergencyBroadcastRequest copyWith({
    String? id,
    String? emergencyType,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    List<EmergencyResponderAlert>? responderAlerts,
  }) {
    return EmergencyBroadcastRequest(
      id: id ?? this.id,
      emergencyType: emergencyType ?? this.emergencyType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      responderAlerts: responderAlerts ?? this.responderAlerts,
    );
  }
}
