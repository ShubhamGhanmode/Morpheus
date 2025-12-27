// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillItem _$BillItemFromJson(Map<String, dynamic> json) => _BillItem(
  card: CreditCard.fromJson(json['card'] as Map<String, dynamic>),
  due: dateTimeFromJson(json['due']),
  amount: (json['amount'] as num).toDouble(),
  amountInBase: (json['amountInBase'] as num).toDouble(),
  currency: json['currency'] as String,
  overdue: json['overdue'] as bool,
);

Map<String, dynamic> _$BillItemToJson(_BillItem instance) => <String, dynamic>{
  'card': instance.card.toJson(),
  'due': dateTimeToJson(instance.due),
  'amount': instance.amount,
  'amountInBase': instance.amountInBase,
  'currency': instance.currency,
  'overdue': instance.overdue,
};
