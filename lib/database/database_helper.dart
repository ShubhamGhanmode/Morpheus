// lib/database/database_helper.dart
import 'package:morpheus/config/app_config.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'morpheus.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Credit Cards Table
    await db.execute('''
      CREATE TABLE credit_cards (
        id TEXT PRIMARY KEY,
        card_holder_name TEXT NOT NULL,
        card_number TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        cvv TEXT NOT NULL,
        bank_name TEXT NOT NULL,
        card_network TEXT,
        card_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        billing_day INTEGER DEFAULT 1,
        grace_days INTEGER DEFAULT 15,
        usage_limit REAL,
        currency TEXT DEFAULT '${AppConfig.baseCurrency}',
        autopay_enabled INTEGER DEFAULT 0,
        reminder_enabled INTEGER DEFAULT 0,
        reminder_offsets TEXT,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Banking Information Table
    await db.execute('''
      CREATE TABLE banking_info (
        id TEXT PRIMARY KEY,
        bank_name TEXT NOT NULL,
        account_number TEXT NOT NULL,
        routing_number TEXT,
        account_type TEXT NOT NULL,
        login_id TEXT,
        login_password TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Passwords Table
    await db.execute('''
      CREATE TABLE passwords (
        id TEXT PRIMARY KEY,
        website TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    // Sync Queue Table (for offline changes)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,  -- INSERT, UPDATE, DELETE
        data TEXT,  -- JSON data for the record
        created_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN billing_day INTEGER DEFAULT 1',
      );
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN grace_days INTEGER DEFAULT 15',
      );
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN usage_limit REAL',
      );
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN reminder_enabled INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN reminder_offsets TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN card_network TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN currency TEXT DEFAULT \'${AppConfig.baseCurrency}\'',
      );
      await db.execute(
        'ALTER TABLE credit_cards ADD COLUMN autopay_enabled INTEGER DEFAULT 0',
      );
    }
  }
}
