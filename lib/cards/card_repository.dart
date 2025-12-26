import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/database/database_helper.dart' show DatabaseHelper;
import 'package:morpheus/services/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Persists credit cards locally (SQLite) and in Firestore under the user node.
class CardRepository {
  CardRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    DatabaseHelper? databaseHelper,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _dbHelper = databaseHelper ?? DatabaseHelper();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final DatabaseHelper _dbHelper;
  static const _cacheUidKey = 'cards.cacheUid';

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _remoteCollection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('cards');
  }

  Future<List<CreditCard>> fetchCards() async {
    final db = await _dbHelper.database;
    await _ensureCacheScope(db);
    final rows = await db.query(
      'credit_cards',
      where: 'is_deleted = 0',
      orderBy: 'updated_at DESC',
    );
    final localCards = rows.map(_fromDbRow).toList();

    final remoteCollection = _remoteCollection;
    if (remoteCollection != null) {
      final snap = await remoteCollection
          .orderBy('createdAt', descending: true)
          .get();
      final remoteCards = snap.docs
          .map((doc) => _decryptCard({...doc.data(), 'id': doc.id}))
          .toList();

      // Cache remote cards locally so offline mode can still show them.
      for (final card in remoteCards) {
        await _upsertLocal(card, db);
      }

      if (remoteCards.isNotEmpty) return remoteCards;
    }

    return localCards;
  }

  Future<void> saveCard(CreditCard card) async {
    final db = await _dbHelper.database;
    await _ensureCacheScope(db);
    await _upsertLocal(card, db);

    final remoteCollection = _remoteCollection;
    if (remoteCollection != null) {
      await remoteCollection.doc(card.id).set(_encryptCard(card));
    }
  }

  Future<void> deleteCard(String id) async {
    final db = await _dbHelper.database;
    await _ensureCacheScope(db);
    await db.update(
      'credit_cards',
      {'is_deleted': 1, 'updated_at': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );

    final remoteCollection = _remoteCollection;
    if (remoteCollection != null) {
      await remoteCollection.doc(id).delete();
    }
  }

  Future<void> _upsertLocal(CreditCard card, Database db) async {
    await db.insert('credit_cards', {
      'id': card.id,
      'card_holder_name': card.holderName,
      'card_number': card.cardNumber,
      'expiry_date': card.expiryDate,
      'cvv': card.cvv,
      'bank_name': card.bankName,
      'card_network': card.cardNetwork,
      'card_type': 'credit',
      'created_at': (card.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      'updated_at': (card.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'billing_day': card.billingDay,
      'grace_days': card.graceDays,
      'usage_limit': card.usageLimit,
      'currency': card.currency,
      'autopay_enabled': card.autopayEnabled ? 1 : 0,
      'reminder_enabled': card.reminderEnabled ? 1 : 0,
      'reminder_offsets': card.reminderOffsets.join(','),
      'is_synced': 1,
      'is_deleted': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _ensureCacheScope(Database db) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedUid = prefs.getString(_cacheUidKey);
    if (cachedUid != uid) {
      await db.delete('credit_cards');
      await prefs.setString(_cacheUidKey, uid);
    }
  }

  CreditCard _fromDbRow(Map<String, Object?> row) {
    final offsetsRaw = row['reminder_offsets'] as String?;
    final offsets = offsetsRaw == null || offsetsRaw.isEmpty
        ? <int>[]
        : offsetsRaw
            .split(',')
            .map((v) => int.tryParse(v) ?? 0)
            .where((v) => v > 0)
            .toList();
    return CreditCard(
      id: row['id'] as String,
      bankName: row['bank_name'] as String,
      cardNetwork: row['card_network'] as String?,
      cardNumber: row['card_number'] as String,
      holderName: row['card_holder_name'] as String,
      expiryDate: row['expiry_date'] as String,
      cvv: (row['cvv'] as String?) ?? '***',
      cardColor: const Color(0xFF334155),
      textColor: Colors.white,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      billingDay: (row['billing_day'] as int?) ?? 1,
      graceDays: (row['grace_days'] as int?) ?? 15,
      usageLimit: (row['usage_limit'] as num?)?.toDouble(),
      currency: (row['currency'] as String?) ?? AppConfig.baseCurrency,
      autopayEnabled: (row['autopay_enabled'] as int?) == 1,
      reminderEnabled: (row['reminder_enabled'] as int?) == 1,
      reminderOffsets: offsets,
    );
  }

  Map<String, dynamic> _encryptCard(CreditCard card) {
    return {
      'id': card.id,
      'bankName': EncryptionService.encryptData(card.bankName),
      'bankIconUrl': card.bankIconUrl,
      'cardNetwork': card.cardNetwork,
      'cardNumber': EncryptionService.encryptData(card.cardNumber),
      'holderName': EncryptionService.encryptData(card.holderName),
      'expiryDate': EncryptionService.encryptData(card.expiryDate),
      'cvv': EncryptionService.encryptData(card.cvv),
      'cardColor': card.cardColor.value,
      'textColor': card.textColor.value,
      'createdAt': (card.createdAt ?? DateTime.now()).millisecondsSinceEpoch,
      'updatedAt': (card.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'billingDay': card.billingDay,
      'graceDays': card.graceDays,
      'usageLimit': card.usageLimit,
      'currency': card.currency,
      'autopayEnabled': card.autopayEnabled,
      'reminderEnabled': card.reminderEnabled,
      'reminderOffsets': card.reminderOffsets,
    };
  }

  CreditCard _decryptCard(Map<String, dynamic> data) {
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    String decrypt(String key, String fallback) {
      final raw = data[key];
      if (raw == null) return fallback;
      try {
        return EncryptionService.decryptData(raw as String);
      } catch (_) {
        return fallback;
      }
    }

    List<int> offsetsFrom(dynamic raw) {
      if (raw is List) {
        return raw
            .map((e) => (e as num?)?.toInt() ?? 0)
            .where((v) => v > 0)
            .toList();
      }
      if (raw is String) {
        return raw
            .split(',')
            .map((e) => int.tryParse(e) ?? 0)
            .where((v) => v > 0)
            .toList();
      }
      return const [];
    }

    return CreditCard(
      id: (data['id'] ?? '').toString(),
      bankName: decrypt('bankName', 'Unknown'),
      bankIconUrl: data['bankIconUrl'] as String?,
      cardNetwork: data['cardNetwork'] as String? ?? data['card_network'] as String?,
      cardNumber: decrypt('cardNumber', '**** **** **** 0000'),
      holderName: decrypt('holderName', ''),
      expiryDate: decrypt('expiryDate', ''),
      cvv: decrypt('cvv', '***'),
      cardColor: Color((data['cardColor'] ?? 0xFF334155) as int),
      textColor: Color((data['textColor'] ?? 0xFFFFFFFF) as int),
      createdAt: toDate(data['createdAt']),
      updatedAt: toDate(data['updatedAt']),
      billingDay: (data['billingDay'] ?? data['billing_day'] ?? 1) as int,
      graceDays: (data['graceDays'] ?? data['grace_days'] ?? 15) as int,
      usageLimit: (data['usageLimit'] as num?)?.toDouble(),
      currency: (data['currency'] ?? data['cardCurrency'] ?? AppConfig.baseCurrency).toString(),
      autopayEnabled:
          (data['autopayEnabled'] ?? data['autopay_enabled'] ?? false) as bool,
      reminderEnabled: (data['reminderEnabled'] ??
              data['reminder_enabled'] ??
              false) as bool,
      reminderOffsets: offsetsFrom(
        data['reminderOffsets'] ?? data['reminder_offsets'],
      ),
    );
  }
}
