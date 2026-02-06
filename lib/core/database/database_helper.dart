import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dose_time.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Initialize FFI for web
      databaseFactory = databaseFactoryFfiWeb;
      return await openDatabase(filePath, version: 5, onCreate: _createDB, onUpgrade: _onUpgrade);
    }
    
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE medications ADD COLUMN stock_quantity REAL');
      await db.execute('ALTER TABLE medications ADD COLUMN refill_threshold REAL');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE dose_logs ADD COLUMN medication_name TEXT');
      await db.execute('ALTER TABLE dose_logs ADD COLUMN medication_color INTEGER');
    }
    if (oldVersion < 4) {
      // New columns for enhanced medication management
      await db.execute('ALTER TABLE medications ADD COLUMN medication_type TEXT');
      await db.execute('ALTER TABLE medications ADD COLUMN instructions TEXT');
      await db.execute('ALTER TABLE medications ADD COLUMN start_date TEXT');
      await db.execute('ALTER TABLE medications ADD COLUMN end_date TEXT');
      await db.execute('ALTER TABLE medications ADD COLUMN image_path TEXT');
      await db.execute('ALTER TABLE medications ADD COLUMN is_archived INTEGER DEFAULT 0');
    }
    if (oldVersion < 5) {
      // Contacts table
      await db.execute('''
      CREATE TABLE contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        notes TEXT
      )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    await db.execute('''
    CREATE TABLE medications (
      id $idType,
      name $textType,
      dosage $textType,
      frequency $textType,
      times $textType,
      color $intType,
      icon $intNullable,
      stock_quantity REAL,
      refill_threshold REAL,
      medication_type TEXT,
      instructions TEXT,
      start_date TEXT,
      end_date TEXT,
      image_path TEXT,
      is_archived INTEGER DEFAULT 0
    )
    ''');

    await db.execute('''
    CREATE TABLE dose_logs (
      id $idType,
      medication_id $intType,
      medication_name TEXT,
      medication_color INTEGER,
      scheduled_time $textType,
      taken_time $textType, -- Nullable in logic, but passing string null needs care
      status $textType,
      FOREIGN KEY (medication_id) REFERENCES medications (id) ON DELETE CASCADE
    )
    ''');

    await db.execute('''
    CREATE TABLE contacts (
      id $idType,
      name $textType,
      type $textType,
      phone TEXT,
      email TEXT,
      address TEXT,
      notes TEXT
    )
    ''');
  }

  /// Delete all data from all tables
  Future<void> deleteAllData() async {
    final db = await instance.database;
    await db.delete('dose_logs');
    await db.delete('medications');
    await db.delete('contacts');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
