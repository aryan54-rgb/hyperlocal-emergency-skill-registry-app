// ============================================================
// EMERGENCY BROADCAST VIEWMODEL - Alert many responders at once
// ============================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/emergency_broadcast.dart';
import '../models/request_models.dart';
import '../models/volunteer.dart';

enum EmergencyBroadcastState { idle, sending, sent, error }

class EmergencyBroadcastViewModel extends ChangeNotifier {
  EmergencyBroadcastState _state = EmergencyBroadcastState.idle;
  EmergencyBroadcastRequest? _request;
  String? _errorMessage;
  bool _usedMockMode = false;

  EmergencyBroadcastState get state => _state;
  EmergencyBroadcastRequest? get request => _request;
  String? get errorMessage => _errorMessage;
  bool get isSending => _state == EmergencyBroadcastState.sending;
  bool get isSent => _state == EmergencyBroadcastState.sent;
  bool get usedMockMode => _usedMockMode;

  List<Volunteer> topResponders(List<Volunteer> responders, {int maxCount = 5}) {
    final max = maxCount < 3 ? 3 : maxCount;
    return responders.take(max).toList();
  }

  Future<void> alertAllNearbyHelpers({
    required String emergencyType,
    required double latitude,
    required double longitude,
    required List<Volunteer> responders,
  }) async {
    if (responders.isEmpty) {
      _setError('No nearby responders found to alert.');
      return;
    }

    final selectedResponders = topResponders(responders, maxCount: 5);

    _state = EmergencyBroadcastState.sending;
    _errorMessage = null;
    _usedMockMode = false;

    _request = EmergencyBroadcastRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      emergencyType: emergencyType,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
      responderAlerts: selectedResponders
          .map(
            (responder) => EmergencyResponderAlert(responder: responder),
          )
          .toList(),
    );
    notifyListeners();

    final backendResult = await ApiService.instance.broadcastEmergencyAlerts(
      EmergencyBroadcastRequestPayload(
        emergencyType: emergencyType,
        latitude: latitude,
        longitude: longitude,
        responderIds: selectedResponders.map((r) => r.id).toList(),
      ),
    );

    if (backendResult.isFailure) {
      _usedMockMode = true;
    }

    await Future.delayed(const Duration(seconds: 2));

    final acceptedResponder = _pickAcceptedResponder(selectedResponders);
    _request = _request?.copyWith(
      responderAlerts: _request!.responderAlerts.map((alert) {
        if (alert.responder.id == acceptedResponder.id) {
          return alert.copyWith(status: ResponderAlertStatus.accepted);
        }
        return alert.copyWith(status: ResponderAlertStatus.pending);
      }).toList(),
    );

    _state = EmergencyBroadcastState.sent;
    notifyListeners();
  }

  Volunteer _pickAcceptedResponder(List<Volunteer> responders) {
    for (final responder in responders) {
      if (responder.availability.toLowerCase() != 'busy') {
        return responder;
      }
    }
    return responders.first;
  }

  void reset() {
    _state = EmergencyBroadcastState.idle;
    _request = null;
    _errorMessage = null;
    _usedMockMode = false;
    notifyListeners();
  }

  void _setError(String message) {
    _state = EmergencyBroadcastState.error;
    _errorMessage = message;
    notifyListeners();
  }
}
