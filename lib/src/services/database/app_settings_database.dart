import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/app_settings.dart';

class AppSettingsDatabase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String collectionName = 'app_settings';

  Future<AppSettings?> getSettings(String userId) async {
    try {
      final doc = await _firestore.collection(collectionName).doc(userId).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['userId'] = userId; // Ensure userId is included
        return AppSettings.fromJson(data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to load settings: $e');
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(settings.userId)
          .set(settings.toJson(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save settings: $e');
    }
  }

  Future<void> deleteSettings(String userId) async {
    try {
      await _firestore.collection(collectionName).doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete settings: $e');
    }
  }
}
