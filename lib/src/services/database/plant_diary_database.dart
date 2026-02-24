import '../../models/diary_entry.dart';
import 'firestore_service.dart';

/// Stub — Firestore removed for offline mode.
/// Diary entries are stored locally via SQLite through PlantDiaryScreen.
class PlantDiaryDatabase extends FirestoreService {
  Future<String> addEntry(DiaryEntry entry) async => '';

  Future<List<DiaryEntry>> getEntriesForPlant(String plantId,
          {int? limit}) async =>
      [];

  Future<List<DiaryEntry>> getUserDiary(String userId,
          {int limit = 50}) async =>
      [];

  Future<void> updateNotes(String entryId, String notes) async {}

  Future<void> deleteEntry(String entryId) async {}

  Stream<List<DiaryEntry>> watchPlantDiary(String plantId) =>
      const Stream.empty();

  Future<int> getEntryCount(String plantId) async => 0;
}
