import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// SQLite database helper for local plant storage
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    final String databasePath = join(appDocumentsDir.path, 'plant_database.db');

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Plants table
    await db.execute('''
      CREATE TABLE plants (
        id TEXT PRIMARY KEY,
        nameTh TEXT NOT NULL,
        nameEn TEXT NOT NULL,
        scientific TEXT NOT NULL,
        size TEXT NOT NULL,
        light TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        petSafe INTEGER NOT NULL,
        airPurifying INTEGER NOT NULL,
        waterIntervalDays INTEGER NOT NULL,
        fertilizeIntervalDays INTEGER NOT NULL,
        tags TEXT NOT NULL,
        description TEXT NOT NULL,
        temperature TEXT NOT NULL,
        humidity TEXT NOT NULL,
        soil TEXT NOT NULL,
        toxicity TEXT NOT NULL,
        image TEXT NOT NULL
      )
    ''');

    // Indexes for better query performance
    await db.execute('CREATE INDEX idx_plants_light ON plants(light)');
    await db
        .execute('CREATE INDEX idx_plants_difficulty ON plants(difficulty)');
    await db.execute('CREATE INDEX idx_plants_size ON plants(size)');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations here when schema changes
    if (oldVersion < 2) {
      // Example migration for version 2
      // await db.execute('ALTER TABLE plants ADD COLUMN newField TEXT');
    }
  }

  /// Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Clear all data (for testing/development)
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('plants');
  }

  /// Get database path (useful for debugging)
  Future<String> getDatabasePath() async {
    final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
    return join(appDocumentsDir.path, 'plant_database.db');
  }
}
