// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      renewalDate: dateTimeFromJson(json['renewalDate']),
      frequency:
          $enumDecodeNullable(
            _$RecurrenceFrequencyEnumMap,
            json['frequency'],
          ) ??
          RecurrenceFrequency.monthly,
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      reminderOffsets: json['reminderOffsets'] == null
          ? const <int>[]
          : intListFromJson(json['reminderOffsets']),
      active: json['active'] as bool? ?? true,
      category: json['category'] as String?,
      note: json['note'] as String?,
      lastNotified: nullableDateTimeFromJson(json['lastNotified']),
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'amount': instance.amount,
      'currency': instance.currency,
      'renewalDate': dateTimeToJson(instance.renewalDate),
      'frequency': _$RecurrenceFrequencyEnumMap[instance.frequency]!,
      'interval': instance.interval,
      'reminderOffsets': intListToJson(instance.reminderOffsets),
      'active': instance.active,
      'category': instance.category,
      'note': instance.note,
      'lastNotified': nullableDateTimeToJson(instance.lastNotified),
    };

const _$RecurrenceFrequencyEnumMap = {
  RecurrenceFrequency.daily: 'daily',
  RecurrenceFrequency.weekly: 'weekly',
  RecurrenceFrequency.monthly: 'monthly',
  RecurrenceFrequency.yearly: 'yearly',
};
