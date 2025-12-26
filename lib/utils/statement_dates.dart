class StatementWindow {
  StatementWindow({
    required this.start,
    required this.end,
    required this.due,
  });

  final DateTime start;
  final DateTime end;
  final DateTime due;
}

StatementWindow buildStatementWindow({
  required DateTime now,
  required int billingDay,
  required int graceDays,
}) {
  final billDay = billingDay.clamp(1, 28);
  final currentBilling = _safeDate(now.year, now.month, billDay);
  final cycleEnd = now.isBefore(currentBilling)
      ? _safeDate(now.year, now.month - 1, billDay)
      : currentBilling;
  final startMonth = cycleEnd.month - 1 <= 0 ? cycleEnd.month + 11 : cycleEnd.month - 1;
  final startYear = cycleEnd.month - 1 <= 0 ? cycleEnd.year - 1 : cycleEnd.year;
  final cycleStart = _safeDate(startYear, startMonth, billDay + 1);
  final due = cycleEnd.add(Duration(days: graceDays));
  return StatementWindow(
    start: _startOfDay(cycleStart),
    end: _endOfDay(cycleEnd),
    due: _startOfDay(due),
  );
}

DateTime nextDueDate({
  required DateTime now,
  required int billingDay,
  required int graceDays,
}) {
  final billDay = billingDay.clamp(1, 28);
  var cycleEnd = _safeDate(now.year, now.month, billDay);
  if (!now.isBefore(cycleEnd)) {
    cycleEnd = _safeDate(now.year, now.month + 1, billDay);
  }
  var due = cycleEnd.add(Duration(days: graceDays));
  if (due.isBefore(now)) {
    final nextCycleEnd = _safeDate(cycleEnd.year, cycleEnd.month + 1, billDay);
    due = nextCycleEnd.add(Duration(days: graceDays));
  }
  return due;
}

DateTime _safeDate(int year, int month, int day) {
  var y = year;
  var m = month;
  while (m <= 0) {
    m += 12;
    y -= 1;
  }
  while (m > 12) {
    m -= 12;
    y += 1;
  }
  final clampedDay = day.clamp(1, _daysInMonth(y, m));
  return DateTime(y, m, clampedDay);
}

int _daysInMonth(int year, int month) {
  final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
