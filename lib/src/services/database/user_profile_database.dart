import '../../models/user_profile.dart';
import 'firestore_service.dart';

/// Stub — replaced by UserProfileStore's SharedPreferences-based storage.
/// Kept so that any code referencing this class still compiles.
class UserProfileDatabase extends FirestoreService {
  Future<UserProfile?> getProfile(String userId) async => null;

  Future<void> saveProfile(UserProfile profile) async {}

  Future<void> updateProfile(
      String userId, Map<String, dynamic> updates) async {}

  Future<void> deleteProfile(String userId) async {}

  Stream<UserProfile?> watchProfile(String userId) => const Stream.empty();
}
