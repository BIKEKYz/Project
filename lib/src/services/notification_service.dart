import '../models/care_data.dart';
import '../models/plant.dart';

// Simplified notification service without external dependencies
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;
  bool _notificationsEnabled = false; // Disabled by default

  Future<void> initialize() async {
    if (_initialized) return;
    // No external packages needed
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    // Return true to indicate permissions granted (no-op)
    return true;
  }

  Future<void> scheduleCaretask(
    CareTask task,
    Plant plant,
  ) async {
    // No-op - notifications disabled
    // Can be implemented later with proper packages
  }

  Future<void> cancelNotification(CareTask task) async {
    // No-op
  }

  Future<void> cancelAllNotifications() async {
    // No-op
  }

  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  bool get notificationsEnabled => _notificationsEnabled;
}
