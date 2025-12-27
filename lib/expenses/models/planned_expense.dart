import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'planned_expense.freezed.dart';
part 'planned_expense.g.dart';

@freezed
abstract class PlannedExpense with _$PlannedExpense {
  const PlannedExpense._();

  factory PlannedExpense({
    required String id,
    required String title,
    required double amount,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime dueDate,
    String? category,
  }) = _PlannedExpense;

  factory PlannedExpense.create({
    String? id,
    required String title,
    required double amount,
    required DateTime dueDate,
    String? category,
  }) {
    return PlannedExpense(
      id: id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      dueDate: dueDate,
      category: category,
    );
  }

  factory PlannedExpense.fromJson(Map<String, dynamic> json) =>
      _$PlannedExpenseFromJson(json);
}
