// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Budget _$BudgetFromJson(Map<String, dynamic> json) => _Budget(
  id: json['id'] as String,
  amount: (json['amount'] as num).toDouble(),
  startDate: dateTimeFromJson(json['startDate']),
  endDate: dateTimeFromJson(json['endDate']),
  currency: json['currency'] as String? ?? AppConfig.baseCurrency,
  plannedExpenses:
      (json['plannedExpenses'] as List<dynamic>?)
          ?.map((e) => PlannedExpense.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PlannedExpense>[],
);

Map<String, dynamic> _$BudgetToJson(_Budget instance) => <String, dynamic>{
  'id': instance.id,
  'amount': instance.amount,
  'startDate': dateTimeToJson(instance.startDate),
  'endDate': dateTimeToJson(instance.endDate),
  'currency': instance.currency,
  'plannedExpenses': instance.plannedExpenses.map((e) => e.toJson()).toList(),
};
