import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user_profile.dart';
import '../../services/database/user_profile_database.dart';

class UserProfileStore with ChangeNotifier {
  final UserProfileDatabase _profileDb = UserProfileDatabase();

  UserProfile? _profile;
  UserProfile? get profile => _profile;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  UserProfileStore() {
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Try to load from Firestore
      _profile = await _profileDb.getProfile(user.uid);

      // If profile doesn't exist in Firestore, create it
      if (_profile == null) {
        _profile = UserProfile(
          id: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
        );

        // Save to Firestore
        await _profileDb.saveProfile(_profile!);
      }
    } catch (e) {
      debugPrint('Error loading profile from Firestore: $e');

      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_profile');

      if (profileJson != null) {
        try {
          _profile = UserProfile.fromJson(Map<String, dynamic>.from(
              await Future.value(profileJson).then((json) => {
                    'id': user.uid,
                    'displayName': user.displayName,
                    'email': user.email,
                    'photoURL': user.photoURL,
                  })));
        } catch (_) {
          _profile = UserProfile(
            id: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL,
          );
        }
      } else {
        _profile = UserProfile(
          id: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
        );
      }
    }

    notifyListeners();
  }

  /// Save profile to both Firestore and local cache
  Future<void> _save() async {
    if (_profile == null) return;

    try {
      // Save to Firestore (primary storage)
      await _profileDb.saveProfile(_profile!);

      // Also save to local cache as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_profile', _profile!.toJson().toString());
    } catch (e) {
      debugPrint('Error saving profile: $e');

      // If Firestore fails, at least save locally
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile', _profile!.toJson().toString());
      } catch (_) {}
    }
  }

  Future<void> updateProfilePicture(ImageSource source) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Delete old custom photo if exists
      if (_profile?.customPhotoURL != null) {
        try {
          await FirebaseStorage.instance
              .refFromURL(_profile!.customPhotoURL!)
              .delete();
        } catch (e) {
          // Ignore if file doesn't exist
        }
      }

      // Upload to Firebase Storage
      final File file = File(pickedFile.path);
      final String fileName =
          'profile_pictures/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(file);
      final String downloadURL = await ref.getDownloadURL();

      // Update profile
      _profile = _profile?.copyWith(customPhotoURL: downloadURL) ??
          UserProfile(
            id: user.uid,
            displayName: user.displayName,
            email: user.email,
            photoURL: user.photoURL,
            customPhotoURL: downloadURL,
          );

      await _save();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeProfilePicture() async {
    if (_profile?.customPhotoURL == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Delete from Firebase Storage
      await FirebaseStorage.instance
          .refFromURL(_profile!.customPhotoURL!)
          .delete();

      // Update profile
      _profile = _profile?.copyWith(customPhotoURL: null);
      await _save();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update display name - saves to Firestore automatically
  Future<void> updateDisplayName(String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || newName.trim().isEmpty) return;

    try {
      _isLoading = true;
      notifyListeners();

      // Update profile
      _profile = _profile?.copyWith(displayName: newName.trim()) ??
          UserProfile(
            id: user.uid,
            displayName: newName.trim(),
            email: user.email,
            photoURL: user.photoURL,
          );

      // Save to Firestore (data will persist forever!)
      await _save();

      _isLoading = false;
      notifyListeners();

      debugPrint('✅ Profile saved to Firestore: ${_profile!.displayName}');
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void refresh() {
    _load();
  }
}
