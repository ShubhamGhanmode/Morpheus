import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/expenses/models/recurring_transaction.dart';
import 'package:morpheus/expenses/models/subscription.dart';

part 'next_occurrence.freezed.dart';

@freezed
abstract class NextRecurring with _$NextRecurring {
  const NextRecurring._();

  const factory NextRecurring({
    required RecurringTransaction transaction,
    required DateTime nextDate,
  }) = _NextRecurring;
}

@freezed
abstract class NextSubscription with _$NextSubscription {
  const NextSubscription._();

  const factory NextSubscription({
    required Subscription subscription,
    required DateTime nextDate,
  }) = _NextSubscription;
}
