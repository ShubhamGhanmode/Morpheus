import 'package:morpheus/expenses/models/recurrence_frequency.dart';

DateTime nextRecurrenceDate({
  required DateTime anchor,
  required RecurrenceFrequency frequency,
  required int interval,
  DateTime? after,
  bool includeAnchorOnSameDay = false,
}) {
  final safeInterval = interval <= 0 ? 1 : interval;
  final target = after ?? DateTime.now();

  if (target.isBefore(anchor) ||
      (includeAnchorOnSameDay && _isSameDate(target, anchor))) {
    return anchor;
  }

  switch (frequency) {
    case RecurrenceFrequency.daily:
      return anchor.add(
        Duration(
          days: _stepsBetween(
            target.difference(anchor).inDays,
            safeInterval,
          ),
        ),
      );
    case RecurrenceFrequency.weekly:
      return anchor.add(
        Duration(
          days: _stepsBetween(
            target.difference(anchor).inDays,
            7 * safeInterval,
          ),
        ),
      );
    case RecurrenceFrequency.monthly:
      return _addMonths(
        anchor,
        _monthStepsBetween(target, anchor, safeInterval),
      );
    case RecurrenceFrequency.yearly:
      return _addMonths(
        anchor,
        _monthStepsBetween(target, anchor, safeInterval * 12),
      );
  }
}

int _stepsBetween(int diffDays, int stepSize) {
  if (diffDays < 0) return 0;
  final steps = (diffDays ~/ stepSize) + 1;
  return steps * stepSize;
}

int _monthStepsBetween(DateTime target, DateTime anchor, int stepMonths) {
  final monthsBetween = (target.year - anchor.year) * 12 +
      (target.month - anchor.month);
  if (monthsBetween < 0) return 0;
  final baseSteps = (monthsBetween ~/ stepMonths) * stepMonths;
  final candidate = _addMonths(anchor, baseSteps);
  if (candidate.isAfter(target)) return baseSteps;
  return baseSteps + stepMonths;
}

DateTime _addMonths(DateTime date, int months) {
  if (months <= 0) return date;
  final baseMonth = date.month - 1 + months;
  final year = date.year + (baseMonth ~/ 12);
  final month = (baseMonth % 12) + 1;
  final day = _clampDay(date.day, year, month);
  return DateTime(
    year,
    month,
    day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

int _clampDay(int day, int year, int month) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return day > lastDay ? lastDay : day;
}

bool _isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
