import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/services/expense_service.dart';
import 'package:morpheus/services/forex_service.dart';

part 'expense_event.dart';
part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  ExpenseBloc(
    this._repository, {
    ForexService? forexService,
    ExpenseService? service,
    String baseCurrency = AppConfig.baseCurrency,
  })  : _forex = forexService ?? ForexService(),
        _service =
            service ??
            ExpenseService(repository: _repository, forexService: forexService),
        super(ExpenseState.initial(baseCurrency: baseCurrency)) {
    on<LoadExpenses>(_onLoadExpenses);
    on<AddExpense>(_onAddExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
    on<SaveBudget>(_onSaveBudget);
    on<AddPlannedExpense>(_onAddPlannedExpense);
    on<ChangeMonth>(_onChangeMonth);
    on<SetBaseCurrency>(_onSetBaseCurrency);
  }

  final ExpenseRepository _repository;
  final ForexService _forex;
  final ExpenseService _service;

  Future<void> _onLoadExpenses(
    LoadExpenses event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final expenses = await _repository.fetchExpenses();
      final budgets = await _repository.fetchBudgets();
      final nextState = _recompute(expenses, budgets, state.focusMonth);
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onAddExpense(
    AddExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final prepared = await _service.addExpense(
        event.expense,
        budgets: state.budgets,
        baseCurrency: state.baseCurrency,
      );
      final updatedExpenses = [prepared, ...state.expenses];
      final nextState = _recompute(
        updatedExpenses,
        state.budgets,
        state.focusMonth,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onUpdateExpense(
    UpdateExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final prepared = await _service.updateExpense(
        event.expense,
        budgets: state.budgets,
        baseCurrency: state.baseCurrency,
      );
      final updated = state.expenses
          .map((e) => e.id == prepared.id ? prepared : e)
          .toList();
      final nextState = _recompute(updated, state.budgets, state.focusMonth);
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onDeleteExpense(
    DeleteExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteExpense(event.expenseId);
      final updated = state.expenses
          .where((e) => e.id != event.expenseId)
          .toList();
      emit(_recompute(updated, state.budgets, state.focusMonth));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onSaveBudget(
    SaveBudget event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveBudget(event.budget);
      final updatedBudgets = [
        event.budget,
        ...state.budgets.where((b) => b.id != event.budget.id),
      ];
      final nextState = _recompute(
        state.expenses,
        updatedBudgets,
        state.focusMonth,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onAddPlannedExpense(
    AddPlannedExpense event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addPlannedExpense(event.budgetId, event.expense);
      final updatedBudgets = state.budgets.map((b) {
        if (b.id == event.budgetId) {
          final planned = [...b.plannedExpenses, event.expense];
          return b.copyWith(plannedExpenses: planned);
        }
        return b;
      }).toList();
      emit(_recompute(state.expenses, updatedBudgets, state.focusMonth));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<ExpenseState> emit,
  ) async {
    final nextState = _recompute(state.expenses, state.budgets, event.month);
    emit(nextState);
    await _refreshRates(nextState, emit);
  }

  Future<void> _onSetBaseCurrency(
    SetBaseCurrency event,
    Emitter<ExpenseState> emit,
  ) async {
    final nextState = _recompute(
      state.expenses,
      state.budgets,
      state.focusMonth,
      baseCurrency: event.currency,
    );
    emit(nextState.copyWith(baseCurrency: event.currency));
    await _refreshRates(nextState, emit);
  }

  ExpenseState _recompute(
    List<Expense> expenses,
    List<Budget> budgets,
    DateTime focusMonth, {
    String? baseCurrency,
  }) {
    final monthStart = DateTime(focusMonth.year, focusMonth.month, 1);
    final monthEnd = DateTime(
      focusMonth.year,
      focusMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );

    final activeBudget = _budgetForMonth(budgets, focusMonth);
    final resolvedBase = baseCurrency ?? state.baseCurrency;
    final displayCurrency = activeBudget?.currency ?? resolvedBase;
    final budgetToEur = activeBudget?.currency == AppConfig.baseCurrency
        ? 1.0
        : state.budgetToEur;

    final spendOnly = expenses
        .where((e) => e.transactionType != 'transfer')
        .toList();
    final monthly = spendOnly
        .where((e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd))
        .toList();
    final monthTotal = monthly.fold<double>(
      0,
      (sum, e) =>
          sum + _amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final monthTotalEur = monthly.fold<double>(
      0,
      (sum, e) =>
          sum +
          (e.amountEur ??
              (e.currency == AppConfig.baseCurrency ? e.amount : e.amount)),
    );

    final annualExpenses = spendOnly
        .where((e) => e.date.year == focusMonth.year)
        .toList();
    final annualTotal = annualExpenses.fold<double>(
      0,
      (sum, e) =>
          sum + _amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final annualTotalEur = annualExpenses.fold<double>(
      0,
      (sum, e) =>
          sum +
          (e.amountEur ??
              (e.currency == AppConfig.baseCurrency ? e.amount : e.amount)),
    );

    final Map<String, double> categoryTotals = {};
    for (final e in monthly) {
      final amount = _amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + amount;
    }

    final reservedPlanned = activeBudget?.reservedAmount ?? 0.0;
    final usableBudget = activeBudget != null
        ? (activeBudget.amount - reservedPlanned - monthTotal)
        : 0.0;

    return state.copyWith(
      loading: false,
      error: null,
      expenses: expenses,
      budgets: budgets,
      activeBudget: activeBudget,
      focusMonth: focusMonth,
      monthlyTotal: monthTotal,
      monthlyTotalEur: monthTotalEur,
      annualTotal: annualTotal,
      annualTotalEur: annualTotalEur,
      categoryTotals: categoryTotals,
      reservedPlanned: reservedPlanned,
      usableBudget: usableBudget,
      baseCurrency: resolvedBase,
      displayCurrency: displayCurrency,
    );
  }

  Budget? _budgetForMonth(List<Budget> budgets, DateTime month) {
    for (final b in budgets) {
      if (b.coversMonth(month)) return b;
    }
    return budgets.isNotEmpty ? budgets.first : null;
  }

  double _amountInDisplayCurrency(
    Expense expense,
    String displayCurrency,
    double? budgetToEur,
  ) {
    final converted = expense.amountForCurrency(displayCurrency);
    if (displayCurrency == expense.currency) return converted;

    if (displayCurrency == AppConfig.baseCurrency && expense.amountEur != null) {
      return expense.amountEur!;
    }

    if (converted != expense.amount) return converted;

    if (displayCurrency == expense.budgetCurrency &&
        expense.amountInBudgetCurrency != null) {
      return expense.amountInBudgetCurrency!;
    }

    if (budgetToEur != null &&
        budgetToEur > 0 &&
        expense.amountEur != null &&
        displayCurrency != AppConfig.baseCurrency) {
      return expense.amountEur! / budgetToEur;
    }

    return converted;
  }

  Future<void> _refreshRates(
    ExpenseState baseState,
    Emitter<ExpenseState> emit,
  ) async {
    double? eurToInr = baseState.eurToInr;
    double? budgetToEur = baseState.budgetToEur;

    if (AppConfig.enableSecondaryCurrency) {
      try {
        eurToInr = await _forex.latestRate(
          base: AppConfig.baseCurrency,
          symbol: AppConfig.secondaryCurrency,
        );
      } catch (_) {
        // ignore, keep previous value
      }
    } else {
      eurToInr = null;
    }

    final activeBudget = baseState.activeBudget;
    if (activeBudget != null &&
        activeBudget.currency != AppConfig.baseCurrency) {
      try {
        budgetToEur = await _forex.latestRate(
          base: activeBudget.currency,
          symbol: AppConfig.baseCurrency,
        );
      } catch (_) {
        // ignore
      }
    } else {
      budgetToEur = 1.0;
    }

    emit(baseState.copyWith(eurToInr: eurToInr, budgetToEur: budgetToEur));
  }
}
