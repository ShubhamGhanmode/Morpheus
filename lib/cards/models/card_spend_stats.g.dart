// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_spend_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CardSpendStats _$CardSpendStatsFromJson(Map<String, dynamic> json) =>
    _CardSpendStats(
      window: statementWindowFromJson(json['window']),
      statementBalance: (json['statementBalance'] as num).toDouble(),
      unbilledBalance: (json['unbilledBalance'] as num).toDouble(),
      totalBalance: (json['totalBalance'] as num).toDouble(),
      statementCharges: (json['statementCharges'] as num).toDouble(),
      statementPayments: (json['statementPayments'] as num).toDouble(),
      statementBalanceBase: (json['statementBalanceBase'] as num).toDouble(),
      unbilledBalanceBase: (json['unbilledBalanceBase'] as num).toDouble(),
      totalBalanceBase: (json['totalBalanceBase'] as num).toDouble(),
      statementPaymentsBase: (json['statementPaymentsBase'] as num).toDouble(),
      available: (json['available'] as num?)?.toDouble(),
      availableBase: (json['availableBase'] as num?)?.toDouble(),
      utilization: (json['utilization'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$CardSpendStatsToJson(_CardSpendStats instance) =>
    <String, dynamic>{
      'window': statementWindowToJson(instance.window),
      'statementBalance': instance.statementBalance,
      'unbilledBalance': instance.unbilledBalance,
      'totalBalance': instance.totalBalance,
      'statementCharges': instance.statementCharges,
      'statementPayments': instance.statementPayments,
      'statementBalanceBase': instance.statementBalanceBase,
      'unbilledBalanceBase': instance.unbilledBalanceBase,
      'totalBalanceBase': instance.totalBalanceBase,
      'statementPaymentsBase': instance.statementPaymentsBase,
      'available': instance.available,
      'availableBase': instance.availableBase,
      'utilization': instance.utilization,
    };
