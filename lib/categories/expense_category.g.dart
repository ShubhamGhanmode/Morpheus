// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseCategory _$ExpenseCategoryFromJson(Map<String, dynamic> json) =>
    _ExpenseCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '',
    );

Map<String, dynamic> _$ExpenseCategoryToJson(_ExpenseCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'emoji': instance.emoji,
    };
