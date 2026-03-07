import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_strings.dart';
import '../../data/stores/app_settings_store.dart';
import '../../data/stores/user_profile_store.dart';
import '../auth/login_screen.dart';

// ─── Sound definitions ────────────────────────────────────────────────────────
class _SoundOption {
  final String key;
  final String labelTh;
  final String labelEn;
  final String emoji;
  final String previewUrl;
  const _SoundOption({
    required this.key,
    required this.labelTh,
    required this.labelEn,
    required this.emoji,
    required this.previewUrl,
  });
  String label(String lang) => lang == 'en' ? labelEn : labelTh;
}

const _sounds = [
  _SoundOption(
    key: 'default',
    labelTh: 'เสียงเริ่มต้น',
    labelEn: 'Default',
    emoji: '🔔',
    previewUrl: 'sounds/sound_default.mp3',
  ),
  _SoundOption(
    key: 'chime',
    labelTh: 'เสียงระฆัง',
    labelEn: 'Chime',
    emoji: '🎵',
    previewUrl: 'sounds/sound_chime.mp3',
  ),
  _SoundOption(
    key: 'nature',
    labelTh: 'เสียงธรรมชาติ',
    labelEn: 'Nature',
    emoji: '🌿',
    previewUrl: 'sounds/sound_nature.mp3',
  ),
  _SoundOption(
    key: 'water',
    labelTh: 'เสียงน้ำ',
    labelEn: 'Water Drop',
    emoji: '💧',
    previewUrl: 'sounds/sound_water.mp3',
  ),
  _SoundOption(
    key: 'soft',
    labelTh: 'เสียงนุ่มนวล',
    labelEn: 'Soft Bell',
    emoji: '✨',
    previewUrl: 'sounds/sound_soft.mp3',
  ),
];

// ─── Settings Screen ──────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  final AppSettingsStore? settingsStore;
  final UserProfileStore? profileStore;

  const SettingsScreen({
    super.key,
    this.settingsStore,
    this.profileStore,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AudioPlayer _audio = AudioPlayer();
  String? _playingKey;

  AppSettingsStore? get store => widget.settingsStore;
  String get lang => store?.language ?? 'th';
  AppStrings get s => AppStrings.of(lang);

  User? get user => null;

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = widget.profileStore?.profile;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 80,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
              title: Text(
                lang == 'en' ? 'Settings' : 'ตั้งค่า',
                style: GoogleFonts.outfit(
                  color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Card ──────────────────────────────
                  _buildProfileCard(context, isDark, profile),
                  const SizedBox(height: 20),

                  // ── Appearance ────────────────────────────────
                  _sectionLabel(
                      lang == 'en' ? 'APPEARANCE' : 'การแสดงผล', isDark),
                  const SizedBox(height: 8),
                  _buildCard(
                    isDark,
                    children: [
                      _buildDarkModeRow(isDark),
                      _buildDivider(isDark),
                      _buildTextSizeRow(isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Notifications ─────────────────────────────
                  _sectionLabel(
                      lang == 'en' ? 'NOTIFICATIONS' : 'การแจ้งเตือน', isDark),
                  const SizedBox(height: 8),
                  _buildCard(
                    isDark,
                    children: [
                      _buildNotificationToggleRow(isDark),
                      _buildDivider(isDark),
                      _buildSoundRow(context, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Language ──────────────────────────────────
                  _sectionLabel(lang == 'en' ? 'LANGUAGE' : 'ภาษา', isDark),
                  const SizedBox(height: 8),
                  _buildCard(
                    isDark,
                    children: [
                      _buildLanguageRow(context, isDark),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Account ───────────────────────────────────
                  _sectionLabel(
                      lang == 'en' ? 'ACCOUNT' : 'บัญชีผู้ใช้', isDark),
                  const SizedBox(height: 8),
                  _buildCard(
                    isDark,
                    children: [
                      _buildActionRow(
                        isDark,
                        emoji: '🚪',
                        bgColor: isDark
                            ? const Color(0xFF3A2020)
                            : const Color(0xFFFFF0F0),
                        title: lang == 'en' ? 'Sign Out' : 'ออกจากระบบ',
                        titleColor: AppColors.error,
                        onTap: () => _confirmSignOut(context, isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── About ─────────────────────────────────────
                  _sectionLabel(lang == 'en' ? 'ABOUT' : 'เกี่ยวกับ', isDark),
                  const SizedBox(height: 8),
                  _buildAboutCard(isDark),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile Card ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard(BuildContext context, bool isDark, profile) {
    final name = profile?.displayName ?? 'Plant Lover';
    final email = profile?.email ?? '';
    final photoURL = profile?.profilePictureURL; // local file path
    final isLoading = widget.profileStore?.isLoading ?? false;

    return GestureDetector(
      onTap: () => _showEditProfileSheet(context, isDark, name, photoURL),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E3028) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0),
          ),
        ),
        child: Row(
          children: [
            // Avatar with camera overlay
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.10),
                  backgroundImage:
                      (photoURL != null && File(photoURL).existsSync())
                          ? FileImage(File(photoURL))
                          : null,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : (photoURL == null || !File(photoURL).existsSync())
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'P',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child:
                        const Icon(Icons.edit, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFD4E8DC)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF5A7A65)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFF5A7A65) : const Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit Profile Sheet ────────────────────────────────────────────────────────
  void _showEditProfileSheet(
      BuildContext context, bool isDark, String currentName, String? photoURL) {
    final nameController = TextEditingController(text: currentName);
    final sheetBg = isDark ? const Color(0xFF1A2820) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) {
            final profile = widget.profileStore?.profile;
            final latestPhoto = profile?.profilePictureURL ?? photoURL;
            final isLoading = widget.profileStore?.isLoading ?? false;

            return Container(
              decoration: BoxDecoration(
                color: sheetBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF3A5040)
                          : const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    lang == 'en' ? 'Edit Profile' : 'แก้ไขโปรไฟล์',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark ? const Color(0xFF7DC99A) : AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Avatar + photo buttons
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        backgroundImage: (latestPhoto != null &&
                                File(latestPhoto).existsSync())
                            ? FileImage(File(latestPhoto))
                            : null,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary)
                            : (latestPhoto == null ||
                                    !File(latestPhoto).existsSync())
                                ? Text(
                                    nameController.text.isNotEmpty
                                        ? nameController.text[0].toUpperCase()
                                        : 'P',
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Photo action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PhotoBtn(
                        icon: Icons.camera_alt_outlined,
                        label: lang == 'en' ? 'Camera' : 'กล้อง',
                        isDark: isDark,
                        onTap: isLoading
                            ? null
                            : () async {
                                try {
                                  await widget.profileStore
                                      ?.updateProfilePicture(
                                          ImageSource.camera);
                                  setSheet(() {});
                                  setState(() {});
                                } catch (_) {}
                              },
                      ),
                      const SizedBox(width: 12),
                      _PhotoBtn(
                        icon: Icons.photo_library_outlined,
                        label: lang == 'en' ? 'Gallery' : 'แกลเลอรี',
                        isDark: isDark,
                        onTap: isLoading
                            ? null
                            : () async {
                                try {
                                  await widget.profileStore
                                      ?.updateProfilePicture(
                                          ImageSource.gallery);
                                  setSheet(() {});
                                  setState(() {});
                                } catch (_) {}
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E3028)
                          : const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2A4035)
                            : const Color(0xFFE8E8E8),
                      ),
                    ),
                    child: TextField(
                      controller: nameController,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFFD4E8DC)
                            : const Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: lang == 'en' ? 'Display name' : 'ชื่อที่แสดง',
                        hintStyle: GoogleFonts.notoSansThai(
                          color: isDark
                              ? const Color(0xFF5A7A65)
                              : const Color(0xFFBDBDBD),
                        ),
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          color: AppColors.primary.withOpacity(0.7),
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final newName = nameController.text.trim();
                              if (newName.isNotEmpty) {
                                await widget.profileStore
                                    ?.updateDisplayName(newName);
                                setState(() {});
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              lang == 'en' ? 'Save' : 'บันทึก',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? const Color(0xFF5A7A65) : const Color(0xFFAAAAAA),
          ),
        ),
      );

  // ── Card wrapper ──────────────────────────────────────────────────────────────
  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ── Dark Mode Row ─────────────────────────────────────────────────────────────
  Widget _buildDarkModeRow(bool isDark) {
    final isOn = store?.darkMode ?? false;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          _SettingIcon(
            emoji: isOn ? '🌙' : '☀️',
            bgColor: isDark ? const Color(0xFF2A3550) : const Color(0xFFEEEBFF),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'en' ? 'Dark Mode' : 'โหมดมืด',
                  style: _titleStyle(isDark),
                ),
                const SizedBox(height: 2),
                Text(
                  isOn
                      ? (lang == 'en' ? 'Enabled' : 'เปิดใช้งาน')
                      : (lang == 'en' ? 'Disabled' : 'ปิดใช้งาน'),
                  style: _subStyle(isDark),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: isOn,
              onChanged: store == null
                  ? null
                  : (v) async {
                      await store!.toggleDarkMode();
                      setState(() {});
                    },
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  isDark ? const Color(0xFF3A4A40) : const Color(0xFFE0E0E0),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sound Row ─────────────────────────────────────────────────────────────────
  Widget _buildSoundRow(BuildContext context, bool isDark) {
    final currentKey = store?.wateringSound ?? 'default';
    final current = _sounds.firstWhere((s) => s.key == currentKey,
        orElse: () => _sounds.first);
    return InkWell(
      onTap: () => _showSoundSheet(context, isDark),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(
              emoji: '🔔',
              bgColor:
                  isDark ? const Color(0xFF2A3A28) : const Color(0xFFE8F5E9),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'en' ? 'Watering Sound' : 'เสียงแจ้งเตือนรดน้ำ',
                    style: _titleStyle(isDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${current.emoji} ${current.label(lang)}',
                    style: _subStyle(isDark),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF5A7A65) : const Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }

  // ── Language Row ──────────────────────────────────────────────────────────────
  Widget _buildLanguageRow(BuildContext context, bool isDark) {
    final flag = lang == 'en' ? '🇬🇧' : '🇹🇭';
    final name = lang == 'en' ? 'English' : 'ภาษาไทย';
    return InkWell(
      onTap: () => _showLanguageSheet(context, isDark),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(
              emoji: '🌐',
              bgColor:
                  isDark ? const Color(0xFF1E3040) : const Color(0xFFE3F2FD),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == 'en' ? 'Language' : 'ภาษา',
                    style: _titleStyle(isDark),
                  ),
                  const SizedBox(height: 2),
                  Text('$flag $name', style: _subStyle(isDark)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF5A7A65) : const Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }

  // ── Action Row ────────────────────────────────────────────────────────────────
  Widget _buildActionRow(
    bool isDark, {
    required String emoji,
    required Color bgColor,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            _SettingIcon(emoji: emoji, bgColor: bgColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: _titleStyle(isDark).copyWith(
                  color: titleColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? const Color(0xFF5A7A65) : const Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }

  // ── Sound Sheet ───────────────────────────────────────────────────────────────
  void _showSoundSheet(BuildContext context, bool isDark) {
    final currentKey = store?.wateringSound ?? 'default';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final sheetBg = isDark ? const Color(0xFF1A2820) : Colors.white;
          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A5040)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang == 'en'
                      ? 'Select Watering Sound'
                      : 'เลือกเสียงแจ้งเตือน',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  lang == 'en'
                      ? 'Tap ▶ to preview before selecting'
                      : 'กด ▶ เพื่อทดลองฟังก่อนเลือก',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF5A7A65) : AppColors.outline,
                  ),
                ),
                const SizedBox(height: 20),
                ..._sounds.map((sound) {
                  final isSelected = sound.key == currentKey;
                  final isPlaying = _playingKey == sound.key;
                  return _SoundTile(
                    sound: sound,
                    lang: lang,
                    isSelected: isSelected,
                    isPlaying: isPlaying,
                    isDark: isDark,
                    onPlay: () async {
                      if (isPlaying) {
                        await _audio.stop();
                        setSheetState(() => _playingKey = null);
                        setState(() => _playingKey = null);
                      } else {
                        await _audio.stop();
                        setSheetState(() => _playingKey = sound.key);
                        setState(() => _playingKey = sound.key);
                        await _audio.play(AssetSource(sound.previewUrl));
                        _audio.onPlayerComplete.listen((_) {
                          if (mounted) {
                            setSheetState(() => _playingKey = null);
                            setState(() => _playingKey = null);
                          }
                        });
                      }
                    },
                    onSelect: () async {
                      await _audio.stop();
                      Navigator.pop(ctx);
                      if (store != null) {
                        await store!.updateWateringSound(sound.key);
                        setState(() => _playingKey = null);
                      }
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Language Sheet ────────────────────────────────────────────────────────────
  void _showLanguageSheet(BuildContext context, bool isDark) {
    final sheetBg = isDark ? const Color(0xFF1A2820) : Colors.white;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF3A5040) : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              lang == 'en' ? 'Select Language' : 'เลือกภาษา',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF7DC99A) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            _LangTile(
              flag: '🇹🇭',
              name: 'ภาษาไทย',
              sub: 'Thai',
              isSelected: lang == 'th',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                if (store != null) {
                  await store!.updateLanguage('th');
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 10),
            _LangTile(
              flag: '🇬🇧',
              name: 'English',
              sub: 'อังกฤษ',
              isSelected: lang == 'en',
              isDark: isDark,
              onTap: () async {
                Navigator.pop(ctx);
                if (store != null) {
                  await store!.updateLanguage('en');
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Divider between rows ──────────────────────────────────────────────────────
  Widget _buildDivider(bool isDark) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Divider(
          height: 1,
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0),
        ),
      );

  // ── Text Size Row ─────────────────────────────────────────────────────────────
  Widget _buildTextSizeRow(bool isDark) {
    final current = store?.textScale ?? 1.0;
    final sizes = [
      (0.9, lang == 'en' ? 'S' : 'เล็ก', lang == 'en' ? 'A' : 'ก'),
      (1.0, lang == 'en' ? 'M' : 'กลาง', lang == 'en' ? 'Aa' : 'กก'),
      (1.15, lang == 'en' ? 'L' : 'ใหญ่', lang == 'en' ? 'Aaa' : 'กกก'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          _SettingIcon(
            emoji: '✍️',
            bgColor: isDark ? const Color(0xFF2A3040) : const Color(0xFFEEF2FF),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'en' ? 'Text Size' : 'ขนาดตัวอักษร',
                  style: _titleStyle(isDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: sizes.map((s) {
                    final isActive = (current - s.$1).abs() < 0.01;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          await store?.updateTextScale(s.$1);
                          setState(() {});
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? const Color(0xFF1A2820)
                                    : const Color(0xFFF5F5F5)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive
                                  ? AppColors.primary
                                  : (isDark
                                      ? const Color(0xFF2A4035)
                                      : const Color(0xFFE0E0E0)),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                s.$3, // A / Aa / Aaa
                                style: TextStyle(
                                  fontSize: 13 * s.$1,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF7DC99A)
                                          : AppColors.textSecondary),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                s.$2, // เล็ก / กลาง / ใหญ่
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 9,
                                  color: isActive
                                      ? Colors.white70
                                      : (isDark
                                          ? const Color(0xFF5A7A65)
                                          : AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Notification Toggle Row ───────────────────────────────────────────────────
  Widget _buildNotificationToggleRow(bool isDark) {
    final isOn = store?.notificationsEnabled ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          _SettingIcon(
            emoji: isOn ? '🔔' : '🔕',
            bgColor: isDark ? const Color(0xFF2A3A28) : const Color(0xFFE8F5E9),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang == 'en' ? 'Notifications' : 'การแจ้งเตือน',
                  style: _titleStyle(isDark),
                ),
                const SizedBox(height: 2),
                Text(
                  isOn
                      ? (lang == 'en' ? 'Enabled' : 'เปิดใช้งาน')
                      : (lang == 'en' ? 'Disabled' : 'ปิดใช้งาน'),
                  style: _subStyle(isDark),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: isOn,
              onChanged: store == null
                  ? null
                  : (v) async {
                      await store!.toggleNotifications();
                      setState(() {});
                    },
              activeColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor:
                  isDark ? const Color(0xFF3A4A40) : const Color(0xFFE0E0E0),
            ),
          ),
        ],
      ),
    );
  }

  // ── About Card ────────────────────────────────────────────────────────────────
  Widget _buildAboutCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3028) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // App Icon placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(Icons.eco_rounded, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plantify 🪴',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFD4E8DC)
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang == 'en'
                      ? 'Version 1.0.0  •  Grow your sanctuary'
                      : 'เวอร์ชัน 1.0.0  •  ปลูกต้นไม้ ดูแลง่าย',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF5A7A65)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _titleStyle(bool isDark) => GoogleFonts.notoSansThai(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFFD4E8DC) : const Color(0xFF1A1A1A),
      );

  TextStyle _subStyle(bool isDark) => GoogleFonts.notoSansThai(
        fontSize: 12,
        color: isDark ? const Color(0xFF5A7A65) : const Color(0xFF9E9E9E),
      );

  // ── Sign-out confirmation ─────────────────────────────────────────────────────
  void _confirmSignOut(BuildContext context, bool isDark) {
    final name = widget.profileStore?.profile?.displayName ?? 'Plant Lover';
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E3028) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👋', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lang == 'en' ? 'Sign Out?' : 'ออกจากระบบ?',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? const Color(0xFFD4E8DC) : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                lang == 'en'
                    ? 'See you later, $name 🌿\nYour data will be saved.'
                    : 'แล้วเจอกันนะ $name 🌿\nข้อมูลของคุณจะยังคงอยู่',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF5A7A65)
                      : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2A4035)
                              : const Color(0xFFE0E0E0),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        lang == 'en' ? 'Cancel' : 'ยกเลิก',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFFD4E8DC)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool('offline_logged_in', false);
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (_) => const LoginSignupScreen()),
                            (_) => false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        lang == 'en' ? 'Sign Out' : 'ออกเลย',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class User {
  get displayName => null;

  get email => null;
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class _SettingIcon extends StatelessWidget {
  final String emoji;
  final Color bgColor;
  const _SettingIcon({required this.emoji, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
    );
  }
}

class _SoundTile extends StatelessWidget {
  final _SoundOption sound;
  final String lang;
  final bool isSelected;
  final bool isPlaying;
  final bool isDark;
  final VoidCallback onPlay;
  final VoidCallback onSelect;

  const _SoundTile({
    required this.sound,
    required this.lang,
    required this.isSelected,
    required this.isPlaying,
    required this.isDark,
    required this.onPlay,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor =
        isDark ? const Color(0xFF2A4035) : const Color(0xFFF1FBF4);
    final borderColor = isSelected
        ? AppColors.primary.withOpacity(0.5)
        : (isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0));

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor
              : (isDark ? const Color(0xFF1E3028) : const Color(0xFFFAFAFA)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Text(sound.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                sound.label(lang),
                style: GoogleFonts.notoSansThai(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isDark
                      ? const Color(0xFFD4E8DC)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            GestureDetector(
              onTap: onPlay,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? AppColors.primary
                      : (isDark
                          ? const Color(0xFF2A4035)
                          : AppColors.primary.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 20,
                  color: isPlaying ? Colors.white : AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangTile extends StatelessWidget {
  final String flag;
  final String name;
  final String sub;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LangTile({
    required this.flag,
    required this.name,
    required this.sub,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg =
        isDark ? const Color(0xFF2A4035) : const Color(0xFFF1FBF4);
    final borderColor = isSelected
        ? AppColors.primary.withOpacity(0.5)
        : (isDark ? const Color(0xFF2A4035) : const Color(0xFFF0F0F0));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedBg
              : (isDark ? const Color(0xFF1E3028) : const Color(0xFFFAFAFA)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isDark
                          ? const Color(0xFFD4E8DC)
                          : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF5A7A65)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Button ─────────────────────────────────────────────────────────────

class _PhotoBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _PhotoBtn({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3028)
                : AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A4035)
                  : AppColors.primary.withOpacity(0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
