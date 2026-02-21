import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/plant.dart';

class WateringStore with ChangeNotifier {
  final Map<String, DateTime> _lastWatered = {};
  // bool _ready = false; // Removed unused field

  WateringStore() {
    _load();
  }

  DateTime? getLastWatered(String id) => _lastWatered[id];

  DateTime nextWatering(Plant plant) {
    final last = _lastWatered[plant.id];
    if (last == null) return DateTime.now(); // Water now if never watered
    return last.add(Duration(days: plant.waterIntervalDays));
  }

  Future<void> setNow(String id) async {
    _lastWatered[id] = DateTime.now();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('water_$id', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final k in keys) {
      if (k.startsWith('water_')) {
        final id = k.substring(6);
        final ms = prefs.getInt(k);
        if (ms != null) {
          _lastWatered[id] = DateTime.fromMillisecondsSinceEpoch(ms);
        }
      }
    }
    notifyListeners();
    // _ready = true;
  }
}
