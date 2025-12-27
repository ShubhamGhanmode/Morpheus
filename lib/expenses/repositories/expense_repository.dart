import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
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

  Future<void> updateExpense(Expense expense) async {
    final uid = _uid;
    if (uid == null) return;
    await _expensesRef(uid).doc(expense.id).update(expense.toJson());
  }

  Future<void> deleteExpense(String expenseId) async {
    final uid = _uid;
    if (uid == null) return;
    await _expensesRef(uid).doc(expenseId).delete();
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
