import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/expense_group.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/services/error_reporter.dart';

class ExpenseService {
  ExpenseService({ExpenseRepository? repository, ForexService? forexService})
      : _repository = repository ?? ExpenseRepository(),
        _forex = forexService ?? ForexService();

  final ExpenseRepository _repository;
  final ForexService _forex;

  Future<Expense> addExpense(
    Expense expense, {
    List<Budget>? budgets,
    String? baseCurrency,
  }) async {
    final prepared = await prepareExpense(
      expense,
      budgets: budgets,
      baseCurrency: baseCurrency,
    );
    await _repository.addExpense(prepared);
    return prepared;
  }

  Future<Expense> updateExpense(
    Expense expense, {
    List<Budget>? budgets,
    String? baseCurrency,
  }) async {
    final prepared = await prepareExpense(
      expense,
      budgets: budgets,
      baseCurrency: baseCurrency,
    );
    await _repository.updateExpense(prepared);
    return prepared;
  }

  Future<List<Expense>> addExpenses(
    List<Expense> expenses, {
    List<Budget>? budgets,
    String? baseCurrency,
  }) async {
    if (expenses.isEmpty) return [];
    final prepared = <Expense>[];
    for (final expense in expenses) {
      prepared.add(
        await prepareExpense(
          expense,
          budgets: budgets,
          baseCurrency: baseCurrency,
        ),
      );
    }
    await _repository.addExpenses(prepared);
    return prepared;
  }

  Future<List<Expense>> addGroupedExpenses(
    List<Expense> expenses, {
    required String groupName,
    String? merchant,
    String? receiptImageUri,
    DateTime? receiptDate,
    List<Budget>? budgets,
    String? baseCurrency,
  }) async {
    if (expenses.isEmpty) return [];
    final prepared = <Expense>[];
    for (final expense in expenses) {
      prepared.add(
        await prepareExpense(
          expense,
          budgets: budgets,
          baseCurrency: baseCurrency,
        ),
      );
    }
    final groupId = await _repository.addExpenseGroup(
      name: groupName,
      expenses: prepared,
      merchant: merchant,
      receiptImageUri: receiptImageUri,
      receiptDate: receiptDate,
    );
    if (groupId == null) {
      await _repository.addExpenses(prepared);
      return prepared;
    }
    return prepared.map((expense) => expense.copyWith(groupId: groupId)).toList();
  }

  Stream<List<ExpenseGroup>> streamGroups() {
    return _repository.streamGroups();
  }

  Future<List<Expense>> fetchExpensesByGroup(String groupId) {
    return _repository.fetchExpensesByGroup(groupId);
  }

  Future<void> updateGroup(ExpenseGroup group) {
    return _repository.updateGroup(group);
  }

  Future<void> deleteGroup(
    String groupId, {
    bool deleteExpenses = false,
  }) {
    return _repository.deleteGroup(
      groupId,
      deleteExpenses: deleteExpenses,
    );
  }

  Future<Expense> prepareExpense(
    Expense expense, {
    List<Budget>? budgets,
    String? baseCurrency,
  }) async {
    final allBudgets = budgets ?? await _repository.fetchBudgets();
    final budget = _budgetForDate(allBudgets, expense.date);
    final budgetCurrency = budget?.currency;
    final resolvedBase = baseCurrency ??
        expense.baseCurrency ??
        budgetCurrency ??
        AppConfig.baseCurrency;

    double? rateToBudget;
    double? rateToEur;
    double? rateToBase;

    final symbols = <String>{AppConfig.baseCurrency, resolvedBase};
    if (budgetCurrency != null) {
      symbols.add(budgetCurrency);
    }
    symbols.remove(expense.currency);

    try {
      if (symbols.isNotEmpty) {
        final rates = await _forex.fetchRates(
          date: expense.date,
          base: expense.currency,
          symbols: symbols.toList(),
        );
        rateToEur = rates[AppConfig.baseCurrency];
        rateToBase = rates[resolvedBase];
        if (budgetCurrency != null) {
          rateToBudget = rates[budgetCurrency];
        }
      }
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Fetch FX rates failed',
      );
    }

    final amountEur = expense.currency == AppConfig.baseCurrency
        ? expense.amount
        : rateToEur != null
            ? expense.amount * rateToEur
            : null;
    final existingAmountEur = expense.amountEur;
    final resolvedAmountEur = amountEur ??
        ((existingAmountEur != null &&
                (expense.currency == AppConfig.baseCurrency ||
                    existingAmountEur != expense.amount))
            ? existingAmountEur
            : null);

    double? amountInBudgetCurrency;
    if (budgetCurrency != null) {
      if (budgetCurrency == expense.currency) {
        rateToBudget = 1;
        amountInBudgetCurrency = expense.amount;
      } else if (rateToBudget != null) {
        amountInBudgetCurrency = expense.amount * rateToBudget;
      } else if (budgetCurrency == AppConfig.baseCurrency && amountEur != null) {
        amountInBudgetCurrency = amountEur;
      }
    }

    double? amountInBaseCurrency;
    if (resolvedBase == expense.currency) {
      rateToBase = 1;
      amountInBaseCurrency = expense.amount;
    } else if (rateToBase != null) {
      amountInBaseCurrency = expense.amount * rateToBase;
    } else if (resolvedBase == AppConfig.baseCurrency && amountEur != null) {
      amountInBaseCurrency = amountEur;
    } else if (resolvedBase == budgetCurrency &&
        amountInBudgetCurrency != null) {
      amountInBaseCurrency = amountInBudgetCurrency;
    }

    return expense.copyWith(
      baseCurrency: resolvedBase,
      baseRate: rateToBase ?? expense.baseRate,
      amountInBaseCurrency:
          amountInBaseCurrency ?? expense.amountInBaseCurrency,
      budgetCurrency: budgetCurrency ?? expense.budgetCurrency,
      budgetRate: rateToBudget ?? expense.budgetRate,
      amountInBudgetCurrency:
          amountInBudgetCurrency ?? expense.amountInBudgetCurrency,
      amountEur: resolvedAmountEur,
    );
  }

  Budget? _budgetForDate(List<Budget> budgets, DateTime date) {
    for (final b in budgets) {
      final starts = !date.isBefore(
        DateTime(b.startDate.year, b.startDate.month, b.startDate.day),
      );
      final ends = !date.isAfter(
        DateTime(b.endDate.year, b.endDate.month, b.endDate.day, 23, 59, 59),
      );
      if (starts && ends) return b;
    }
    return null;
  }
}
