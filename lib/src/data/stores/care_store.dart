import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/care_data.dart';
import '../../models/plant.dart';
import '../../services/notification_service.dart';

class CareStore with ChangeNotifier {
  final List<CareTask> _tasks = [];
  final List<CareLog> _history = [];
  final Map<String, PlantCareStatus> _plantStatus = {};
  final List<UndoAction> _undoStack = [];
  final List<Achievement> _achievements = [];

  final Uuid _uuid = const Uuid();
  final NotificationService _notificationService = NotificationService();

  List<CareTask> get tasks => List.unmodifiable(_tasks);
  List<CareLog> get history => List.unmodifiable(_history);
  List<Achievement> get achievements => List.unmodifiable(_achievements);

  CareStore() {
    _notificationService.initialize();
    _load();
  }

  // ========== WATERING VALIDATION ==========

  bool canWaterToday(String plantId) {
    final status = _plantStatus[plantId];
    if (status == null) return true;

    final lastWatered = status.lastWateredDate;
    if (lastWatered == null) return true;

    final now = DateTime.now();
    return !isSameDay(lastWatered, now);
  }

  bool canFertilizeToday(String plantId) {
    final status = _plantStatus[plantId];
    if (status == null) return true;

    final lastFertilized = status.lastFertilizedDate;
    if (lastFertilized == null) return true;

    final now = DateTime.now();
    return !isSameDay(lastFertilized, now);
  }

  DateTime? getLastWateredTime(String plantId) {
    return _plantStatus[plantId]?.lastWateredDate;
  }

  DateTime? getLastFertilizedTime(String plantId) {
    return _plantStatus[plantId]?.lastFertilizedDate;
  }

  // ========== TASK QUERIES ==========

  List<CareTask> getTasksForDate(DateTime date) {
    return _tasks
        .where((t) => isSameDay(t.dueDate, date) && !t.isCompleted)
        .toList();
  }

  List<CareTask> get upcomingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks
        .where((t) => t.dueDate.isAfter(today) && !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<CareTask> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks
        .where((t) => t.dueDate.isBefore(today) && !t.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  // ========== COMPLETE TASK WITH FULL FEATURES ==========

  Future<bool> completeTask(CareTask task, Plant plant,
      {bool showUndo = true}) async {
    // 1. Validate one-time-per-day rule
    if (task.type == CareType.water && !canWaterToday(task.plantId)) {
      return false; // Already watered today
    }
    if (task.type == CareType.fertilize && !canFertilizeToday(task.plantId)) {
      return false; // Already fertilized today
    }

    // 2. Store previous state for undo
    final previousStatus = _plantStatus[task.plantId];

    // 3. Cancel notification
    await _notificationService.cancelNotification(task);

    // 4. Remove task
    _tasks.removeWhere((t) => t.id == task.id);

    // 5. Add to history
    final log = CareLog(
      id: _uuid.v4(),
      plantId: task.plantId,
      type: task.type,
      date: DateTime.now(),
    );
    _history.insert(0, log);

    // 5.1 Save to Firestore for persistence
    await _saveCareLogToFirestore(log);

    // 6. Update plant status
    _updatePlantStatus(task.plantId, task.type, plant);

    // 7. Check and unlock achievements
    _checkAchievements();

    // 8. Create undo action
    if (showUndo) {
      final undoAction = UndoAction(
        id: _uuid.v4(),
        action: log,
        timestamp: DateTime.now(),
        previousStatus: previousStatus,
      );
      _undoStack.add(undoAction);

      // Clean up expired undo actions
      _undoStack.removeWhere((u) => u.isExpired);
    }

    // 9. Schedule next task
    final nextDueDate = _calculateNextDueDate(task.type, plant);
    final nextTask = CareTask(
      id: _uuid.v4(),
      plantId: task.plantId,
      type: task.type,
      dueDate: nextDueDate,
    );
    _tasks.add(nextTask);
    await _notificationService.scheduleCaretask(nextTask, plant);

    notifyListeners();
    _save();
    return true;
  }

  // ========== UNDO FUNCTIONALITY ==========

  UndoAction? get lastUndoAction {
    if (_undoStack.isEmpty) return null;
    final last = _undoStack.last;
    return last.isExpired ? null : last;
  }

  Future<void> undoLastAction() async {
    if (_undoStack.isEmpty) return;

    final undoAction = _undoStack.removeLast();
    if (undoAction.isExpired) {
      notifyListeners();
      return;
    }

    // Remove from history
    _history.removeWhere((log) => log.id == undoAction.action.id);

    // Restore previous status
    if (undoAction.previousStatus != null) {
      _plantStatus[undoAction.action.plantId] = undoAction.previousStatus!;
    }

    notifyListeners();
    _save();
  }

  // ========== HEALTH & STREAK CALCULATION ==========

  void _updatePlantStatus(String plantId, CareType type, Plant plant) {
    final now = DateTime.now();
    var status = _plantStatus[plantId] ?? PlantCareStatus(plantId: plantId);

    // Update last care date
    if (type == CareType.water) {
      status = status.copyWith(lastWateredDate: now);
    } else if (type == CareType.fertilize) {
      status = status.copyWith(lastFertilizedDate: now);
    }

    // Update total care actions
    status = status.copyWith(totalCareActions: status.totalCareActions + 1);

    // Update streak
    final daysSinceLastCare = status.lastWateredDate != null
        ? now.difference(status.lastWateredDate!).inDays
        : 0;

    if (daysSinceLastCare <= 1) {
      // Continue streak
      status = status.copyWith(careStreak: status.careStreak + 1);
    } else {
      // Reset streak
      status = status.copyWith(
        careStreak: 1,
        streakStartDate: now,
      );
    }

    // Check perfect week
    if (status.careStreak >= 7) {
      status = status.copyWith(perfectWeek: true);
    }

    // Calculate health score
    final healthScore = _calculateHealthScore(plantId, plant, status);
    status = status.copyWith(healthScore: healthScore);

    _plantStatus[plantId] = status;
  }

  double _calculateHealthScore(
      String plantId, Plant plant, PlantCareStatus status) {
    double score = 50.0; // Base score

    // Streak bonus (max +30)
    score += min(status.careStreak * 2.0, 30.0);

    // Regular care bonus (max +20)
    if (status.lastWateredDate != null) {
      final daysSinceWater =
          DateTime.now().difference(status.lastWateredDate!).inDays;
      if (daysSinceWater <= plant.waterIntervalDays) {
        score += 20;
      } else if (daysSinceWater > plant.waterIntervalDays * 2) {
        score -= 15; // Penalty for neglect
      }
    }

    // Perfect week bonus
    if (status.perfectWeek) {
      score += 10;
    }

    // Prevent overwatering penalty
    if (status.lastWateredDate != null) {
      final hoursSinceWater =
          DateTime.now().difference(status.lastWateredDate!).inHours;
      if (hoursSinceWater < 12) {
        score -= 5; // Small penalty for frequent watering
      }
    }

    return score.clamp(0.0, 100.0);
  }

  DateTime _calculateNextDueDate(CareType type, Plant plant) {
    final now = DateTime.now();
    switch (type) {
      case CareType.water:
        return now.add(Duration(days: plant.waterIntervalDays));
      case CareType.fertilize:
        return now.add(Duration(days: plant.fertilizeIntervalDays));
      case CareType.prune:
        return now.add(const Duration(days: 90));
      case CareType.repot:
        return now.add(const Duration(days: 365));
    }
  }

  // ========== ACHIEVEMENTS ==========

  void _checkAchievements() {
    // First water
    if (_history.isNotEmpty && !_hasAchievement(AchievementType.firstWater)) {
      _unlockAchievement(AchievementType.firstWater);
    }

    // Care count milestones
    final totalCare = _history.length;
    if (totalCare >= 100 && !_hasAchievement(AchievementType.careCount100)) {
      _unlockAchievement(AchievementType.careCount100);
    } else if (totalCare >= 50 &&
        !_hasAchievement(AchievementType.careCount50)) {
      _unlockAchievement(AchievementType.careCount50);
    } else if (totalCare >= 10 &&
        !_hasAchievement(AchievementType.careCount10)) {
      _unlockAchievement(AchievementType.careCount10);
    }

    // Streak achievements
    for (var status in _plantStatus.values) {
      if (status.careStreak >= 90 &&
          !_hasAchievement(AchievementType.streak90)) {
        _unlockAchievement(AchievementType.streak90);
      } else if (status.careStreak >= 30 &&
          !_hasAchievement(AchievementType.streak30)) {
        _unlockAchievement(AchievementType.streak30);
      } else if (status.careStreak >= 14 &&
          !_hasAchievement(AchievementType.streak14)) {
        _unlockAchievement(AchievementType.streak14);
      } else if (status.careStreak >= 7 &&
          !_hasAchievement(AchievementType.streak7)) {
        _unlockAchievement(AchievementType.streak7);
      }

      if (status.perfectWeek && !_hasAchievement(AchievementType.perfectWeek)) {
        _unlockAchievement(AchievementType.perfectWeek);
      }
    }

    // Healthy garden (all plants > 80 health)
    if (_plantStatus.isNotEmpty &&
        _plantStatus.values.every((s) => s.healthScore >= 80) &&
        !_hasAchievement(AchievementType.healthyGarden)) {
      _unlockAchievement(AchievementType.healthyGarden);
    }
  }

  bool _hasAchievement(AchievementType type) {
    return _achievements.any((a) => a.type == type);
  }

  void _unlockAchievement(AchievementType type) {
    _achievements.add(Achievement.create(type));
  }

  // ========== INSIGHTS ==========

  PlantCareStatus? getPlantStatus(String plantId) {
    return _plantStatus[plantId];
  }

  int get totalCareStreak {
    if (_plantStatus.isEmpty) return 0;
    return _plantStatus.values.map((s) => s.careStreak).reduce(max);
  }

  double get averageHealthScore {
    if (_plantStatus.isEmpty) return 0;
    final total =
        _plantStatus.values.map((s) => s.healthScore).reduce((a, b) => a + b);
    return total / _plantStatus.length;
  }

  List<MapEntry<String, int>> getTopStreakPlants() {
    return _plantStatus.entries
        .map((e) => MapEntry(e.key, e.value.careStreak))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  // ========== SCHEDULE FOR PLANT ==========

  Future<void> scheduleForPlant(Plant plant) async {
    if (_tasks.any((t) => t.plantId == plant.id)) return;

    final now = DateTime.now();

    final waterTask = CareTask(
      id: _uuid.v4(),
      plantId: plant.id,
      type: CareType.water,
      dueDate: now.add(Duration(days: plant.waterIntervalDays)),
    );
    _tasks.add(waterTask);
    await _notificationService.scheduleCaretask(waterTask, plant);

    final fertilizeTask = CareTask(
      id: _uuid.v4(),
      plantId: plant.id,
      type: CareType.fertilize,
      dueDate: now.add(Duration(days: plant.fertilizeIntervalDays)),
    );
    _tasks.add(fertilizeTask);
    await _notificationService.scheduleCaretask(fertilizeTask, plant);

    // Initialize plant status
    _plantStatus[plant.id] = PlantCareStatus(plantId: plant.id);

    notifyListeners();
    _save();
  }

  // ========== HISTORY QUERIES ==========

  List<CareLog> getHistoryForMonth(int year, int month) {
    return _history.where((log) {
      return log.date.year == year && log.date.month == month;
    }).toList();
  }

  List<CareLog> getHistoryForDate(DateTime date) {
    return _history.where((log) {
      return isSameDay(log.date, date);
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // ========== PERSISTENCE ==========

  Future<void> _load() async {
    // TODO: Load from Firestore in future update
    // For now, just initialize empty
  }

  Future<void> _save() async {
    // TODO: Save to Firestore in future update
  }

  /// Save a care log locally (no-op in offline mode — data lives in memory)
  Future<void> _saveCareLogToFirestore(CareLog log) async {
    // Offline mode: care logs are stored in-memory via _history list.
    // No network or Firestore involved.
    debugPrint('✅ Care log recorded: ${log.type} for plant ${log.plantId}');
  }

  /// No-op in offline mode — history is stored in-memory.
  Future<void> loadFromFirestore(String userId) async {
    debugPrint('ℹ️  Offline mode: care history is in-memory only.');
  }
}
