import '../../models/user_plant.dart';
import 'firestore_service.dart';

/// Stub — Firestore removed for offline mode.
/// User plants are stored locally via SQLite through WateringStore.
class UserPlantsDatabase extends FirestoreService {
  Future<List<UserPlant>> getUserPlants(String userId) async => [];

  Future<UserPlant?> getUserPlant(String userPlantId) async => null;

  Future<String> addPlant(UserPlant userPlant) async => '';

  Future<void> updatePlant(
      String userPlantId, Map<String, dynamic> updates) async {}

  Future<void> removePlant(String userPlantId) async {}

  Stream<List<UserPlant>> watchUserPlants(String userId) =>
      const Stream.empty();

  Future<List<UserPlant>> getPlantsByLocation(
          String userId, String location) async =>
      [];
}
