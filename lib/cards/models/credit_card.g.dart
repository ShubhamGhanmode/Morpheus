// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreditCard _$CreditCardFromJson(Map<String, dynamic> json) => _CreditCard(
  id: json['id'] as String,
  bankName: _readBankName(json, 'bankName') as String,
  bankIconUrl: _readBankIconUrl(json, 'bankIconUrl') as String?,
  cardNetwork: _readCardNetwork(json, 'cardNetwork') as String?,
  cardNumber: _readCardNumber(json, 'cardNumber') as String,
  holderName: _readHolderName(json, 'holderName') as String,
  expiryDate: _readExpiryDate(json, 'expiryDate') as String,
  cvv: _readCvv(json, 'cvv') as String,
  cardColor: cardColorFromJson(json['cardColor']),
  textColor: textColorFromJson(json['textColor']),
  createdAt: nullableDateTimeFromJson(_readCreatedAt(json, 'createdAt')),
  updatedAt: nullableDateTimeFromJson(_readUpdatedAt(json, 'updatedAt')),
  billingDay: (_readBillingDay(json, 'billingDay') as num?)?.toInt() ?? 1,
  graceDays: (_readGraceDays(json, 'graceDays') as num?)?.toInt() ?? 15,
  usageLimit: (_readUsageLimit(json, 'usageLimit') as num?)?.toDouble(),
  currency:
      _readCurrency(json, 'currency') as String? ?? AppConfig.baseCurrency,
  autopayEnabled: _readAutopayEnabled(json, 'autopayEnabled') == null
      ? false
      : _boolFromJson(_readAutopayEnabled(json, 'autopayEnabled')),
  reminderEnabled: _readReminderEnabled(json, 'reminderEnabled') == null
      ? false
      : _boolFromJson(_readReminderEnabled(json, 'reminderEnabled')),
  reminderOffsets: _readReminderOffsets(json, 'reminderOffsets') == null
      ? const <int>[]
      : intListFromJson(_readReminderOffsets(json, 'reminderOffsets')),
);

Map<String, dynamic> _$CreditCardToJson(_CreditCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bankName': instance.bankName,
      'bankIconUrl': instance.bankIconUrl,
      'cardNetwork': instance.cardNetwork,
      'cardNumber': instance.cardNumber,
      'holderName': instance.holderName,
      'expiryDate': instance.expiryDate,
      'cvv': instance.cvv,
      'cardColor': colorToJson(instance.cardColor),
      'textColor': colorToJson(instance.textColor),
      'createdAt': nullableDateTimeToJson(instance.createdAt),
      'updatedAt': nullableDateTimeToJson(instance.updatedAt),
      'billingDay': instance.billingDay,
      'graceDays': instance.graceDays,
      'usageLimit': instance.usageLimit,
      'currency': instance.currency,
      'autopayEnabled': instance.autopayEnabled,
      'reminderEnabled': instance.reminderEnabled,
      'reminderOffsets': intListToJson(instance.reminderOffsets),
    };
