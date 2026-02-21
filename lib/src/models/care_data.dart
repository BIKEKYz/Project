import 'package:flutter/material.dart';

enum CareType {
  water,
  fertilize,
  prune,
  repot,
}

class CareTask {
  final String id;
  final String plantId;
  final CareType type;
  final DateTime dueDate;
  final bool isCompleted;

  CareTask({
    required this.id,
    required this.plantId,
    required this.type,
    required this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'type': type.name,
      'dueDate': dueDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory CareTask.fromJson(Map<String, dynamic> json) {
    return CareTask(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      type: CareType.values.firstWhere((e) => e.name == json['type']),
      dueDate: DateTime.parse(json['dueDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class CareLog {
  final String id;
  final String plantId;
  final CareType type;
  final DateTime date;
  final String? notes;

  CareLog({
    required this.id,
    required this.plantId,
    required this.type,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'type': type.name,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory CareLog.fromJson(Map<String, dynamic> json) {
    return CareLog(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      type: CareType.values.firstWhere((e) => e.name == json['type']),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory CareLog.fromFirestore(Map<String, dynamic> data) {
    return CareLog.fromJson(data);
  }
}

// Professional care status tracking
class PlantCareStatus {
  final String plantId;
  final DateTime? lastWateredDate;
  final DateTime? lastFertilizedDate;
  final int careStreak;
  final double healthScore;
  final DateTime streakStartDate;
  final int totalCareActions;
  final int missedDays;
  final bool perfectWeek; // 7 days streak

  PlantCareStatus({
    required this.plantId,
    this.lastWateredDate,
    this.lastFertilizedDate,
    this.careStreak = 0,
    this.healthScore = 50.0,
    DateTime? streakStartDate,
    this.totalCareActions = 0,
    this.missedDays = 0,
    this.perfectWeek = false,
  }) : streakStartDate = streakStartDate ?? DateTime.now();

  PlantCareStatus copyWith({
    String? plantId,
    DateTime? lastWateredDate,
    DateTime? lastFertilizedDate,
    int? careStreak,
    double? healthScore,
    DateTime? streakStartDate,
    int? totalCareActions,
    int? missedDays,
    bool? perfectWeek,
  }) {
    return PlantCareStatus(
      plantId: plantId ?? this.plantId,
      lastWateredDate: lastWateredDate ?? this.lastWateredDate,
      lastFertilizedDate: lastFertilizedDate ?? this.lastFertilizedDate,
      careStreak: careStreak ?? this.careStreak,
      healthScore: healthScore ?? this.healthScore,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      totalCareActions: totalCareActions ?? this.totalCareActions,
      missedDays: missedDays ?? this.missedDays,
      perfectWeek: perfectWeek ?? this.perfectWeek,
    );
  }

  String get healthLabel {
    if (healthScore >= 80) return 'Excellent';
    if (healthScore >= 60) return 'Good';
    if (healthScore >= 40) return 'Fair';
    return 'Needs Care';
  }

  String get healthLabelThai {
    if (healthScore >= 80) return 'ดีเยี่ยม';
    if (healthScore >= 60) return 'ดี';
    if (healthScore >= 40) return 'พอใช้';
    return 'ต้องดูแล';
  }

  Color get healthColor {
    if (healthScore >= 80) return const Color(0xFF4CAF50); // Green
    if (healthScore >= 60) return const Color(0xFF8BC34A); // Light green
    if (healthScore >= 40) return const Color(0xFFFFC107); // Amber
    return const Color(0xFFF44336); // Red
  }

  Map<String, dynamic> toJson() {
    return {
      'plantId': plantId,
      'lastWateredDate': lastWateredDate?.toIso8601String(),
      'lastFertilizedDate': lastFertilizedDate?.toIso8601String(),
      'careStreak': careStreak,
      'healthScore': healthScore,
      'streakStartDate': streakStartDate.toIso8601String(),
      'totalCareActions': totalCareActions,
      'missedDays': missedDays,
      'perfectWeek': perfectWeek,
    };
  }

  factory PlantCareStatus.fromJson(Map<String, dynamic> json) {
    return PlantCareStatus(
      plantId: json['plantId'] as String,
      lastWateredDate: json['lastWateredDate'] != null
          ? DateTime.parse(json['lastWateredDate'] as String)
          : null,
      lastFertilizedDate: json['lastFertilizedDate'] != null
          ? DateTime.parse(json['lastFertilizedDate'] as String)
          : null,
      careStreak: json['careStreak'] as int? ?? 0,
      healthScore: (json['healthScore'] as num?)?.toDouble() ?? 50.0,
      streakStartDate: json['streakStartDate'] != null
          ? DateTime.parse(json['streakStartDate'] as String)
          : null,
      totalCareActions: json['totalCareActions'] as int? ?? 0,
      missedDays: json['missedDays'] as int? ?? 0,
      perfectWeek: json['perfectWeek'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  factory PlantCareStatus.fromFirestore(Map<String, dynamic> data) {
    return PlantCareStatus.fromJson(data);
  }
}

// Undo action for reversible operations
class UndoAction {
  final String id;
  final CareLog action;
  final DateTime timestamp;
  final PlantCareStatus? previousStatus;

  UndoAction({
    required this.id,
    required this.action,
    required this.timestamp,
    this.previousStatus,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp).inSeconds > 30;
  }

  Duration get timeRemaining {
    const maxDuration = Duration(seconds: 30);
    final elapsed = DateTime.now().difference(timestamp);
    final remaining = maxDuration - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

// Achievement system
enum AchievementType {
  firstWater,
  streak7,
  streak14,
  streak30,
  streak90,
  perfectWeek,
  careCount10,
  careCount50,
  careCount100,
  healthyGarden, // All plants > 80 health
}

class Achievement {
  final AchievementType type;
  final String title;
  final String titleThai;
  final String description;
  final String descriptionThai;
  final String icon;
  final DateTime unlockedAt;

  Achievement({
    required this.type,
    required this.title,
    required this.titleThai,
    required this.description,
    required this.descriptionThai,
    required this.icon,
    required this.unlockedAt,
  });

  static Achievement create(AchievementType type) {
    switch (type) {
      case AchievementType.firstWater:
        return Achievement(
          type: type,
          title: 'First Drop',
          titleThai: 'หยดแรก',
          description: 'Watered your first plant',
          descriptionThai: 'รดน้ำพืชแรก',
          icon: '💧',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.streak7:
        return Achievement(
          type: type,
          title: 'Week Warrior',
          titleThai: 'นักรบสัปดาห์',
          description: '7 days care streak',
          descriptionThai: 'ดูแลติดต่อกัน 7 วัน',
          icon: '🔥',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.streak14:
        return Achievement(
          type: type,
          title: 'Two Weeks Champion',
          titleThai: 'แชมป์สองสัปดาห์',
          description: '14 days care streak',
          descriptionThai: 'ดูแลติดต่อกัน 14 วัน',
          icon: '⭐',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.streak30:
        return Achievement(
          type: type,
          title: 'Monthly Master',
          titleThai: 'ปรมาจารย์รายเดือน',
          description: '30 days care streak',
          descriptionThai: 'ดูแลติดต่อกัน 30 วัน',
          icon: '🌟',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.streak90:
        return Achievement(
          type: type,
          title: 'Season Legend',
          titleThai: 'ตำนานแห่งฤดู',
          description: '90 days care streak',
          descriptionThai: 'ดูแลติดต่อกัน 90 วัน',
          icon: '👑',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.perfectWeek:
        return Achievement(
          type: type,
          title: 'Perfect Week',
          titleThai: 'สัปดาห์แห่งความสมบูรณ์แบบ',
          description: 'Complete week without missing',
          descriptionThai: 'ดูแลครบทุกวันในหนึ่งสัปดาห์',
          icon: '✨',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.careCount10:
        return Achievement(
          type: type,
          title: 'Caring Beginner',
          titleThai: 'มือใหม่ใส่ใจ',
          description: '10 care actions',
          descriptionThai: 'ดูแลพืช 10 ครั้ง',
          icon: '🌱',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.careCount50:
        return Achievement(
          type: type,
          title: 'Dedicated Gardener',
          titleThai: 'คนสวนผู้ทุ่มเท',
          description: '50 care actions',
          descriptionThai: 'ดูแลพืช 50 ครั้ง',
          icon: '🌳',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.careCount100:
        return Achievement(
          type: type,
          title: 'Expert Botanist',
          titleThai: 'นักพฤกษศาสตร์ชำนาญการ',
          description: '100 care actions',
          descriptionThai: 'ดูแลพืช 100 ครั้ง',
          icon: '🏆',
          unlockedAt: DateTime.now(),
        );
      case AchievementType.healthyGarden:
        return Achievement(
          type: type,
          title: 'Perfect Garden',
          titleThai: 'สวนในฝัน',
          description: 'All plants healthy',
          descriptionThai: 'พืชทุกต้นสุขภาพดี',
          icon: '🌺',
          unlockedAt: DateTime.now(),
        );
    }
  }
}
