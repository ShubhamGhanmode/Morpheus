import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'budget.freezed.dart';
part 'budget.g.dart';

@freezed
abstract class Budget with _$Budget {
  const Budget._();

  @JsonSerializable(explicitToJson: true)
  factory Budget({
    required String id,
    required double amount,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime startDate,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime endDate,
    @Default(AppConfig.baseCurrency) String currency,
    @Default(<PlannedExpense>[]) List<PlannedExpense> plannedExpenses,
  }) = _Budget;

  factory Budget.create({
    String? id,
    required double amount,
    required DateTime startDate,
    required DateTime endDate,
    String currency = AppConfig.baseCurrency,
    List<PlannedExpense>? plannedExpenses,
  }) {
    return Budget(
      id: id ?? const Uuid().v4(),
      amount: amount,
      startDate: startDate,
      endDate: endDate,
      currency: currency,
      plannedExpenses: plannedExpenses ?? const [],
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) => _$BudgetFromJson(json);

  double get reservedAmount =>
      plannedExpenses.fold<double>(0, (sum, e) => sum + e.amount);

  bool coversMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0);
    return (startDate.isBefore(monthEnd) ||
            startDate.isAtSameMomentAs(monthEnd)) &&
        (endDate.isAfter(monthStart) || endDate.isAtSameMomentAs(monthStart));
  }
}
