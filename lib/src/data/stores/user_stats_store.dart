import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStatsStore with ChangeNotifier {
  int _xp = 0;
  int get xp => _xp;

  int get level => (_xp / 100).floor() + 1;
  int get nextLevelXp => level * 100;
  double get progress => (_xp % 100) / 100;

  UserStatsStore() {
    _load();
  }

  Future<void> addXp(int amount) async {
    _xp += amount;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_xp', _xp);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _xp = prefs.getInt('user_xp') ?? 0;
    notifyListeners();
  }
}
