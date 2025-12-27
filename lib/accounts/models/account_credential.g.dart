// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'account_credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AccountCredential _$AccountCredentialFromJson(Map<String, dynamic> json) =>
    _AccountCredential(
      id: json['id'] as String,
      bankName: _readBankName(json, 'bankName') as String,
      bankIconUrl: _readBankIconUrl(json, 'bankIconUrl') as String?,
      username: _readUsername(json, 'username') as String,
      password: _readPassword(json, 'password') as String,
      website: _readWebsite(json, 'website') as String?,
      lastUpdated: dateTimeFromJson(_readLastUpdated(json, 'lastUpdated')),
      brandColor: nullableColorFromJson(json['brandColor']),
      currency:
          _readCurrency(json, 'currency') as String? ?? AppConfig.baseCurrency,
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$AccountCredentialToJson(_AccountCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bankName': instance.bankName,
      'bankIconUrl': instance.bankIconUrl,
      'username': instance.username,
      'password': instance.password,
      'website': instance.website,
      'lastUpdated': dateTimeToJson(instance.lastUpdated),
      'brandColor': nullableColorToJson(instance.brandColor),
      'currency': instance.currency,
      'balance': instance.balance,
    };
