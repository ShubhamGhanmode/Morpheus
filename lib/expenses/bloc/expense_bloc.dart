import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/models/recurring_transaction.dart';
import 'package:morpheus/expenses/models/spending_anomaly.dart';
import 'package:morpheus/expenses/models/subscription.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/services/expense_service.dart';
import 'package:morpheus/expenses/utils/expense_amounts.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

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
    on<SaveRecurringTransaction>(_onSaveRecurringTransaction);
    on<DeleteRecurringTransaction>(_onDeleteRecurringTransaction);
    on<RecordRecurringTransaction>(_onRecordRecurringTransaction);
    on<SaveSubscription>(_onSaveSubscription);
    on<DeleteSubscription>(_onDeleteSubscription);
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
      final recurring = await _repository.fetchRecurringTransactions();
      final subscriptions = await _repository.fetchSubscriptions();
      final nextState = _recompute(
        expenses,
        budgets,
        state.focusMonth,
        recurringTransactions: recurring,
        subscriptions: subscriptions,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Load expenses failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Load expenses'),
        ),
      );
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
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Add expense failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Add expense'),
        ),
      );
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
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Update expense failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Update expense'),
        ),
      );
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
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Delete expense failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Delete expense'),
        ),
      );
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
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Save budget failed');
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Save budget'),
        ),
      );
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
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Add planned expense failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Add planned expense'),
        ),
      );
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

  Future<void> _onSaveRecurringTransaction(
    SaveRecurringTransaction event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveRecurringTransaction(event.transaction);
      final updated = [
        event.transaction,
        ...state.recurringTransactions.where((t) => t.id != event.transaction.id),
      ];
      emit(
        _recompute(
          state.expenses,
          state.budgets,
          state.focusMonth,
          recurringTransactions: updated,
          subscriptions: state.subscriptions,
        ),
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Save recurring transaction failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Save recurring transaction'),
        ),
      );
    }
  }

  Future<void> _onDeleteRecurringTransaction(
    DeleteRecurringTransaction event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteRecurringTransaction(event.transactionId);
      final updated = state.recurringTransactions
          .where((t) => t.id != event.transactionId)
          .toList();
      emit(
        _recompute(
          state.expenses,
          state.budgets,
          state.focusMonth,
          recurringTransactions: updated,
          subscriptions: state.subscriptions,
        ),
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Delete recurring transaction failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Delete recurring transaction'),
        ),
      );
    }
  }

  Future<void> _onRecordRecurringTransaction(
    RecordRecurringTransaction event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final now = DateTime.now();
      final expense = Expense.create(
        title: event.transaction.title,
        amount: event.transaction.amount,
        currency: event.transaction.currency,
        category: event.transaction.category,
        date: now,
        note: event.transaction.note,
        paymentSourceType: event.transaction.paymentSourceType,
        paymentSourceId: event.transaction.paymentSourceId,
      );
      final prepared = await _service.addExpense(
        expense,
        budgets: state.budgets,
        baseCurrency: state.baseCurrency,
      );
      final updatedExpenses = [prepared, ...state.expenses];
      final updatedTransaction =
          event.transaction.copyWith(lastGenerated: now);
      await _repository.saveRecurringTransaction(updatedTransaction);
      final updatedRecurring = [
        updatedTransaction,
        ...state.recurringTransactions
            .where((t) => t.id != updatedTransaction.id),
      ];
      final nextState = _recompute(
        updatedExpenses,
        state.budgets,
        state.focusMonth,
        recurringTransactions: updatedRecurring,
        subscriptions: state.subscriptions,
      );
      emit(nextState);
      await _refreshRates(nextState, emit);
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Record recurring transaction failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Record recurring transaction'),
        ),
      );
    }
  }

  Future<void> _onSaveSubscription(
    SaveSubscription event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveSubscription(event.subscription);
      final updated = [
        event.subscription,
        ...state.subscriptions.where((s) => s.id != event.subscription.id),
      ];
      emit(
        _recompute(
          state.expenses,
          state.budgets,
          state.focusMonth,
          recurringTransactions: state.recurringTransactions,
          subscriptions: updated,
        ),
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Save subscription failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Save subscription'),
        ),
      );
    }
  }

  Future<void> _onDeleteSubscription(
    DeleteSubscription event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteSubscription(event.subscriptionId);
      final updated = state.subscriptions
          .where((s) => s.id != event.subscriptionId)
          .toList();
      emit(
        _recompute(
          state.expenses,
          state.budgets,
          state.focusMonth,
          recurringTransactions: state.recurringTransactions,
          subscriptions: updated,
        ),
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Delete subscription failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Delete subscription'),
        ),
      );
    }
  }

  ExpenseState _recompute(
    List<Expense> expenses,
    List<Budget> budgets,
    DateTime focusMonth, {
    String? baseCurrency,
    List<RecurringTransaction>? recurringTransactions,
    List<Subscription>? subscriptions,
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
    final recurring = recurringTransactions ?? state.recurringTransactions;
    final subs = subscriptions ?? state.subscriptions;

    final spendOnly = expenses
        .where((e) => e.transactionType != 'transfer')
        .toList();
    final monthly = spendOnly
        .where((e) => !e.date.isBefore(monthStart) && !e.date.isAfter(monthEnd))
        .toList();
    final monthTotal = monthly.fold<double>(
      0,
      (sum, e) =>
          sum + amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final monthTotalEur = monthly.fold<double>(
      0,
      (sum, e) => sum + e.amountForCurrency(AppConfig.baseCurrency),
    );

    final annualExpenses = spendOnly
        .where((e) => e.date.year == focusMonth.year)
        .toList();
    final annualTotal = annualExpenses.fold<double>(
      0,
      (sum, e) =>
          sum + amountInDisplayCurrency(e, displayCurrency, budgetToEur),
    );
    final annualTotalEur = annualExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amountForCurrency(AppConfig.baseCurrency),
    );

    final Map<String, double> categoryTotals = {};
    for (final e in monthly) {
      final amount = amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0) + amount;
    }

    final reservedPlanned = activeBudget?.reservedAmount ?? 0.0;
    final budgetStart = activeBudget != null
        ? DateTime(
            activeBudget.startDate.year,
            activeBudget.startDate.month,
            activeBudget.startDate.day,
          )
        : monthStart;
    final budgetEnd = activeBudget != null
        ? DateTime(
            activeBudget.endDate.year,
            activeBudget.endDate.month,
            activeBudget.endDate.day,
            23,
            59,
            59,
            999,
          )
        : monthEnd;
    final budgetSpend = activeBudget == null
        ? monthTotal
        : spendOnly
            .where(
              (e) =>
                  !e.date.isBefore(budgetStart) &&
                  !e.date.isAfter(budgetEnd),
            )
            .fold<double>(
              0,
              (sum, e) =>
                  sum +
                  amountInDisplayCurrency(
                    e,
                    displayCurrency,
                    budgetToEur,
                  ),
            );
    final usableBudget = activeBudget != null
        ? (activeBudget.amount - reservedPlanned - budgetSpend)
        : 0.0;

    final forecast = _forecastSpend(
      expenses: spendOnly,
      focusMonth: focusMonth,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
      budget: activeBudget,
    );

    final anomalies = _detectAnomalies(
      expenses: spendOnly,
      focusMonth: focusMonth,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
    );

    return state.copyWith(
      loading: false,
      error: null,
      expenses: expenses,
      budgets: budgets,
      recurringTransactions: recurring,
      subscriptions: subs,
      activeBudget: activeBudget,
      focusMonth: focusMonth,
      monthlyTotal: monthTotal,
      monthlyTotalEur: monthTotalEur,
      annualTotal: annualTotal,
      annualTotalEur: annualTotalEur,
      categoryTotals: categoryTotals,
      reservedPlanned: reservedPlanned,
      usableBudget: usableBudget,
      forecastTotal: forecast.total,
      forecastDaily: forecast.daily,
      forecastOverBudget: forecast.overBudget,
      anomalies: anomalies,
      baseCurrency: resolvedBase,
      displayCurrency: displayCurrency,
    );
  }

  Budget? _budgetForMonth(List<Budget> budgets, DateTime month) {
    for (final b in budgets) {
      if (b.coversMonth(month)) return b;
    }
    return null;
  }

  _Forecast _forecastSpend({
    required List<Expense> expenses,
    required DateTime focusMonth,
    required String displayCurrency,
    required double? budgetToEur,
    required Budget? budget,
  }) {
    final now = DateTime.now();
    if (now.year != focusMonth.year || now.month != focusMonth.month) {
      return const _Forecast.empty();
    }

    final periodStart = budget?.startDate ??
        DateTime(focusMonth.year, focusMonth.month, 1);
    final periodEnd = budget?.endDate ??
        DateTime(focusMonth.year, focusMonth.month + 1, 0, 23, 59, 59, 999);

    final start = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final end = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
      23,
      59,
      59,
      999,
    );
    final clampedNow = now.isBefore(start)
        ? start
        : now.isAfter(end)
        ? end
        : now;

    final totalDays = end.difference(start).inDays + 1;
    final elapsedDays = clampedNow.difference(start).inDays + 1;
    if (totalDays <= 0 || elapsedDays <= 0) {
      return const _Forecast.empty();
    }

    final spentToDate = expenses
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(clampedNow))
        .fold<double>(
          0,
          (sum, e) =>
              sum + amountInDisplayCurrency(e, displayCurrency, budgetToEur),
        );

    final daily = spentToDate / elapsedDays;
    final total = daily * totalDays;
    final overBudget =
        budget != null ? total - budget.amount : null;

    return _Forecast(total: total, daily: daily, overBudget: overBudget);
  }

  List<SpendingAnomaly> _detectAnomalies({
    required List<Expense> expenses,
    required DateTime focusMonth,
    required String displayCurrency,
    required double? budgetToEur,
  }) {
    final currentStart = DateTime(focusMonth.year, focusMonth.month, 1);
    final currentEnd = DateTime(
      focusMonth.year,
      focusMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
    final current = expenses
        .where((e) => !e.date.isBefore(currentStart) && !e.date.isAfter(currentEnd))
        .toList();

    final previousMonths = List.generate(
      3,
      (i) => DateTime(focusMonth.year, focusMonth.month - (i + 1), 1),
    );
    final baselineStart = DateTime(
      previousMonths.last.year,
      previousMonths.last.month,
      1,
    );

    final baseline = expenses
        .where((e) => !e.date.isBefore(baselineStart) && e.date.isBefore(currentStart))
        .toList();

    final currentByCategory = _sumByKey(
      current,
      displayCurrency,
      budgetToEur,
      (e) => e.category,
    );
    final currentByMerchant = _sumByKey(
      current,
      displayCurrency,
      budgetToEur,
      _merchantKey,
    );
    final baselineByCategory = _sumByKey(
      baseline,
      displayCurrency,
      budgetToEur,
      (e) => e.category,
    );
    final baselineByMerchant = _sumByKey(
      baseline,
      displayCurrency,
      budgetToEur,
      _merchantKey,
    );
    final baselineMonthsByCategory = _monthKeysByKey(
      baseline,
      (e) => e.category,
    );
    final baselineMonthsByMerchant = _monthKeysByKey(
      baseline,
      _merchantKey,
    );

    final anomalies = <SpendingAnomaly>[];

    for (final entry in currentByCategory.entries) {
      final months = baselineMonthsByCategory[entry.key];
      if (months == null || months.isEmpty) continue;
      final avg = (baselineByCategory[entry.key] ?? 0) / months.length;
      if (_isAnomalous(entry.value, avg)) {
        anomalies.add(
          SpendingAnomaly(
            type: AnomalyType.category,
            label: entry.key,
            currentAmount: entry.value,
            averageAmount: avg,
          ),
        );
      }
    }

    for (final entry in currentByMerchant.entries) {
      final months = baselineMonthsByMerchant[entry.key];
      if (months == null || months.isEmpty) continue;
      final avg = (baselineByMerchant[entry.key] ?? 0) / months.length;
      if (_isAnomalous(entry.value, avg)) {
        anomalies.add(
          SpendingAnomaly(
            type: AnomalyType.merchant,
            label: entry.key,
            currentAmount: entry.value,
            averageAmount: avg,
          ),
        );
      }
    }

    anomalies.sort((a, b) => b.delta.compareTo(a.delta));
    return anomalies.take(6).toList();
  }

  Map<String, double> _sumByKey(
    List<Expense> expenses,
    String displayCurrency,
    double? budgetToEur,
    String Function(Expense) keySelector,
  ) {
    final totals = <String, double>{};
    for (final e in expenses) {
      final key = keySelector(e).trim();
      if (key.isEmpty) continue;
      final amount = amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      totals[key] = (totals[key] ?? 0) + amount;
    }
    return totals;
  }

  Map<String, Set<String>> _monthKeysByKey(
    List<Expense> expenses,
    String Function(Expense) keySelector,
  ) {
    final monthsByKey = <String, Set<String>>{};
    for (final e in expenses) {
      final key = keySelector(e).trim();
      if (key.isEmpty) continue;
      final monthKey = '${e.date.year}-${e.date.month}';
      monthsByKey.putIfAbsent(key, () => <String>{}).add(monthKey);
    }
    return monthsByKey;
  }

  String _merchantKey(Expense expense) {
    return expense.title.trim().toLowerCase();
  }

  bool _isAnomalous(double current, double average) {
    const minAbsolute = 50.0;
    if (current < minAbsolute) return false;
    if (average <= 0) return current >= minAbsolute * 2;
    return current >= average * 1.6 && (current - average) >= 25;
  }

  Future<void> _refreshRates(
    ExpenseState baseState,
    Emitter<ExpenseState> emit,
  ) async {
    double? eurToInr = baseState.eurToInr;
    double? budgetToEur = baseState.budgetToEur;
    String? rateError;

    if (AppConfig.enableSecondaryCurrency) {
      try {
        eurToInr = await _forex.latestRate(
          base: AppConfig.baseCurrency,
          symbol: AppConfig.secondaryCurrency,
        );
      } catch (e, stack) {
        await ErrorReporter.recordError(
          e,
          stack,
          reason: 'Refresh secondary FX rate failed',
        );
        rateError = 'Unable to refresh FX rates.';
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
      } catch (e, stack) {
        await ErrorReporter.recordError(
          e,
          stack,
          reason: 'Refresh budget FX rate failed',
        );
        rateError ??= 'Unable to refresh FX rates.';
      }
    } else {
      budgetToEur = 1.0;
    }

    emit(
      baseState.copyWith(
        eurToInr: eurToInr,
        budgetToEur: budgetToEur,
        error: rateError ?? baseState.error,
      ),
    );
  }
}

class _Forecast {
  const _Forecast({required this.total, required this.daily, this.overBudget});

  final double? total;
  final double? daily;
  final double? overBudget;

  const _Forecast.empty()
      : total = null,
        daily = null,
        overBudget = null;
}
