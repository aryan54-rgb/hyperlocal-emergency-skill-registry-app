// ============================================================
// APP SETTINGS VIEWMODEL - Persisted user preferences
// ============================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class AppSettingsViewModel extends ChangeNotifier {
  bool _isDarkMode = true;
  bool _highContrast = false;
  bool _largeText = false;
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  bool get isDarkMode => _isDarkMode;
  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;

  double get textScaleFactor => _largeText ? 1.2 : 1.0;

  /// Call once during app startup to load stored prefs.
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.darkModeKey) ?? true;
    _highContrast = prefs.getBool(AppConstants.highContrastKey) ?? false;
    _largeText = prefs.getBool(AppConstants.largeTextKey) ?? false;
    _notificationsEnabled = prefs.getBool(AppConstants.notificationsKey) ?? true;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.darkModeKey, value);
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.highContrastKey, value);
  }

  Future<void> setLargeText(bool value) async {
    _largeText = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.largeTextKey, value);
  }

  Future<void> setNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.notificationsKey, value);
  }
}
