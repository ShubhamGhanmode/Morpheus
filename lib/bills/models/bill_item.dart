import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/models/json_converters.dart';

part 'bill_item.freezed.dart';
part 'bill_item.g.dart';

@freezed
abstract class BillItem with _$BillItem {
  const BillItem._();

  @JsonSerializable(explicitToJson: true)
  factory BillItem({
    required CreditCard card,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime due,
    required double amount,
    required double amountInBase,
    required String currency,
    required bool overdue,
  }) = _BillItem;

  factory BillItem.fromJson(Map<String, dynamic> json) =>
      _$BillItemFromJson(json);
}
