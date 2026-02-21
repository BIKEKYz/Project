import 'package:cloud_firestore/cloud_firestore.dart';

/// Base service for Firestore operations with error handling
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  /// Handle Firestore errors and convert to user-friendly messages
  String handleError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'คุณไม่มีสิทธิ์เข้าถึงข้อมูลนี้';
        case 'not-found':
          return 'ไม่พบข้อมูล';
        case 'already-exists':
          return 'ข้อมูลนี้มีอยู่แล้ว';
        case 'unavailable':
          return 'ไม่สามารถเชื่อมต่อกับเซิร์ฟเวอร์ได้';
        default:
          return 'เกิดข้อผิดพลาด: ${error.message}';
      }
    }
    return 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
  }

  /// Retry logic for operations that might fail due to network issues
  Future<T> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          rethrow;
        }
        await Future.delayed(delay * attempts);
      }
    }
    throw Exception('Operation failed after $maxRetries attempts');
  }
}
