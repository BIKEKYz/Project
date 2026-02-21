import 'package:sqflite/sqflite.dart';
import '../../models/plant.dart';
import 'database_helper.dart';

class PlantDatabase {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Insert or update a plant
  Future<void> insertPlant(Plant plant) async {
    final db = await _dbHelper.database;
    await db.insert(
      'plants',
      plant.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple plants (bulk operation)
  Future<void> insertPlants(List<Plant> plants) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (final plant in plants) {
      batch.insert(
        'plants',
        plant.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  /// Get plant by ID
  Future<Plant?> getPlant(String id) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Plant.fromJson(results.first);
  }

  /// Get all plants
  Future<List<Plant>> getAllPlants() async {
    final db = await _dbHelper.database;
    final results = await db.query('plants');
    return results.map((json) => Plant.fromJson(json)).toList();
  }

  /// Search plants by name (Thai or English)
  Future<List<Plant>> searchPlants(String query) async {
    final db = await _dbHelper.database;
    final lowerQuery = query.toLowerCase();

    final results = await db.query(
      'plants',
      where:
          'LOWER(nameTh) LIKE ? OR LOWER(nameEn) LIKE ? OR LOWER(scientific) LIKE ?',
      whereArgs: ['%$lowerQuery%', '%$lowerQuery%', '%$lowerQuery%'],
    );

    return results.map((json) => Plant.fromJson(json)).toList();
  }

  /// Filter plants by criteria
  Future<List<Plant>> filterPlants({
    Light? light,
    Difficulty? difficulty,
    SizeClass? size,
    bool? petSafe,
    bool? airPurifying,
  }) async {
    final db = await _dbHelper.database;
    final List<String> whereClauses = [];
    final List<dynamic> whereArgs = [];

    if (light != null) {
      whereClauses.add('light = ?');
      whereArgs.add(light.name);
    }

    if (difficulty != null) {
      whereClauses.add('difficulty = ?');
      whereArgs.add(difficulty.name);
    }

    if (size != null) {
      whereClauses.add('size = ?');
      whereArgs.add(size.name);
    }

    if (petSafe != null) {
      whereClauses.add('petSafe = ?');
      whereArgs.add(petSafe ? 1 : 0);
    }

    if (airPurifying != null) {
      whereClauses.add('airPurifying = ?');
      whereArgs.add(airPurifying ? 1 : 0);
    }

    final results = await db.query(
      'plants',
      where: whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    return results.map((json) => Plant.fromJson(json)).toList();
  }

  /// Get plants by tag
  Future<List<Plant>> getPlantsByTag(String tag) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'plants',
      where: 'tags LIKE ?',
      whereArgs: ['%$tag%'],
    );

    return results.map((json) => Plant.fromJson(json)).toList();
  }

  /// Get plants suitable for specific light conditions
  Future<List<Plant>> getPlantsByLight(Light light) async {
    final db = await _dbHelper.database;
    final results = await db.query(
      'plants',
      where: 'light = ?',
      whereArgs: [light.name],
    );

    return results.map((json) => Plant.fromJson(json)).toList();
  }

  /// Get beginner-friendly plants
  Future<List<Plant>> getBeginnerPlants() async {
    return filterPlants(difficulty: Difficulty.easy);
  }

  /// Get pet-safe plants
  Future<List<Plant>> getPetSafePlants() async {
    return filterPlants(petSafe: true);
  }

  /// Get air-purifying plants
  Future<List<Plant>> getAirPurifyingPlants() async {
    return filterPlants(airPurifying: true);
  }

  /// Delete a plant
  Future<void> deletePlant(String id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'plants',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get plant count
  Future<int> getPlantCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM plants');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if database is seeded
  Future<bool> isSeeded() async {
    final count = await getPlantCount();
    return count > 0;
  }
}
