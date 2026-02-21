import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteStore with ChangeNotifier {
  final Set<String> _ids = {};
  // bool _ready = false; // Removed unused field

  FavoriteStore() {
    _load();
  }

  bool isFavorite(String id) => _ids.contains(id);

  Future<void> toggle(String id) async {
    if (_ids.contains(id)) {
      _ids.remove(id);
    } else {
      _ids.add(id);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('fav_ids', _ids.toList());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('fav_ids');
    if (list != null) {
      _ids.addAll(list);
      notifyListeners();
    }
    // _ready = true;
  }
}
