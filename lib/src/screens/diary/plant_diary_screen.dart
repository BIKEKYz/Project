import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/diary_entry.dart';
import '../../models/plant.dart';
import '../../services/database/plant_diary_database.dart';
import '../../theme/app_colors.dart';

class PlantDiaryScreen extends StatefulWidget {
  final Plant plant;

  const PlantDiaryScreen({
    super.key,
    required this.plant,
  });

  @override
  State<PlantDiaryScreen> createState() => _PlantDiaryScreenState();
}

class _PlantDiaryScreenState extends State<PlantDiaryScreen> {
  final PlantDiaryDatabase _diaryDb = PlantDiaryDatabase();
  final _uuid = const Uuid();
  bool _isLoading = false;

  Future<void> _addEntry() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (photo == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Upload to Firebase Storage
      final File file = File(photo.path);
      final String fileName =
          'diary/${widget.plant.id}/${_uuid.v4()}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(file);
      final String downloadURL = await ref.getDownloadURL();

      // Ask for notes
      final notes = await _askForNotes();

      // Create diary entry
      final entry = DiaryEntry(
        id: _uuid.v4(),
        userId: user.uid,
        plantId: widget.plant.id,
        photoUrl: downloadURL,
        notes: notes,
        date: DateTime.now(),
      );

      await _diaryDb.addEntry(entry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('📸 Memory saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _askForNotes() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Notes', style: GoogleFonts.outfit()),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'How is your plant doing?',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.plant.nameEn} Diary',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<DiaryEntry>>(
        stream: _diaryDb.watchPlantDiary(widget.plant.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];

          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No memories yet',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Capture your plant\'s growth journey!',
                    style: GoogleFonts.notoSansThai(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return _DiaryEntryCard(entry: entry);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addEntry,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.camera_alt),
        label: const Text('Add Memory'),
      ),
    );
  }
}

class _DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;

  const _DiaryEntryCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                entry.photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMMM d, y • h:mm a').format(entry.date),
                      style: GoogleFonts.outfit(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                // Notes
                if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    entry.notes!,
                    style: GoogleFonts.notoSansThai(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
