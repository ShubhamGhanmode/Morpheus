// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  category: json['category'] as String,
  date: dateTimeFromJson(json['date']),
  groupId: json['groupId'] as String?,
  note: json['note'] as String?,
  amountEur: (json['amountEur'] as num?)?.toDouble(),
  baseCurrency: json['baseCurrency'] as String?,
  baseRate: (json['baseRate'] as num?)?.toDouble(),
  amountInBaseCurrency: (json['amountInBaseCurrency'] as num?)?.toDouble(),
  budgetCurrency: json['budgetCurrency'] as String?,
  budgetRate: (json['budgetRate'] as num?)?.toDouble(),
  amountInBudgetCurrency: (json['amountInBudgetCurrency'] as num?)?.toDouble(),
  paymentSourceType: json['paymentSourceType'] == null
      ? 'cash'
      : _paymentSourceFromJson(json['paymentSourceType']),
  paymentSourceId: json['paymentSourceId'] as String?,
  transactionType: json['transactionType'] as String? ?? 'spend',
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'amount': instance.amount,
  'currency': instance.currency,
  'category': instance.category,
  'date': dateTimeToJson(instance.date),
  'groupId': instance.groupId,
  'note': instance.note,
  'amountEur': instance.amountEur,
  'baseCurrency': instance.baseCurrency,
  'baseRate': instance.baseRate,
  'amountInBaseCurrency': instance.amountInBaseCurrency,
  'budgetCurrency': instance.budgetCurrency,
  'budgetRate': instance.budgetRate,
  'amountInBudgetCurrency': instance.amountInBudgetCurrency,
  'paymentSourceType': instance.paymentSourceType,
  'paymentSourceId': instance.paymentSourceId,
  'transactionType': instance.transactionType,
};
