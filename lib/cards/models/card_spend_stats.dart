import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:morpheus/utils/statement_dates.dart';

part 'card_spend_stats.freezed.dart';
part 'card_spend_stats.g.dart';

@freezed
abstract class CardSpendStats with _$CardSpendStats {
  const CardSpendStats._();

  @JsonSerializable(explicitToJson: true)
  factory CardSpendStats({
    @JsonKey(fromJson: statementWindowFromJson, toJson: statementWindowToJson)
    required StatementWindow window,
    required double statementBalance,
    required double unbilledBalance,
    required double totalBalance,
    required double statementCharges,
    required double statementPayments,
    required double statementBalanceBase,
    required double unbilledBalanceBase,
    required double totalBalanceBase,
    required double statementPaymentsBase,
    double? available,
    double? availableBase,
    double? utilization,
  }) = _CardSpendStats;

  factory CardSpendStats.fromJson(Map<String, dynamic> json) =>
      _$CardSpendStatsFromJson(json);
}
