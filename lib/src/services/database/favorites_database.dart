import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';

class FavoritesDatabase extends FirestoreService {
  static const String _collection = 'favorites';

  /// Get user's favorite plant IDs
  Future<List<String>> getFavorites(String userId) async {
    try {
      final doc = await firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data();
      final plantIds = data?['plantIds'] as List<dynamic>?;
      return plantIds?.cast<String>() ?? [];
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Add plant to favorites
  Future<void> addFavorite(String userId, String plantId) async {
    try {
      await retryOperation(() async {
        await firestore.collection(_collection).doc(userId).set({
          'plantIds': FieldValue.arrayUnion([plantId]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Remove plant from favorites
  Future<void> removeFavorite(String userId, String plantId) async {
    try {
      await retryOperation(() async {
        await firestore.collection(_collection).doc(userId).update({
          'plantIds': FieldValue.arrayRemove([plantId]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Check if plant is favorite
  Future<bool> isFavorite(String userId, String plantId) async {
    try {
      final favorites = await getFavorites(userId);
      return favorites.contains(plantId);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String userId, String plantId) async {
    final isFav = await isFavorite(userId, plantId);
    if (isFav) {
      await removeFavorite(userId, plantId);
    } else {
      await addFavorite(userId, plantId);
    }
  }

  /// Listen to favorites in real-time
  Stream<List<String>> watchFavorites(String userId) {
    return firestore.collection(_collection).doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      final plantIds = data?['plantIds'] as List<dynamic>?;
      return plantIds?.cast<String>() ?? [];
    });
  }

  /// Clear all favorites
  Future<void> clearFavorites(String userId) async {
    try {
      await firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }
}
