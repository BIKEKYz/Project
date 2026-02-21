import 'package:flutter/material.dart';

/// Represents a single activity event in the app
class ActivityEvent {
  final String id;
  final ActivityType type;
  final String plantName;
  final String plantEmoji;
  final DateTime timestamp;
  bool isRead;

  ActivityEvent({
    required this.id,
    required this.type,
    required this.plantName,
    required this.plantEmoji,
    required this.timestamp,
    this.isRead = false,
  });

  String get titleTh {
    switch (type) {
      case ActivityType.watered:
        return 'รดน้ำ $plantName แล้ว';
      case ActivityType.favorited:
        return 'บันทึก $plantName ลงสวน';
      case ActivityType.unfavorited:
        return 'นำ $plantName ออกจากสวน';
    }
  }

  String get titleEn {
    switch (type) {
      case ActivityType.watered:
        return 'Watered $plantName';
      case ActivityType.favorited:
        return 'Added $plantName to garden';
      case ActivityType.unfavorited:
        return 'Removed $plantName from garden';
    }
  }

  String title(String lang) => lang == 'en' ? titleEn : titleTh;

  String get icon {
    switch (type) {
      case ActivityType.watered:
        return '💧';
      case ActivityType.favorited:
        return '🌿';
      case ActivityType.unfavorited:
        return '🍂';
    }
  }

  Color get color {
    switch (type) {
      case ActivityType.watered:
        return const Color(0xFF4FC3F7);
      case ActivityType.favorited:
        return const Color(0xFF81C784);
      case ActivityType.unfavorited:
        return const Color(0xFFFF8A65);
    }
  }

  String timeAgo(String lang) {
    final diff = DateTime.now().difference(timestamp);
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} น.';
    if (diff.inSeconds < 60) {
      return lang == 'en' ? 'Just now • $timeStr' : 'เมื่อกี้ • $timeStr';
    } else if (diff.inMinutes < 60) {
      return lang == 'en'
          ? '${diff.inMinutes}m ago • $timeStr'
          : '${diff.inMinutes} นาทีที่แล้ว • $timeStr';
    } else if (diff.inHours < 24) {
      return lang == 'en'
          ? '${diff.inHours}h ago • $timeStr'
          : '${diff.inHours} ชั่วโมงที่แล้ว • $timeStr';
    } else {
      return lang == 'en'
          ? '${diff.inDays}d ago • $timeStr'
          : '${diff.inDays} วันที่แล้ว • $timeStr';
    }
  }
}

enum ActivityType { watered, favorited, unfavorited }

/// Store for managing real-time activity log
class ActivityStore with ChangeNotifier {
  final List<ActivityEvent> _events = [];

  List<ActivityEvent> get events => List.unmodifiable(_events);

  int get unreadCount => _events.where((e) => !e.isRead).length;

  bool get hasUnread => unreadCount > 0;

  /// Log a watering event
  void logWatered(String plantId, String plantName, String plantEmoji) {
    _addEvent(ActivityEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}_water_$plantId',
      type: ActivityType.watered,
      plantName: plantName,
      plantEmoji: plantEmoji,
      timestamp: DateTime.now(),
    ));
  }

  /// Log a favorite/unfavorite event
  void logFavorite(
      String plantId, String plantName, String plantEmoji, bool isFavorited) {
    _addEvent(ActivityEvent(
      id: '${DateTime.now().millisecondsSinceEpoch}_fav_$plantId',
      type: isFavorited ? ActivityType.favorited : ActivityType.unfavorited,
      plantName: plantName,
      plantEmoji: plantEmoji,
      timestamp: DateTime.now(),
    ));
  }

  void _addEvent(ActivityEvent event) {
    _events.insert(0, event); // newest first
    // Keep max 50 events
    if (_events.length > 50) {
      _events.removeRange(50, _events.length);
    }
    notifyListeners();
  }

  /// Mark all events as read
  void markAllRead() {
    for (final e in _events) {
      e.isRead = true;
    }
    notifyListeners();
  }

  /// Clear all events
  void clearAll() {
    _events.clear();
    notifyListeners();
  }
}
