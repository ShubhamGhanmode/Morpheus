import 'package:freezed_annotation/freezed_annotation.dart';

part 'spending_anomaly.freezed.dart';

enum AnomalyType { category, merchant }

@freezed
abstract class SpendingAnomaly with _$SpendingAnomaly {
  const SpendingAnomaly._();

  factory SpendingAnomaly({
    required AnomalyType type,
    required String label,
    required double currentAmount,
    required double averageAmount,
  }) = _SpendingAnomaly;

  double get delta => currentAmount - averageAmount;

  double get multiplier =>
      averageAmount <= 0 ? 0 : currentAmount / averageAmount;
}
