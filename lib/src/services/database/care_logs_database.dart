import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/care_data.dart';
import 'firestore_service.dart';

class CareLogsDatabase extends FirestoreService {
  static const String _collection = 'care_logs';

  /// Log a care action
  Future<String> logCare(CareLog careLog) async {
    try {
      return await retryOperation(() async {
        final docRef =
            await firestore.collection(_collection).add(careLog.toFirestore());
        return docRef.id;
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get care logs for a specific plant
  Future<List<CareLog>> getCareLogs(String plantId, {int? limit}) async {
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
        data['id'] = doc.id;
        return CareLog.fromFirestore(data);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get recent care activities for a user (across all plants)
  Future<List<CareLog>> getRecentCareActivities(String userId,
      {int limit = 20}) async {
    try {
      // Note: This requires userId to be added to CareLog model and stored
      // For now, we'll get all recent care logs
      final snapshot = await firestore
          .collection(_collection)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CareLog.fromFirestore(data);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get care logs by type
  Future<List<CareLog>> getCareLogsByType(
    String plantId,
    CareType type, {
    int? limit,
  }) async {
    try {
      Query query = firestore
          .collection(_collection)
          .where('plantId', isEqualTo: plantId)
          .where('type', isEqualTo: type.name)
          .orderBy('date', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CareLog.fromFirestore(data);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get care logs within a date range
  Future<List<CareLog>> getCareLogsInRange(
    String plantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('plantId', isEqualTo: plantId)
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return CareLog.fromFirestore(data);
      }).toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Delete a care log
  Future<void> deleteCareLog(String careLogId) async {
    try {
      await firestore.collection(_collection).doc(careLogId).delete();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Listen to care logs for a plant in real-time
  Stream<List<CareLog>> watchCareLogs(String plantId) {
    return firestore
        .collection(_collection)
        .where('plantId', isEqualTo: plantId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return CareLog.fromFirestore(data);
            }).toList());
  }
}
