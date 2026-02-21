import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_plant.dart';
import 'firestore_service.dart';

class UserPlantsDatabase extends FirestoreService {
  static const String _collection = 'user_plants';

  /// Get all plants for a user
  Future<List<UserPlant>> getUserPlants(String userId) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('addedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserPlant.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Get a specific user plant
  Future<UserPlant?> getUserPlant(String userPlantId) async {
    try {
      final doc =
          await firestore.collection(_collection).doc(userPlantId).get();
      if (!doc.exists) return null;
      return UserPlant.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Add plant to user's collection
  Future<String> addPlant(UserPlant userPlant) async {
    try {
      return await retryOperation(() async {
        final docRef = await firestore
            .collection(_collection)
            .add(userPlant.toFirestore());
        return docRef.id;
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Update user plant details
  Future<void> updatePlant(
      String userPlantId, Map<String, dynamic> updates) async {
    try {
      await retryOperation(() async {
        await firestore
            .collection(_collection)
            .doc(userPlantId)
            .update(updates);
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Remove plant from user's collection
  Future<void> removePlant(String userPlantId) async {
    try {
      await firestore.collection(_collection).doc(userPlantId).delete();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Listen to user's plants in real-time
  Stream<List<UserPlant>> watchUserPlants(String userId) {
    return firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('addedDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserPlant.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Get plants by location
  Future<List<UserPlant>> getPlantsByLocation(
      String userId, String location) async {
    try {
      final snapshot = await firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('location', isEqualTo: location)
          .orderBy('addedDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => UserPlant.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }
}
