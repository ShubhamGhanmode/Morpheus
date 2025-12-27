import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/models/json_converters.dart';

part 'credit_card.freezed.dart';
part 'credit_card.g.dart';

@freezed
abstract class CreditCard with _$CreditCard {
  const CreditCard._();

  factory CreditCard({
    required String id,
    @JsonKey(readValue: _readBankName) required String bankName,
    @JsonKey(readValue: _readBankIconUrl) String? bankIconUrl,
    @JsonKey(readValue: _readCardNetwork) String? cardNetwork,
    @JsonKey(readValue: _readCardNumber) required String cardNumber,
    @JsonKey(readValue: _readHolderName) required String holderName,
    @JsonKey(readValue: _readExpiryDate) required String expiryDate,
    @JsonKey(readValue: _readCvv) required String cvv,
    @JsonKey(fromJson: cardColorFromJson, toJson: colorToJson)
    required Color cardColor,
    @JsonKey(fromJson: textColorFromJson, toJson: colorToJson)
    required Color textColor,
    @JsonKey(
      readValue: _readCreatedAt,
      fromJson: nullableDateTimeFromJson,
      toJson: nullableDateTimeToJson,
    )
    DateTime? createdAt,
    @JsonKey(
      readValue: _readUpdatedAt,
      fromJson: nullableDateTimeFromJson,
      toJson: nullableDateTimeToJson,
    )
    DateTime? updatedAt,
    @JsonKey(readValue: _readBillingDay) @Default(1) int billingDay,
    @JsonKey(readValue: _readGraceDays) @Default(15) int graceDays,
    @JsonKey(readValue: _readUsageLimit) double? usageLimit,
    @JsonKey(readValue: _readCurrency)
    @Default(AppConfig.baseCurrency)
    String currency,
    @JsonKey(readValue: _readAutopayEnabled, fromJson: _boolFromJson)
    @Default(false)
    bool autopayEnabled,
    @JsonKey(readValue: _readReminderEnabled, fromJson: _boolFromJson)
    @Default(false)
    bool reminderEnabled,
    @JsonKey(readValue: _readReminderOffsets, fromJson: intListFromJson, toJson: intListToJson)
    @Default(<int>[])
    List<int> reminderOffsets,
  }) = _CreditCard;

  factory CreditCard.create({
    required String id,
    required String bankName,
    String? bankIconUrl,
    String? cardNetwork,
    required String cardNumber,
    required String holderName,
    required String expiryDate,
    required String cvv,
    required Color cardColor,
    required Color textColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    int billingDay = 1,
    int graceDays = 15,
    double? usageLimit,
    String currency = AppConfig.baseCurrency,
    bool autopayEnabled = false,
    bool reminderEnabled = false,
    List<int> reminderOffsets = const [],
  }) {
    return CreditCard(
      id: id,
      bankName: bankName,
      bankIconUrl: bankIconUrl,
      cardNetwork: cardNetwork,
      cardNumber: cardNumber,
      holderName: holderName,
      expiryDate: expiryDate,
      cvv: cvv,
      cardColor: cardColor,
      textColor: textColor,
      createdAt: createdAt,
      updatedAt: updatedAt,
      billingDay: billingDay,
      graceDays: graceDays,
      usageLimit: usageLimit,
      currency: currency,
      autopayEnabled: autopayEnabled,
      reminderEnabled: reminderEnabled,
      reminderOffsets: reminderOffsets,
    );
  }

  factory CreditCard.fromJson(Map<String, dynamic> json) =>
      _$CreditCardFromJson(json);
}

Object? _readBankName(Map<dynamic, dynamic> json, String key) =>
    json['bankName'] ?? json['bank_name'] ?? 'Unknown';

Object? _readBankIconUrl(Map<dynamic, dynamic> json, String key) =>
    json['bankIconUrl'];

Object? _readCardNetwork(Map<dynamic, dynamic> json, String key) =>
    json['cardNetwork'] ?? json['card_network'];

Object? _readCardNumber(Map<dynamic, dynamic> json, String key) =>
    json['cardNumber'] ?? json['card_number'] ?? '**** **** **** 0000';

Object? _readHolderName(Map<dynamic, dynamic> json, String key) =>
    json['holderName'] ?? json['card_holder_name'] ?? '';

Object? _readExpiryDate(Map<dynamic, dynamic> json, String key) =>
    json['expiryDate'] ?? json['expiry_date'] ?? '';

Object? _readCvv(Map<dynamic, dynamic> json, String key) =>
    json['cvv'] ?? '***';

Object? _readBillingDay(Map<dynamic, dynamic> json, String key) =>
    json['billingDay'] ?? json['billing_day'] ?? 1;

Object? _readGraceDays(Map<dynamic, dynamic> json, String key) =>
    json['graceDays'] ?? json['grace_days'] ?? 15;

Object? _readUsageLimit(Map<dynamic, dynamic> json, String key) =>
    json['usageLimit'] ?? json['usage_limit'];

Object? _readCurrency(Map<dynamic, dynamic> json, String key) =>
    json['currency'] ?? json['cardCurrency'] ?? AppConfig.baseCurrency;

Object? _readReminderOffsets(Map<dynamic, dynamic> json, String key) =>
    json['reminderOffsets'] ?? json['reminder_offsets'] ?? const [];

Object? _readAutopayEnabled(Map<dynamic, dynamic> json, String key) =>
    json['autopayEnabled'] ?? json['autopay_enabled'] ?? false;

Object? _readReminderEnabled(Map<dynamic, dynamic> json, String key) =>
    json['reminderEnabled'] ?? json['reminder_enabled'] ?? false;

Object? _readCreatedAt(Map<dynamic, dynamic> json, String key) =>
    json['createdAt'] ?? json['created_at'];

Object? _readUpdatedAt(Map<dynamic, dynamic> json, String key) =>
    json['updatedAt'] ?? json['updated_at'];

bool _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return false;
}
