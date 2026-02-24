import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';

class UserProfileStore with ChangeNotifier {
  static const _keyName = 'offline_user_name';
  static const _keyEmail = 'offline_user_email';
  static const _keyPhotoPath = 'offline_user_photo_path';

  UserProfile? _profile;
  UserProfile? get profile => _profile;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProfileStore() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName) ?? 'Plant Lover';
    final email = prefs.getString(_keyEmail) ?? '';
    final photoPath = prefs.getString(_keyPhotoPath);

    _profile = UserProfile(
      id: 'local',
      displayName: name,
      email: email,
      photoURL: null,
      customPhotoURL: photoPath,
    );
    notifyListeners();
  }

  Future<void> _save() async {
    if (_profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (_profile!.displayName != null) {
      await prefs.setString(_keyName, _profile!.displayName!);
    }
    if (_profile!.email != null) {
      await prefs.setString(_keyEmail, _profile!.email!);
    }
    if (_profile!.customPhotoURL != null) {
      await prefs.setString(_keyPhotoPath, _profile!.customPhotoURL!);
    } else {
      await prefs.remove(_keyPhotoPath);
    }
  }

  Future<void> updateDisplayName(String newName) async {
    if (newName.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();

    _profile = _profile?.copyWith(displayName: newName.trim()) ??
        UserProfile(
          id: 'local',
          displayName: newName.trim(),
          email: '',
          photoURL: null,
        );

    await _save();
    // Also update the shared prefs key used by AuthGate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, newName.trim());

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfilePicture(ImageSource source) async {
    _isLoading = true;
    notifyListeners();

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Copy file to app documents directory (persists across sessions)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '${appDir.path}/$fileName';

      // Delete old custom photo if exists
      final oldPath = _profile?.customPhotoURL;
      if (oldPath != null) {
        try {
          final old = File(oldPath);
          if (await old.exists()) await old.delete();
        } catch (_) {}
      }

      await File(picked.path).copy(destPath);

      _profile = _profile?.copyWith(customPhotoURL: destPath) ??
          UserProfile(
            id: 'local',
            displayName: 'Plant Lover',
            email: '',
            photoURL: null,
            customPhotoURL: destPath,
          );

      await _save();
    } catch (e) {
      debugPrint('Error updating profile picture: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeProfilePicture() async {
    if (_profile?.customPhotoURL == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final file = File(_profile!.customPhotoURL!);
      if (await file.exists()) await file.delete();
    } catch (_) {}

    _profile = _profile?.copyWith(customPhotoURL: null);
    await _save();

    _isLoading = false;
    notifyListeners();
  }

  void refresh() => _load();
}
