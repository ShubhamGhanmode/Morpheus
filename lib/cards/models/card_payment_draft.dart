import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/models/json_converters.dart';

part 'card_payment_draft.freezed.dart';
part 'card_payment_draft.g.dart';

@freezed
abstract class CardPaymentDraft with _$CardPaymentDraft {
  const CardPaymentDraft._();

  @JsonSerializable(explicitToJson: true)
  factory CardPaymentDraft({
    required double amount,
    required String currency,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime date,
    String? accountId,
    String? note,
  }) = _CardPaymentDraft;

  factory CardPaymentDraft.fromJson(Map<String, dynamic> json) =>
      _$CardPaymentDraftFromJson(json);
}
