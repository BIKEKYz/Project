import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/care_data.dart';
import '../models/plant.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'plantify_watering';
  static const _channelName = 'Watering Reminders';
  static const _channelDesc = 'Daily reminders to water your plants';

  bool _initialized = false;
  bool _notificationsEnabled = false;

  bool get notificationsEnabled => _notificationsEnabled;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
  }

  Future<bool> requestPermissions() async {
    final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;

    if (granted) {
      _notificationsEnabled = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', true);
    }
    return granted;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (!enabled) await cancelAllNotifications();
  }

  /// Schedule a daily watering reminder for a plant at 8 AM.
  Future<void> scheduleCaretask(CareTask task, Plant plant) async {
    if (!_notificationsEnabled) return;

    final id = plant.id.hashCode.abs() % 10000;

    await _plugin.zonedSchedule(
      id,
      '💧 Time to water ${plant.nameEn}!',
      'Your ${plant.nameEn} needs water. Keep it thriving! 🌿',
      _nextInstanceOfTime(8, 0),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2E7D32),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(CareTask task) async {
    // Cancellation by plant ID hash
    final id = task.plantId.hashCode.abs() % 10000;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllNotifications() => _plugin.cancelAll();

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
