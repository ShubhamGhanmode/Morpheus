import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
abstract class Expense with _$Expense {
  const Expense._();

  factory Expense({
    required String id,
    required String title,
    required double amount,
    required String currency,
    required String category,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime date,
    String? groupId,
    String? note,
    double? amountEur,
    String? baseCurrency,
    double? baseRate,
    double? amountInBaseCurrency,
    String? budgetCurrency,
    double? budgetRate,
    double? amountInBudgetCurrency,
    @JsonKey(fromJson: _paymentSourceFromJson)
    @Default('cash')
    String paymentSourceType,
    String? paymentSourceId,
    @Default('spend') String transactionType,
  }) = _Expense;

  factory Expense.create({
    String? id,
    required String title,
    required double amount,
    required String currency,
    required String category,
    required DateTime date,
    String? groupId,
    String? note,
    double? amountEur,
    String? baseCurrency,
    double? baseRate,
    double? amountInBaseCurrency,
    String? budgetCurrency,
    double? budgetRate,
    double? amountInBudgetCurrency,
    String paymentSourceType = 'cash',
    String? paymentSourceId,
    String transactionType = 'spend',
  }) {
    return Expense(
      id: id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      currency: currency,
      category: category,
      date: date,
      groupId: groupId,
      note: note,
      amountEur: amountEur,
      baseCurrency: baseCurrency,
      baseRate: baseRate,
      amountInBaseCurrency: amountInBaseCurrency,
      budgetCurrency: budgetCurrency,
      budgetRate: budgetRate,
      amountInBudgetCurrency: amountInBudgetCurrency,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
      transactionType: transactionType,
    );
  }

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  double amountForCurrency(String targetCurrency) {
    if (targetCurrency == currency) return amount;
    if (baseCurrency != null &&
        targetCurrency == baseCurrency &&
        amountInBaseCurrency != null) {
      return amountInBaseCurrency!;
    }
    if (targetCurrency == AppConfig.baseCurrency && amountEur != null) {
      return amountEur!;
    }
    if (budgetCurrency != null && budgetCurrency == targetCurrency) {
      if (amountInBudgetCurrency != null) return amountInBudgetCurrency!;
      if (budgetRate != null) return amount * budgetRate!;
    }
    if (baseCurrency != null &&
        targetCurrency == baseCurrency &&
        baseRate != null) {
      return amount * baseRate!;
    }
    return amount;
  }

}

String _paymentSourceFromJson(Object? value) {
  return (value as String? ?? 'cash').toLowerCase();
}
