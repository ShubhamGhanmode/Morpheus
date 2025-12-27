import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/database/database_helper.dart' show DatabaseHelper;
import 'package:morpheus/services/error_reporter.dart';
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
    return CreditCard.fromJson(row.cast<String, dynamic>());
  }

  Map<String, dynamic> _encryptCard(CreditCard card) {
    final base = card.toJson();
    return {
      ...base,
      'bankName': EncryptionService.encryptData(card.bankName),
      'cardNumber': EncryptionService.encryptData(card.cardNumber),
      'holderName': EncryptionService.encryptData(card.holderName),
      'expiryDate': EncryptionService.encryptData(card.expiryDate),
      'cvv': EncryptionService.encryptData(card.cvv),
    };
  }

  CreditCard _decryptCard(Map<String, dynamic> data) {
    String decrypt(String key, String fallback) {
      final raw = data[key];
      if (raw == null) return fallback;
      try {
        return EncryptionService.decryptData(raw as String);
      } catch (e, stack) {
        unawaited(
          ErrorReporter.recordError(
            e,
            stack,
            reason: 'Card field decrypt failed',
            context: {'field': key},
          ),
        );
        return fallback;
      }
    }

    final decrypted = {
      ...data,
      'bankName': decrypt('bankName', 'Unknown'),
      'cardNumber': decrypt('cardNumber', '**** **** **** 0000'),
      'holderName': decrypt('holderName', ''),
      'expiryDate': decrypt('expiryDate', ''),
      'cvv': decrypt('cvv', '***'),
    };
    return CreditCard.fromJson(decrypted);
  }
}
