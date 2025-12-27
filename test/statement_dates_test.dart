import 'package:flutter_test/flutter_test.dart';
import 'package:morpheus/utils/statement_dates.dart';

void main() {
  group('statement dates', () {
    test('uses previous cycle when before billing day', () {
      final now = DateTime(2025, 2, 10);
      final window = buildStatementWindow(
        now: now,
        billingDay: 15,
        graceDays: 10,
      );

      expect(window.start, DateTime(2024, 12, 16));
      expect(window.end, DateTime(2025, 1, 15));
      expect(window.due, DateTime(2025, 1, 25));
    });

    test('uses current cycle when after billing day', () {
      final now = DateTime(2025, 2, 20);
      final window = buildStatementWindow(
        now: now,
        billingDay: 15,
        graceDays: 10,
      );

      expect(window.start, DateTime(2025, 1, 16));
      expect(window.end, DateTime(2025, 2, 15));
      expect(window.due, DateTime(2025, 2, 25));
    });

    test('nextDueDate rolls forward when due date has passed', () {
      final now = DateTime(2025, 2, 28);
      final due = nextDueDate(
        now: now,
        billingDay: 1,
        graceDays: 5,
      );

      expect(due, DateTime(2025, 3, 6));
    });
  });
}
