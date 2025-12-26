// lib/database/database_helper.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/services/encryption_service.dart';
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

// lib/models/credit_card.dart
class CreditCard {
  String id;
  String cardHolderName;
  String cardNumber;
  String expiryDate;
  String cvv;
  String bankName;
  String cardType;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  bool isDeleted;

  CreditCard({
    required this.id,
    required this.cardHolderName,
    required this.cardNumber,
    required this.expiryDate,
    required this.cvv,
    required this.bankName,
    required this.cardType,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.isDeleted = false,
  });

  // Convert to encrypted map for local storage
  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'card_holder_name': EncryptionService.encryptData(cardHolderName),
      'card_number': EncryptionService.encryptData(cardNumber),
      'expiry_date': EncryptionService.encryptData(expiryDate),
      'cvv': EncryptionService.encryptData(cvv),
      'bank_name': EncryptionService.encryptData(bankName),
      'card_type': cardType,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  // Convert to encrypted map for Firebase
  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'cardHolderName': EncryptionService.encryptData(cardHolderName),
      'cardNumber': EncryptionService.encryptData(cardNumber),
      'expiryDate': EncryptionService.encryptData(expiryDate),
      'cvv': EncryptionService.encryptData(cvv),
      'bankName': EncryptionService.encryptData(bankName),
      'cardType': cardType,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
    };
  }

  // Create from local database
  static CreditCard fromLocalMap(Map<String, dynamic> map) {
    return CreditCard(
      id: map['id'],
      cardHolderName: EncryptionService.decryptData(map['card_holder_name']),
      cardNumber: EncryptionService.decryptData(map['card_number']),
      expiryDate: EncryptionService.decryptData(map['expiry_date']),
      cvv: EncryptionService.decryptData(map['cvv']),
      bankName: EncryptionService.decryptData(map['bank_name']),
      cardType: map['card_type'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      isDeleted: map['is_deleted'] == 1,
    );
  }

  // Create from Firebase
  static CreditCard fromFirebaseMap(String id, Map<String, dynamic> map) {
    return CreditCard(
      id: id,
      cardHolderName: EncryptionService.decryptData(map['cardHolderName']),
      cardNumber: EncryptionService.decryptData(map['cardNumber']),
      expiryDate: EncryptionService.decryptData(map['expiryDate']),
      cvv: EncryptionService.decryptData(map['cvv']),
      bankName: EncryptionService.decryptData(map['bankName']),
      cardType: map['cardType'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      isSynced: true,
      isDeleted: map['isDeleted'] ?? false,
    );
  }
}
