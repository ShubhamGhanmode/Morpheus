import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/expense_group.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/models/recurring_transaction.dart';
import 'package:morpheus/expenses/models/subscription.dart';

class ExpenseRepository {
  ExpenseRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _expensesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('expenses');

  CollectionReference<Map<String, dynamic>> _budgetsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('budgets');

  CollectionReference<Map<String, dynamic>> _recurringRef(String uid) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('recurring_transactions');

  CollectionReference<Map<String, dynamic>> _subscriptionsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('subscriptions');

  CollectionReference<Map<String, dynamic>> _groupsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('groups');

  Stream<List<ExpenseGroup>> streamGroups() {
    final uid = _uid;
    if (uid == null) return Stream.empty();
    return _groupsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ExpenseGroup.fromJson({'id': doc.id, ...doc.data()}))
              .toList(),
        );
  }

  Future<List<Expense>> fetchExpensesByGroup(String groupId) async {
    final uid = _uid;
    if (uid == null || groupId.trim().isEmpty) return [];
    final snap = await _expensesRef(uid)
        .where('groupId', isEqualTo: groupId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs
        .map((d) => Expense.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> updateGroup(ExpenseGroup group) async {
    final uid = _uid;
    if (uid == null) return;
    final data = group.toJson();
    data.remove('id');
    data.remove('createdAt');
    final trimmedMerchant = group.merchant?.trim();
    data['merchant'] =
        trimmedMerchant == null || trimmedMerchant.isEmpty
            ? null
            : trimmedMerchant;
    final trimmedImageUri = group.receiptImageUri?.trim();
    data['receiptImageUri'] =
        trimmedImageUri == null || trimmedImageUri.isEmpty
            ? null
            : trimmedImageUri;
    await _groupsRef(uid).doc(group.id).update(data);
  }

  Future<void> deleteGroup(
    String groupId, {
    bool deleteExpenses = false,
  }) async {
    final uid = _uid;
    if (uid == null || groupId.trim().isEmpty) return;
    final expensesSnap =
        await _expensesRef(uid).where('groupId', isEqualTo: groupId).get();
    final batch = _firestore.batch();
    for (final doc in expensesSnap.docs) {
      if (deleteExpenses) {
        batch.delete(doc.reference);
      } else {
        batch.update(
          doc.reference,
          {'groupId': FieldValue.delete()},
        );
      }
    }
    batch.delete(_groupsRef(uid).doc(groupId));
    await batch.commit();
  }

  Future<List<Expense>> fetchExpenses() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _expensesRef(
      uid,
    ).orderBy('date', descending: true).get();
    return snap.docs
        .map((d) => Expense.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> addExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    await _expensesRef(uid).doc(expense.id).set(expense.toJson());
  }

  Future<void> addExpenses(List<Expense> expenses) async {
    final uid = _uid;
    if (uid == null || expenses.isEmpty) return;
    final batch = _firestore.batch();
    final ref = _expensesRef(uid);
    for (final expense in expenses) {
      batch.set(ref.doc(expense.id), expense.toJson());
    }
    await batch.commit();
  }

  Future<String?> addExpenseGroup({
    required String name,
    required List<Expense> expenses,
    String? merchant,
    String? receiptImageUri,
    DateTime? receiptDate,
  }) async {
    final uid = _uid;
    if (uid == null || expenses.isEmpty) return null;
    final groupRef = _groupsRef(uid).doc();
    final groupId = groupRef.id;
    final groupedExpenses =
        expenses.map((e) => e.copyWith(groupId: groupId)).toList();
    final expenseIds = groupedExpenses.map((e) => e.id).toList();
    final trimmedMerchant = merchant?.trim();
    final resolvedMerchant =
        trimmedMerchant == null || trimmedMerchant.isEmpty
            ? null
            : trimmedMerchant;
    final trimmedImageUri = receiptImageUri?.trim();
    final resolvedImageUri =
        trimmedImageUri == null || trimmedImageUri.isEmpty
            ? null
            : trimmedImageUri;
    final totalAmount =
        groupedExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final currency = groupedExpenses.first.currency;

    final batch = _firestore.batch();
    final ref = _expensesRef(uid);
    for (final expense in groupedExpenses) {
      batch.set(ref.doc(expense.id), expense.toJson());
    }
    batch.set(
      groupRef,
      {
        'name': name,
        'merchant': resolvedMerchant,
        'expenseIds': expenseIds,
        'receiptImageUri': resolvedImageUri,
        'currency': currency,
        'totalAmount': totalAmount,
        if (receiptDate != null) 'receiptDate': receiptDate,
        'createdAt': FieldValue.serverTimestamp(),
      },
    );
    await batch.commit();
    return groupId;
  }

  Future<void> updateExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    await _expensesRef(uid).doc(expense.id).update(expense.toJson());
  }

  Future<void> deleteExpense(String expenseId) async {
    final uid = _uid;
    if (uid == null) return;
    final expenseRef = _expensesRef(uid).doc(expenseId);
    final snap = await expenseRef.get();
    if (!snap.exists) return;
    final data = snap.data();
    final groupId = data?['groupId'] as String?;
    final batch = _firestore.batch();
    batch.delete(expenseRef);
    if (groupId != null && groupId.trim().isNotEmpty) {
      batch.update(
        _groupsRef(uid).doc(groupId),
        {'expenseIds': FieldValue.arrayRemove([expenseId])},
      );
    }
    await batch.commit();
  }

  Future<List<Budget>> fetchBudgets() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _budgetsRef(
      uid,
    ).orderBy('startDate', descending: true).get();
    return snap.docs
        .map((d) => Budget.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> saveBudget(Budget budget) async {
    final uid = _uid;
    if (uid == null) return;
    await _budgetsRef(uid).doc(budget.id).set(budget.toJson());
  }

  Future<void> addPlannedExpense(
    String budgetId,
    PlannedExpense expense,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    final budgets = _budgetsRef(uid);
    await _firestore.runTransaction((tx) async {
      final docRef = budgets.doc(budgetId);
      final snap = await tx.get(docRef);
      final data = snap.data() ?? {};
      final planned = (data['plannedExpenses'] as List?) ?? [];
      planned.add(expense.toJson());
      tx.set(docRef, {...data, 'plannedExpenses': planned});
    });
  }

  Future<List<RecurringTransaction>> fetchRecurringTransactions() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _recurringRef(uid)
        .orderBy('startDate', descending: true)
        .get();
    return snap.docs
        .map((d) => RecurringTransaction.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> saveRecurringTransaction(
    RecurringTransaction transaction,
  ) async {
    final uid = _uid;
    if (uid == null) return;
    await _recurringRef(uid)
        .doc(transaction.id)
        .set(transaction.toJson());
  }

  Future<void> deleteRecurringTransaction(String transactionId) async {
    final uid = _uid;
    if (uid == null) return;
    await _recurringRef(uid).doc(transactionId).delete();
  }

  Future<List<Subscription>> fetchSubscriptions() async {
    final uid = _uid;
    if (uid == null) return [];
    final snap = await _subscriptionsRef(uid)
        .orderBy('renewalDate', descending: true)
        .get();
    return snap.docs
        .map((d) => Subscription.fromJson({'id': d.id, ...d.data()}))
        .toList();
  }

  Future<void> saveSubscription(Subscription subscription) async {
    final uid = _uid;
    if (uid == null) return;
    await _subscriptionsRef(uid).doc(subscription.id).set(subscription.toJson());
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    final uid = _uid;
    if (uid == null) return;
    await _subscriptionsRef(uid).doc(subscriptionId).delete();
  }
}
