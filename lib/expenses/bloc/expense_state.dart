part of 'expense_bloc.dart';

class ExpenseState extends Equatable {
  final bool loading;
  final String? error;
  final List<Expense> expenses;
  final List<Budget> budgets;
  final Budget? activeBudget;
  final DateTime focusMonth;
  final double monthlyTotal;
  final double monthlyTotalEur;
  final double annualTotal;
  final double annualTotalEur;
  final Map<String, double> categoryTotals;
  final double reservedPlanned;
  final double usableBudget;
  final String baseCurrency;
  final String displayCurrency;
  final double? eurToInr;
  final double? budgetToEur;

  const ExpenseState({
    required this.loading,
    required this.error,
    required this.expenses,
    required this.budgets,
    required this.activeBudget,
    required this.focusMonth,
    required this.monthlyTotal,
    required this.monthlyTotalEur,
    required this.annualTotal,
    required this.annualTotalEur,
    required this.categoryTotals,
    required this.reservedPlanned,
    required this.usableBudget,
    required this.baseCurrency,
    required this.displayCurrency,
    required this.eurToInr,
    required this.budgetToEur,
  });

  factory ExpenseState.initial({String baseCurrency = AppConfig.baseCurrency}) {
    final now = DateTime.now();
    return ExpenseState(
      loading: false,
      error: null,
      expenses: const [],
      budgets: const [],
      activeBudget: null,
      focusMonth: DateTime(now.year, now.month, 1),
      monthlyTotal: 0,
      monthlyTotalEur: 0,
      annualTotal: 0,
      annualTotalEur: 0,
      categoryTotals: const {},
      reservedPlanned: 0,
      usableBudget: 0,
      baseCurrency: baseCurrency,
      displayCurrency: baseCurrency,
      eurToInr: null,
      budgetToEur: null,
    );
  }

  ExpenseState copyWith({
    bool? loading,
    String? error,
    List<Expense>? expenses,
    List<Budget>? budgets,
    Budget? activeBudget,
    DateTime? focusMonth,
    double? monthlyTotal,
    double? monthlyTotalEur,
    double? annualTotal,
    double? annualTotalEur,
    Map<String, double>? categoryTotals,
    double? reservedPlanned,
    double? usableBudget,
    String? baseCurrency,
    String? displayCurrency,
    double? eurToInr,
    double? budgetToEur,
  }) {
    return ExpenseState(
      loading: loading ?? this.loading,
      error: error,
      expenses: expenses ?? this.expenses,
      budgets: budgets ?? this.budgets,
      activeBudget: activeBudget ?? this.activeBudget,
      focusMonth: focusMonth ?? this.focusMonth,
      monthlyTotal: monthlyTotal ?? this.monthlyTotal,
      monthlyTotalEur: monthlyTotalEur ?? this.monthlyTotalEur,
      annualTotal: annualTotal ?? this.annualTotal,
      annualTotalEur: annualTotalEur ?? this.annualTotalEur,
      categoryTotals: categoryTotals ?? this.categoryTotals,
      reservedPlanned: reservedPlanned ?? this.reservedPlanned,
      usableBudget: usableBudget ?? this.usableBudget,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      displayCurrency: displayCurrency ?? this.displayCurrency,
      eurToInr: eurToInr ?? this.eurToInr,
      budgetToEur: budgetToEur ?? this.budgetToEur,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    error,
    expenses,
    budgets,
    activeBudget,
    focusMonth,
    monthlyTotal,
    monthlyTotalEur,
    annualTotal,
    annualTotalEur,
    categoryTotals,
    reservedPlanned,
    usableBudget,
    baseCurrency,
    displayCurrency,
    eurToInr,
    budgetToEur,
  ];
}
