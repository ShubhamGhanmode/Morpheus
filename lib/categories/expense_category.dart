import 'package:freezed_annotation/freezed_annotation.dart';

part 'expense_category.freezed.dart';
part 'expense_category.g.dart';

@freezed
abstract class ExpenseCategory with _$ExpenseCategory {
  const ExpenseCategory._();

  factory ExpenseCategory({
    required String id,
    required String name,
    @Default('') String emoji,
  }) = _ExpenseCategory;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) =>
      _$ExpenseCategoryFromJson(json);

  String get label => emoji.isNotEmpty ? '$emoji $name' : name;
}
