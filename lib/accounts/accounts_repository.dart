import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/services/encryption_service.dart';

class AccountsRepository {
  AccountsRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('accounts');
  }

  Future<List<AccountCredential>> fetchAccounts() async {
    final col = _collection;
    if (col == null) return [];
    final snap = await col.orderBy('lastUpdated', descending: true).get();
    return snap.docs
        .map((d) => AccountCredential.fromJson({'id': d.id, ..._decrypt(d.data())}))
        .toList();
  }

  Future<void> saveAccount(AccountCredential account) async {
    final col = _collection;
    if (col == null) return;
    await col.doc(account.id).set(_encrypt(account));
  }

  Future<void> deleteAccount(String id) async {
    final col = _collection;
    if (col == null) return;
    await col.doc(id).delete();
  }

  Map<String, dynamic> _encrypt(AccountCredential acct) {
    final base = acct.toJson();
    return {
      ...base,
      'bankName': EncryptionService.encryptData(acct.bankName),
      'username': EncryptionService.encryptData(acct.username),
      'password': EncryptionService.encryptData(acct.password),
      'website': acct.website != null
          ? EncryptionService.encryptData(acct.website!)
          : null,
    };
  }

  Map<String, dynamic> _decrypt(Map<String, dynamic> data) {
    String dec(String key, String fallback) {
      final raw = data[key];
      if (raw == null) return fallback;
      try {
        return EncryptionService.decryptData(raw as String);
      } catch (e, stack) {
        unawaited(
          ErrorReporter.recordError(
            e,
            stack,
            reason: 'Account field decrypt failed',
            context: {'field': key},
          ),
        );
        return fallback;
      }
    }

    return {
      ...data,
      'bankName': dec('bankName', 'Bank'),
      'username': dec('username', ''),
      'password': dec('password', ''),
      if (data['website'] != null) 'website': dec('website', ''),
    };
  }
}
