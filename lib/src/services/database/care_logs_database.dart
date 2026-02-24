import '../../models/care_data.dart';
import 'firestore_service.dart';

/// Stub — Firestore removed for offline mode.
/// Care logs are stored locally via SQLite through CareStore.
class CareLogsDatabase extends FirestoreService {
  Future<String> logCare(CareLog careLog) async => '';

  Future<List<CareLog>> getCareLogs(String plantId, {int? limit}) async => [];

  Future<List<CareLog>> getRecentCareActivities(String userId,
          {int limit = 20}) async =>
      [];

  Future<List<CareLog>> getCareLogsByType(String plantId, CareType type,
          {int? limit}) async =>
      [];

  Future<List<CareLog>> getCareLogsInRange(
          String plantId, DateTime startDate, DateTime endDate) async =>
      [];

  Future<void> deleteCareLog(String careLogId) async {}

  Stream<List<CareLog>> watchCareLogs(String plantId) => const Stream.empty();
}
