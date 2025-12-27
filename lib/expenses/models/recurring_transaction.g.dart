// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecurringTransaction _$RecurringTransactionFromJson(
  Map<String, dynamic> json,
) => _RecurringTransaction(
  id: json['id'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  category: json['category'] as String,
  startDate: dateTimeFromJson(json['startDate']),
  frequency:
      $enumDecodeNullable(_$RecurrenceFrequencyEnumMap, json['frequency']) ??
      RecurrenceFrequency.monthly,
  interval: (json['interval'] as num?)?.toInt() ?? 1,
  lastGenerated: nullableDateTimeFromJson(json['lastGenerated']),
  active: json['active'] as bool? ?? true,
  note: json['note'] as String?,
  paymentSourceType: json['paymentSourceType'] as String? ?? 'cash',
  paymentSourceId: json['paymentSourceId'] as String?,
);

Map<String, dynamic> _$RecurringTransactionToJson(
  _RecurringTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'amount': instance.amount,
  'currency': instance.currency,
  'category': instance.category,
  'startDate': dateTimeToJson(instance.startDate),
  'frequency': _$RecurrenceFrequencyEnumMap[instance.frequency]!,
  'interval': instance.interval,
  'lastGenerated': nullableDateTimeToJson(instance.lastGenerated),
  'active': instance.active,
  'note': instance.note,
  'paymentSourceType': instance.paymentSourceType,
  'paymentSourceId': instance.paymentSourceId,
};

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.daily: 'daily',
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.monthly: 'monthly',
  RecurrenceFrequency.yearly: 'yearly',
};
