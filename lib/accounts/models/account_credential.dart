import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'account_credential.freezed.dart';
part 'account_credential.g.dart';

@freezed
abstract class AccountCredential with _$AccountCredential {
  const AccountCredential._();

  factory AccountCredential({
    required String id,
    @JsonKey(readValue: _readBankName) required String bankName,
    @JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,
    @JsonKey(readValue: _readUsername) required String username,
    @JsonKey(readValue: _readPassword) required String password,
    @JsonKey(readValue: _readWebsite) String? website,
    @JsonKey(
      readValue: _readLastUpdated,
      fromJson: dateTimeFromJson,
      toJson: dateTimeToJson,
    )
    required DateTime lastUpdated,
    @JsonKey(fromJson: nullableColorFromJson, toJson: nullableColorToJson)
    Color? brandColor,
    @JsonKey(readValue: _readCurrency)
    @Default(AppConfig.baseCurrency)
    String currency,
    @Default(0) double balance,
  }) = _AccountCredential;

  factory AccountCredential.create({
    String? id,
    required String bankName,
    String? bankIconUrl,
    required String username,
    required String password,
    String? website,
    required DateTime lastUpdated,
    Color? brandColor,
    String currency = AppConfig.baseCurrency,
    double balance = 0,
  }) {
    return AccountCredential(
      id: id ?? const Uuid().v4(),
      bankName: bankName,
      bankIconUrl: bankIconUrl,
      username: username,
      password: password,
      website: website,
      lastUpdated: lastUpdated,
      brandColor: brandColor,
      currency: currency,
      balance: balance,
    );
  }

  factory AccountCredential.fromJson(Map<String, dynamic> json) =>
      _$AccountCredentialFromJson(json);
}

Object? _readBankName(Map<dynamic, dynamic> json, String key) =>
    json['bankName'] ?? json['bank_name'] ?? 'Bank';

Object? _readBankIconUrl(Map<dynamic, dynamic> json, String key) =>
    json['bankIconUrl'] ?? json['bank_icon_url'];

Object? _readUsername(Map<dynamic, dynamic> json, String key) =>
    json['username'] ?? json['login_id'] ?? '';

Object? _readPassword(Map<dynamic, dynamic> json, String key) =>
    json['password'] ?? json['login_password'] ?? '';

Object? _readWebsite(Map<dynamic, dynamic> json, String key) => json['website'];

Object? _readLastUpdated(Map<dynamic, dynamic> json, String key) =>
    json['lastUpdated'] ??
    json['updated_at'] ??
    DateTime.now().millisecondsSinceEpoch;

Object? _readCurrency(Map<dynamic, dynamic> json, String key) =>
    json['currency'] ?? json['accountCurrency'] ?? AppConfig.baseCurrency;
