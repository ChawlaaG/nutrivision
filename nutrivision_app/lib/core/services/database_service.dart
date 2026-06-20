import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nutrivision_v2.db'); // Bumped version/name for clean slate

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add new tables for version 2
          await db.execute('''
            CREATE TABLE IF NOT EXISTS water_logs(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              amount_ml INTEGER NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
          
          await db.execute('''
            CREATE TABLE IF NOT EXISTS weight_logs(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL,
              weight_kg REAL NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE IF NOT EXISTS custom_foods(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              calories INTEGER NOT NULL,
              protein INTEGER NOT NULL,
              carbs INTEGER NOT NULL,
              fat INTEGER NOT NULL,
              serving_size TEXT
            )
          ''');



          await db.execute('''
            CREATE TABLE IF NOT EXISTS barcode_cache(
              barcode TEXT PRIMARY KEY,
              data TEXT NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    // Meals Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        calories INTEGER,
        protein INTEGER,
        carbs INTEGER,
        fat INTEGER,
        image_path TEXT,
        timestamp INTEGER,
        meal_type TEXT
      )
    ''');

    // Water Logs Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS water_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount_ml INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Weight Logs Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS weight_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        weight_kg REAL NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Custom Foods Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories INTEGER NOT NULL,
        protein INTEGER NOT NULL,
        carbs INTEGER NOT NULL,
        fat INTEGER NOT NULL,
        serving_size TEXT
      )
    ''');

    // Sync Queue Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        action TEXT NOT NULL,
        row_id INTEGER NOT NULL,
        payload TEXT,
        timestamp INTEGER NOT NULL
      )
    ''');

    // Barcode Cache Table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS barcode_cache(
        barcode TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // --- Generic Helpers ---

  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> query(String table, {String? where, List<Object?>? whereArgs, String? orderBy}) async {
    final db = await database;
    return await db.query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  Future<int> update(String table, Map<String, dynamic> data, String where, List<Object?> whereArgs) async {
    final db = await database;
    return await db.update(table, data, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(String table, String where, List<Object?> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }
}
