import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/app_settings.dart';
import '../../services/database/app_settings_database.dart';

class AppSettingsStore with ChangeNotifier {
  AppSettings? _settings;
  bool _isLoading = false;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  String get wateringSound => _settings?.wateringSound ?? 'default';
  String get language => _settings?.language ?? 'th';
  bool get darkMode => _settings?.darkMode ?? false;

  Future<void> loadSettings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final db = AppSettingsDatabase();
      _settings = await db.getSettings(userId);

      // Create default settings if none exist
      if (_settings == null) {
        _settings = AppSettings(userId: userId);
        await db.saveSettings(_settings!);
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateWateringSound(String sound) async {
    if (_settings == null) return;

    try {
      _settings = _settings!.copyWith(
        wateringSound: sound,
        updatedAt: DateTime.now(),
      );

      final db = AppSettingsDatabase();
      await db.saveSettings(_settings!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating watering sound: $e');
      rethrow;
    }
  }

  Future<void> updateLanguage(String lang) async {
    if (_settings == null) return;

    try {
      _settings = _settings!.copyWith(
        language: lang,
        updatedAt: DateTime.now(),
      );

      final db = AppSettingsDatabase();
      await db.saveSettings(_settings!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating language: $e');
      rethrow;
    }
  }

  Future<void> toggleDarkMode() async {
    if (_settings == null) return;

    try {
      _settings = _settings!.copyWith(
        darkMode: !_settings!.darkMode,
        updatedAt: DateTime.now(),
      );

      final db = AppSettingsDatabase();
      await db.saveSettings(_settings!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling dark mode: $e');
      rethrow;
    }
  }
}
