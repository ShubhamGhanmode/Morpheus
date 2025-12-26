part of 'expense_bloc.dart';

sealed class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  const LoadExpenses();
}

class AddExpense extends ExpenseEvent {
  const AddExpense(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

class UpdateExpense extends ExpenseEvent {
  const UpdateExpense(this.expense);

  final Expense expense;

  @override
  List<Object?> get props => [expense];
}

class DeleteExpense extends ExpenseEvent {
  const DeleteExpense(this.expenseId);

  final String expenseId;

  @override
  List<Object?> get props => [expenseId];
}

class SaveBudget extends ExpenseEvent {
  const SaveBudget(this.budget);

  final Budget budget;

  @override
  List<Object?> get props => [budget];
}

class AddPlannedExpense extends ExpenseEvent {
  const AddPlannedExpense({required this.budgetId, required this.expense});

  final String budgetId;
  final PlannedExpense expense;

  @override
  List<Object?> get props => [budgetId, expense];
}

class ChangeMonth extends ExpenseEvent {
  const ChangeMonth(this.month);

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

class SetBaseCurrency extends ExpenseEvent {
  const SetBaseCurrency(this.currency);

  final String currency;

  @override
  List<Object?> get props => [currency];
}
