// ============================================================
// SEARCH VIEWMODEL - Manages volunteer search state & API
// ============================================================

import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../models/volunteer.dart';

enum SearchState { idle, loading, success, empty, error }

class SearchViewModel extends ChangeNotifier {
  SearchState _state = SearchState.idle;
  List<Volunteer> _volunteers = [];
  String? _errorMessage;
  ApiErrorType? _errorType;

  SearchState get state => _state;
  List<Volunteer> get volunteers => _volunteers;
  String? get errorMessage => _errorMessage;
  ApiErrorType? get errorType => _errorType;
  bool get isLoading => _state == SearchState.loading;

  String locality = '';
  String emergencyType = '';

  Future<void> search() async {
    if (locality.trim().isEmpty || emergencyType.isEmpty) return;

    _state = SearchState.loading;
    _volunteers = [];
    _errorMessage = null;
    notifyListeners();

    final result = await ApiService.instance.searchVolunteers(
      locality: locality.trim(),
      emergencyType: emergencyType,
    );

    if (result.isSuccess) {
      _volunteers = result.data!.volunteers;
      _state = _volunteers.isEmpty ? SearchState.empty : SearchState.success;
    } else {
      _errorMessage = result.error;
      _errorType = result.errorType;
      _state = SearchState.error;
    }
    notifyListeners();

  }

  void setEmergencyType(String value) {
    emergencyType = value;
    notifyListeners();
  }

  void reset() {
    _state = SearchState.idle;
    _volunteers = [];
    _errorMessage = null;
    locality = '';
    emergencyType = '';
    notifyListeners();
  }
}
