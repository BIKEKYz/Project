import '../services/database/database_helper.dart';
import '../services/database/plant_database.dart';
import 'plant_repository.dart';

/// Initializes and seeds the local SQLite database with plant data
class DatabaseInitializer {
  final PlantDatabase _plantDb = PlantDatabase();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Initialize database and seed with plant data if needed
  Future<void> initialize() async {
    try {
      // Check if database is already seeded
      final isSeeded = await _plantDb.isSeeded();

      if (!isSeeded) {
        print('Seeding database with plant data...');
        await seedDatabase();
        print('Database seeded successfully');
      } else {
        print('Database already seeded');
      }
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  /// Seed database with plant data from repository
  Future<void> seedDatabase() async {
    final plants = PlantRepository.all();
    await _plantDb.insertPlants(plants);
  }

  /// Re-seed database (useful for updates)
  Future<void> reseedDatabase() async {
    await _dbHelper.clearAllData();
    await seedDatabase();
  }

  /// Get database path for debugging
  Future<String> getDatabasePath() async {
    return await _dbHelper.getDatabasePath();
  }
}
