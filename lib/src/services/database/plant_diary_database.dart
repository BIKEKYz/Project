import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/diary_entry.dart';
import 'firestore_service.dart';

class PlantDiaryDatabase extends FirestoreService {
  static const String _collection = 'plant_diary';

  /// Add a new diary entry
  Future<String> addEntry(DiaryEntry entry) async {
    try {
      return await retryOperation(() async {
        final docRef =
            await firestore.collection(_collection).add(entry.toFirestore());
        return docRef.id;
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get diary entries for a specific plant
  Future<List<DiaryEntry>> getEntriesForPlant(
    String plantId, {
    int? limit,
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('plantId', isEqualTo: plantId)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DiaryEntry.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get all diary entries for a user
  Future<List<DiaryEntry>> getUserDiary(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return DiaryEntry.fromFirestore(data, doc.id);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Update diary entry notes
  Future<void> updateNotes(String entryId, String notes) async {
    try {
      await firestore.collection(_collection).doc(entryId).update({
        'notes': notes,
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Delete a diary entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await firestore.collection(_collection).doc(entryId).delete();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Watch diary entries for a plant in real-time
  Stream<List<DiaryEntry>> watchPlantDiary(String plantId) {
    return firestore
        .collection(_collection)
        .where('plantId', isEqualTo: plantId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return DiaryEntry.fromFirestore(data, doc.id);
            }).toList());
  }

  /// Get total entry count for a plant
  Future<int> getEntryCount(String plantId) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('plantId', isEqualTo: plantId)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception(handleError(e));
    }
  }
}
