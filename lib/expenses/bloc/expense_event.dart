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

class AddExpenses extends ExpenseEvent {
  const AddExpenses(this.expenses);

  final List<Expense> expenses;

  @override
  List<Object?> get props => [expenses];
}

class AddGroupedExpenses extends ExpenseEvent {
  const AddGroupedExpenses({
    required this.expenses,
    required this.groupName,
    this.merchant,
    this.receiptImageUri,
    this.receiptDate,
  });

  final List<Expense> expenses;
  final String groupName;
  final String? merchant;
  final String? receiptImageUri;
  final DateTime? receiptDate;

  @override
  List<Object?> get props => [
        expenses,
        groupName,
        merchant,
        receiptImageUri,
        receiptDate,
      ];
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

class SaveRecurringTransaction extends ExpenseEvent {
  const SaveRecurringTransaction(this.transaction);

  final RecurringTransaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class DeleteRecurringTransaction extends ExpenseEvent {
  const DeleteRecurringTransaction(this.transactionId);

  final String transactionId;

  @override
  List<Object?> get props => [transactionId];
}

class RecordRecurringTransaction extends ExpenseEvent {
  const RecordRecurringTransaction(this.transaction);

  final RecurringTransaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class SaveSubscription extends ExpenseEvent {
  const SaveSubscription(this.subscription);

  final Subscription subscription;

  @override
  List<Object?> get props => [subscription];
}

class DeleteSubscription extends ExpenseEvent {
  const DeleteSubscription(this.subscriptionId);

  final String subscriptionId;

  @override
  List<Object?> get props => [subscriptionId];
}
