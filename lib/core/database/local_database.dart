import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabase {
  static Database? _database;
  static const int _version = 2; // bumped from 1 → idempotency_key added
  static const String _dbName = 'alertguard.db';

  static Future<Database> get instance async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final fullPath = join(dbPath, _dbName);

    return openDatabase(
      fullPath,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_alerts (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        trigger_type      TEXT    NOT NULL,
        latitude          REAL,
        longitude         REAL,
        front_photo_path  TEXT,
        rear_photo_path   TEXT,
        is_test           INTEGER NOT NULL DEFAULT 0,
        created_at        TEXT    NOT NULL,
        retry_count       INTEGER NOT NULL DEFAULT 0,
        idempotency_key   TEXT    NOT NULL DEFAULT ''
      )
    ''');
  }

  // Handles upgrading existing installs that have version 1
  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Add idempotency_key to existing table
      await db.execute(
        "ALTER TABLE pending_alerts ADD COLUMN idempotency_key TEXT NOT NULL DEFAULT ''",
      );
      print('[DB] Migrated to version 2 — added idempotency_key');
    }
  }
}
