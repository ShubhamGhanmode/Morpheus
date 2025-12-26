import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/services/forex_service.dart';

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
    } catch (_) {
      // fall back to previous values below
    }

    final amountEur = expense.currency == AppConfig.baseCurrency
        ? expense.amount
        : rateToEur != null
            ? expense.amount * rateToEur
            : expense.amount;

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
      amountEur: amountEur,
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
