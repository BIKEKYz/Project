import 'package:flutter/material.dart';
import '../../models/plant.dart';

class PlantFilter with ChangeNotifier {
  String query = '';
  Light? light;
  bool onlyPetSafe = false;
  bool onlyAirPurifying = false;
  Difficulty? difficulty;
  Aspect? aspect;

  bool get hasFilters =>
      light != null ||
      difficulty != null ||
      onlyPetSafe ||
      onlyAirPurifying ||
      aspect != null;

  void clear() {
    query = '';
    light = null;
    difficulty = null;
    onlyPetSafe = false;
    onlyAirPurifying = false;
    aspect = null;
    notifyListeners();
  }

  void setQuery(String q) {
    query = q.trim();
    notifyListeners();
  }

  void setLight(Light? l) {
    light = l;
    notifyListeners();
  }

  void setDifficulty(Difficulty? d) {
    difficulty = d;
    notifyListeners();
  }

  void togglePetSafe() {
    onlyPetSafe = !onlyPetSafe;
    notifyListeners();
  }

  void toggleAirPurifying() {
    onlyAirPurifying = !onlyAirPurifying;
    notifyListeners();
  }

  void setAspect(Aspect? a) {
    aspect = a;
    notifyListeners();
  }

  List<Plant> apply(List<Plant> src) {
    return src.where((p) {
      final q = query.toLowerCase();
      final okQ = q.isEmpty ||
          p.nameTh.toLowerCase().contains(q) ||
          p.nameEn.toLowerCase().contains(q) ||
          p.scientific.toLowerCase().contains(q) ||
          p.tags.any((t) => t.toLowerCase().contains(q));
      final okLight = light == null || p.light == light;
      final okDiff = difficulty == null || p.difficulty == difficulty;
      final okPet = !onlyPetSafe || p.petSafe;
      final okAir = !onlyAirPurifying || p.airPurifying;
      final okAspect =
          aspect == null || lightsForAspect(aspect!).contains(p.light);
      return okQ && okLight && okDiff && okPet && okAir && okAspect;
    }).toList();
  }

  Set<Light> lightsForAspect(Aspect aspect) {
    switch (aspect) {
      case Aspect.north:
        return {Light.low, Light.medium};
      case Aspect.east:
        return {Light.medium, Light.bright};
      case Aspect.west:
        return {Light.medium, Light.bright};
      case Aspect.south:
        return {Light.bright};
    }
  }
}
