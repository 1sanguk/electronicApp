import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _db;

  DatabaseHelper._();

  static DatabaseHelper get instance {
    _instance ??= DatabaseHelper._();
    return _instance!;
  }

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'electronic_app.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        measured_at TEXT NOT NULL,
        value_ua REAL NOT NULL,
        method TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        touch_points INTEGER NOT NULL DEFAULT 1,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_summary (
        date TEXT PRIMARY KEY,
        avg_ua REAL NOT NULL,
        min_ua REAL NOT NULL,
        max_ua REAL NOT NULL,
        count INTEGER NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_measurements_date ON measurements(measured_at)',
    );
  }
}
