import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nutrivision.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE food_logs ( 
  id $idType, 
  date $textType,
  meal_type $textType,
  image_path $textType,
  calories $integerType,
  protein_g $integerType,
  carbs_g $integerType,
  fat_g $integerType,
  is_synced INTEGER DEFAULT 0
  )
''');

    await db.execute('''
CREATE TABLE recipes (
  id $idType,
  name $textType,
  total_calories $integerType,
  total_protein $integerType,
  total_carbs $integerType,
  total_fat $integerType
)
''');

    await db.execute('''
CREATE TABLE recipe_ingredients (
  id $idType,
  recipe_id $integerType,
  name $textType,
  calories $integerType,
  protein_g $integerType,
  carbs_g $integerType,
  fat_g $integerType,
  FOREIGN KEY (recipe_id) REFERENCES recipes (id) ON DELETE CASCADE
)
''');
  }

  Future<int> createFoodLog(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('food_logs', row);
  }

  Future<List<Map<String, dynamic>>> getFoodLogsForDate(String date) async {
    final db = await instance.database;
    return await db.query(
      'food_logs',
      where: 'date = ?',
      whereArgs: [date],
    );
  }

  Future<Map<String, int>> getDailyMacros(String date) async {
    final db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        SUM(calories) as total_calories,
        SUM(protein_g) as total_protein,
        SUM(carbs_g) as total_carbs,
        SUM(fat_g) as total_fat
      FROM food_logs
      WHERE date = ?
    ''', [date]);

    if (result.isNotEmpty) {
      return {
        'calories': (result.first['total_calories'] as int?) ?? 0,
        'protein': (result.first['total_protein'] as int?) ?? 0,
        'carbs': (result.first['total_carbs'] as int?) ?? 0,
        'fat': (result.first['total_fat'] as int?) ?? 0,
      };
    }
    return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
  }
  Future<List<Map<String, dynamic>>> getAllFoodLogs() async {
    final db = await instance.database;
    return await db.query('food_logs');
  }

  Future<void> restoreFoodLogs(List<Map<String, dynamic>> logs) async {
    final db = await instance.database;
    final batch = db.batch();
    
    // Optional: Clear existing data before restore? 
    // For now, let's just insert and ignore conflicts or replace.
    // A full restore usually implies wiping old data or merging.
    // Let's wipe for simplicity of "Restore".
    batch.delete('food_logs');

    for (var log in logs) {
      batch.insert('food_logs', log);
    }
    await batch.commit(noResult: true);
  }
}
