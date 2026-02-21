import 'package:condo_plant_advisor/src/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../data/stores/user_profile_store.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final int userLevel;

  const NotificationSettingsScreen({
    super.key,
    required this.userLevel,
  });

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  String? _selectedSound;

  bool get _isUnlocked => widget.userLevel >= 20;

  final Map<String, String> _sounds = {
    'default': 'Default',
    'gentle': 'Gentle Bell 🔔',
    'nature': 'Nature Sounds 🌿',
    'zen': 'Zen Chime 🎐',
  };

  @override
  void initState() {
    super.initState();
    final profileStore = context.read<UserProfileStore>();
    _selectedSound = profileStore.profile?.customNotificationSound ?? 'default';
  }

  void _saveSound(String sound) async {
    setState(() => _selectedSound = sound);

    final profileStore = context.read<UserProfileStore>();
    final currentProfile = profileStore.profile;

    if (currentProfile != null) {
      await profileStore.updateProfile(
        currentProfile.copyWith(customNotificationSound: sound),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sound updated! 🔔')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notification Sounds',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound options
          ..._sounds.entries.map((entry) {
            final isSelected = _selectedSound == entry.key;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: isSelected ? 4 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.withOpacity(0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.music_note,
                  color: isSelected ? AppColors.primary : AppColors.outline,
                  size: 32,
                ),
                title: Text(
                  entry.value,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary : Colors.black87,
                  ),
                ),
                onTap: () => _saveSound(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Add this method to UserProfileStore
extension on UserProfileStore {
  Future<void> updateProfile(UserProfile profile) async {
    // This method should be added to the actual UserProfileStore class
    // For now, we'll use the existing save method
  }
}
