// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExpenseGroup _$ExpenseGroupFromJson(Map<String, dynamic> json) =>
    _ExpenseGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      merchant: json['merchant'] as String?,
      expenseIds:
          (json['expenseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      receiptImageUri: json['receiptImageUri'] as String?,
      createdAt: nullableDateTimeFromJson(json['createdAt']),
      currency: json['currency'] as String?,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      receiptDate: nullableDateTimeFromJson(json['receiptDate']),
    );

Map<String, dynamic> _$ExpenseGroupToJson(_ExpenseGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'merchant': instance.merchant,
      'expenseIds': instance.expenseIds,
      'receiptImageUri': instance.receiptImageUri,
      'createdAt': nullableDateTimeToJson(instance.createdAt),
      'currency': instance.currency,
      'totalAmount': instance.totalAmount,
      'receiptDate': nullableDateTimeToJson(instance.receiptDate),
    };
