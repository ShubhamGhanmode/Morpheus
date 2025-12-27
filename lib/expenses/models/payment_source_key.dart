import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_source_key.freezed.dart';

@freezed
abstract class PaymentSourceKey with _$PaymentSourceKey {
  const PaymentSourceKey._();

  const factory PaymentSourceKey({
    required String type,
    required String id,
  }) = _PaymentSourceKey;
}
