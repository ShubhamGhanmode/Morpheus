import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/expenses/models/recurrence_frequency.dart';
import 'package:morpheus/expenses/utils/recurrence_utils.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

@freezed
abstract class Subscription with _$Subscription {
  const Subscription._();

  @JsonSerializable(explicitToJson: true)
  factory Subscription({
    required String id,
    required String name,
    required double amount,
    required String currency,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime renewalDate,
    @Default(RecurrenceFrequency.monthly) RecurrenceFrequency frequency,
    @Default(1) int interval,
    @JsonKey(fromJson: intListFromJson, toJson: intListToJson)
    @Default(<int>[])
    List<int> reminderOffsets,
    @Default(true) bool active,
    String? category,
    String? note,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? lastNotified,
  }) = _Subscription;

  factory Subscription.create({
    String? id,
    required String name,
    required double amount,
    required String currency,
    required DateTime renewalDate,
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
    int interval = 1,
    List<int> reminderOffsets = const [],
    bool active = true,
    String? category,
    String? note,
    DateTime? lastNotified,
  }) {
    return Subscription(
      id: id ?? const Uuid().v4(),
      name: name,
      amount: amount,
      currency: currency,
      renewalDate: renewalDate,
      frequency: frequency,
      interval: interval,
      reminderOffsets: reminderOffsets,
      active: active,
      category: category,
      note: note,
      lastNotified: lastNotified,
    );
  }

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  DateTime nextRenewal({DateTime? from}) {
    return nextRecurrenceDate(
      anchor: renewalDate,
      frequency: frequency,
      interval: interval,
      after: from ?? DateTime.now(),
      includeAnchorOnSameDay: true,
    );
  }
}
