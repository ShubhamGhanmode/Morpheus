import 'package:equatable/equatable.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:uuid/uuid.dart';

class Budget extends Equatable {
  Budget({
    String? id,
    required this.amount,
    required this.startDate,
    required this.endDate,
    this.currency = AppConfig.baseCurrency,
    List<PlannedExpense>? plannedExpenses,
  }) : id = id ?? const Uuid().v4(),
       plannedExpenses = plannedExpenses ?? const [];

  final String id;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final List<PlannedExpense> plannedExpenses;

  double get reservedAmount =>
      plannedExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  bool coversMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    return (startDate.isBefore(monthEnd) ||
            startDate.isAtSameMomentAs(monthEnd)) &&
        (endDate.isAfter(monthStart) || endDate.isAtSameMomentAs(monthStart));
  }

  Budget copyWith({
    String? id,
    double? amount,
    DateTime? startDate,
    DateTime? endDate,
    String? currency,
    List<PlannedExpense>? plannedExpenses,
  }) {
    return Budget(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currency: currency ?? this.currency,
      plannedExpenses: plannedExpenses ?? this.plannedExpenses,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'startDate': startDate.millisecondsSinceEpoch,
    'endDate': endDate.millisecondsSinceEpoch,
    'plannedExpenses': plannedExpenses.map((e) => e.toMap()).toList(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) {
    final planned = (map['plannedExpenses'] as List?) ?? [];
    return Budget(
      id: (map['id'] ?? '').toString(),
      amount: (map['amount'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? AppConfig.baseCurrency,
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate'] as int),
      endDate: DateTime.fromMillisecondsSinceEpoch(map['endDate'] as int),
      plannedExpenses: planned
          .map(
            (e) => PlannedExpense.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    amount,
    currency,
    startDate,
    endDate,
    plannedExpenses,
  ];
}
