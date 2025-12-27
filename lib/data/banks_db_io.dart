import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class BanksDb {
  static Database? _db;
  static const _assetDbPath = 'assets/tables/banks.sqlite';
  static const _dbFileName = 'banks.sqlite';

  static Future<Database> instance() async {
    if (_db != null) return _db!;

    // Desktop support (optional)
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      ffi.sqfliteFfiInit();
      databaseFactory = ffi.databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbFileName);

    // If not copied yet, copy from assets
    final file = File(dbPath);
    if (!await file.exists()) {
      final bytes = await rootBundle.load(_assetDbPath);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
    }

    _db = await openDatabase(dbPath, readOnly: true);
    return _db!;
  }

  /// Returns a small, alphabetized list of bank names filtered by [startsWith].
  /// Defaults to top 5 rows to keep UI fast; bump [limit] if you need more.
  static Future<List<String>> fetchBankNames({
    String startsWith = '',
    int limit = 5,
  }) async {
    final db = await instance();
    final rows = await db.query(
      'banks',
      columns: ['name'],
      where: startsWith.isNotEmpty ? 'name LIKE ?' : null,
      whereArgs: startsWith.isNotEmpty ? ['$startsWith%'] : null,
      orderBy: 'name COLLATE NOCASE ASC',
      limit: limit,
    );
    return rows.map((r) => r['name'] as String).toList();
  }

  // If you need id + ifsc later:
  static Future<List<Map<String, dynamic>>> fetchBanks() async {
    final db = await instance();
    return db.query(
      'banks',
      columns: ['id', 'name', 'ifsc', 'icon', 'website', 'cat_id'],
    );
  }

  static Future<String?> fetchBankIcon(String name) async {
    final db = await instance();
    final rows = await db.query(
      'banks',
      columns: ['icon'],
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['icon'] as String?;
  }
}
