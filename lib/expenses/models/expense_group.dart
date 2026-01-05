import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/models/json_converters.dart';

part 'expense_group.freezed.dart';
part 'expense_group.g.dart';

@freezed
abstract class ExpenseGroup with _$ExpenseGroup {
  const ExpenseGroup._();

  factory ExpenseGroup({
    required String id,
    required String name,
    String? merchant,
    @Default(<String>[]) List<String> expenseIds,
    String? receiptImageUri,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? createdAt,
    String? currency,
    double? totalAmount,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? receiptDate,
  }) = _ExpenseGroup;

  factory ExpenseGroup.fromJson(Map<String, dynamic> json) =>
      _$ExpenseGroupFromJson(json);

  int get itemCount => expenseIds.length;
}
