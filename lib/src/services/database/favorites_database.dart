import 'firestore_service.dart';

/// Stub — Firestore removed for offline mode.
/// Favorites are stored locally via SQLite through FavoriteStore.
class FavoritesDatabase extends FirestoreService {
  Future<List<String>> getFavorites(String userId) async => [];

  Future<void> addFavorite(String userId, String plantId) async {}

  Future<void> removeFavorite(String userId, String plantId) async {}

  Future<bool> isFavorite(String userId, String plantId) async => false;

  Future<void> toggleFavorite(String userId, String plantId) async {}

  Stream<List<String>> watchFavorites(String userId) => const Stream.empty();

  Future<void> clearFavorites(String userId) async {}
}
