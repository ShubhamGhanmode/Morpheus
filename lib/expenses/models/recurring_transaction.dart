import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/expenses/models/recurrence_frequency.dart';
import 'package:morpheus/expenses/utils/recurrence_utils.dart';
import 'package:morpheus/models/json_converters.dart';
import 'package:uuid/uuid.dart';

part 'recurring_transaction.freezed.dart';
part 'recurring_transaction.g.dart';

@freezed
abstract class RecurringTransaction with _$RecurringTransaction {
  const RecurringTransaction._();

  @JsonSerializable(explicitToJson: true)
  factory RecurringTransaction({
    required String id,
    required String title,
    required double amount,
    required String currency,
    required String category,
    @JsonKey(fromJson: dateTimeFromJson, toJson: dateTimeToJson)
    required DateTime startDate,
    @Default(RecurrenceFrequency.monthly) RecurrenceFrequency frequency,
    @Default(1) int interval,
    @JsonKey(fromJson: nullableDateTimeFromJson, toJson: nullableDateTimeToJson)
    DateTime? lastGenerated,
    @Default(true) bool active,
    String? note,
    @Default('cash') String paymentSourceType,
    String? paymentSourceId,
  }) = _RecurringTransaction;

  factory RecurringTransaction.create({
    String? id,
    required String title,
    required double amount,
    required String currency,
    required String category,
    required DateTime startDate,
    RecurrenceFrequency frequency = RecurrenceFrequency.monthly,
    int interval = 1,
    DateTime? lastGenerated,
    bool active = true,
    String? note,
    String paymentSourceType = 'cash',
    String? paymentSourceId,
  }) {
    return RecurringTransaction(
      id: id ?? const Uuid().v4(),
      title: title,
      amount: amount,
      currency: currency,
      category: category,
      startDate: startDate,
      frequency: frequency,
      interval: interval,
      lastGenerated: lastGenerated,
      active: active,
      note: note,
      paymentSourceType: paymentSourceType,
      paymentSourceId: paymentSourceId,
    );
  }

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) =>
      _$RecurringTransactionFromJson(json);

  DateTime nextOccurrence({DateTime? from}) {
    return nextRecurrenceDate(
      anchor: startDate,
      frequency: frequency,
      interval: interval,
      after: from ?? DateTime.now(),
    );
  }
}
