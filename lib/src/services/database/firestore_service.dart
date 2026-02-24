/// Stub — Firestore has been removed for offline standalone mode.
/// This file is kept as a no-op so existing imports don't break if referenced elsewhere.
class FirestoreService {
  String handleError(dynamic error) => error.toString();

  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 1,
    Duration delay = const Duration(milliseconds: 0),
  }) async {
    return await operation();
  }
}
