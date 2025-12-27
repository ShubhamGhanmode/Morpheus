// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_payment_draft.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardPaymentDraft _$CardPaymentDraftFromJson(Map<String, dynamic> json) =>
    _CardPaymentDraft(
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      date: dateTimeFromJson(json['date']),
      accountId: json['accountId'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$CardPaymentDraftToJson(_CardPaymentDraft instance) =>
    <String, dynamic>{
      'amount': instance.amount,
      'currency': instance.currency,
      'date': dateTimeToJson(instance.date),
      'accountId': instance.accountId,
      'note': instance.note,
    };
