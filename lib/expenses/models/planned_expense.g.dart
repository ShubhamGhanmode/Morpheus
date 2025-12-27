// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlannedExpense _$PlannedExpenseFromJson(Map<String, dynamic> json) =>
    _PlannedExpense(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      dueDate: dateTimeFromJson(json['dueDate']),
      category: json['category'] as String?,
    );

Map<String, dynamic> _$PlannedExpenseToJson(_PlannedExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'amount': instance.amount,
      'dueDate': dateTimeToJson(instance.dueDate),
      'category': instance.category,
    };
