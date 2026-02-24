import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';

/// Offline replacement for the old Firestore-based AppSettingsDatabase.
/// All settings are persisted to SharedPreferences.
class AppSettingsDatabase {
  static const _keySound = 'settings_watering_sound';
  static const _keyLanguage = 'settings_language';
  static const _keyDarkMode = 'settings_dark_mode';

  Future<AppSettings?> getSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      userId: userId,
      wateringSound: prefs.getString(_keySound) ?? 'default',
      language: prefs.getString(_keyLanguage) ?? 'th',
      darkMode: prefs.getBool(_keyDarkMode) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySound, settings.wateringSound);
    await prefs.setString(_keyLanguage, settings.language);
    await prefs.setBool(_keyDarkMode, settings.darkMode);
  }

  Future<void> deleteSettings(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySound);
    await prefs.remove(_keyLanguage);
    await prefs.remove(_keyDarkMode);
  }
}
