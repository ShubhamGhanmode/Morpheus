import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';

class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _categoriesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('expense_categories');

  Future<List<ExpenseCategory>> fetchCategories() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _categoriesRef(uid).orderBy('name').get();
    return snap.docs
        .map((d) => ExpenseCategory.fromMap(d.id, d.data()))
        .where((c) => c.name.isNotEmpty)
        .toList();
  }

  Future<bool> hasCategories() async {
    final uid = _uid;
    if (uid == null) return false;
    final snap = await _categoriesRef(uid).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Future<void> addDefaultCategories() async {
    final uid = _uid;
    if (uid == null) return;
    final batch = _firestore.batch();
    final ref = _categoriesRef(uid);
    for (final seed in AppConfig.defaultExpenseCategories) {
      final docId = _slug(seed.name);
      batch.set(
        ref.doc(docId),
        {
          'name': seed.name,
          'emoji': seed.emoji,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<void> addCategory({required String name, required String emoji}) async {
    final uid = _uid;
    if (uid == null) return;
    await _categoriesRef(uid).add({
      'name': name,
      'emoji': emoji,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  String _slug(String name) {
    final sanitized =
        name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return sanitized.isEmpty ? DateTime.now().millisecondsSinceEpoch.toString() : sanitized;
  }
}
