import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_profile.dart';
import 'firestore_service.dart';

class UserProfileDatabase extends FirestoreService {
  static const String _collection = 'users';

  /// Get user profile by ID
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final doc = await firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Save or update user profile
  Future<void> saveProfile(UserProfile profile) async {
    try {
      await retryOperation(() async {
        await firestore
            .collection(_collection)
            .doc(profile.id)
            .set(profile.toFirestore(), SetOptions(merge: true));
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Update specific profile fields
  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {
    try {
      await retryOperation(() async {
        await firestore.collection(_collection).doc(userId).update(updates);
      });
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Delete user profile
  Future<void> deleteProfile(String userId) async {
    try {
      await firestore.collection(_collection).doc(userId).delete();
    } catch (e) {
      throw Exception(handleError(e));
    }
  }

  /// Listen to profile changes in real-time
  Stream<UserProfile?> watchProfile(String userId) {
    return firestore.collection(_collection).doc(userId).snapshots().map(
      (doc) {
        if (!doc.exists) return null;
        return UserProfile.fromFirestore(doc.data()!, doc.id);
      },
    );
  }
}
