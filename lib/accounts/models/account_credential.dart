import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:uuid/uuid.dart';

class AccountCredential extends Equatable {
  AccountCredential({
    String? id,
    required this.bankName,
    this.bankIconUrl,
    required this.username,
    required this.password,
    this.website,
    required this.lastUpdated,
    this.brandColor,
    this.currency = AppConfig.baseCurrency,
    this.balance = 0,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String bankName;
  final String? bankIconUrl;
  final String username;
  final String password;
  final String? website;
  final DateTime lastUpdated;
  final Color? brandColor;
  final String currency;
  final double balance;

  AccountCredential copyWith({
    String? id,
    String? bankName,
    String? bankIconUrl,
    String? username,
    String? password,
    String? website,
    DateTime? lastUpdated,
    Color? brandColor,
    String? currency,
    double? balance,
  }) {
    return AccountCredential(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      bankIconUrl: bankIconUrl ?? this.bankIconUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      website: website ?? this.website,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      brandColor: brandColor ?? this.brandColor,
      currency: currency ?? this.currency,
      balance: balance ?? this.balance,
    );
  }

  Map<String, dynamic> toMap() => {
    'bankName': bankName,
    'bankIconUrl': bankIconUrl,
    'username': username,
    'password': password,
    'website': website,
    'lastUpdated': lastUpdated.millisecondsSinceEpoch,
    'brandColor': brandColor?.value,
    'currency': currency,
    'balance': balance,
  };

  factory AccountCredential.fromMap(String id, Map<String, dynamic> map) {
    DateTime toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return AccountCredential(
      id: id,
      bankName: (map['bankName'] ?? map['bank_name'] ?? 'Bank').toString(),
      bankIconUrl:
          (map['bankIconUrl'] ?? map['bank_icon_url'])?.toString(),
      username: (map['username'] ?? map['login_id'] ?? '').toString(),
      password: (map['password'] ?? map['login_password'] ?? '').toString(),
      website: map['website'] as String?,
      lastUpdated: toDate(
        map['lastUpdated'] ??
            map['updated_at'] ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      brandColor: map['brandColor'] != null
          ? Color(map['brandColor'] as int)
          : null,
      currency: (map['currency'] ?? map['accountCurrency'] ?? AppConfig.baseCurrency).toString(),
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    bankName,
    bankIconUrl,
    username,
    password,
    website,
    lastUpdated,
    brandColor,
    currency,
    balance,
  ];
}
