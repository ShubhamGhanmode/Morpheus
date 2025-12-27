import 'package:flutter_test/flutter_test.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/services/expense_service.dart';
import 'package:morpheus/services/forex_service.dart';

class FakeForexService implements ForexService {
  FakeForexService(this.ratesByBase);

  final Map<String, Map<String, double>> ratesByBase;

  @override
  Future<Map<String, double>> fetchRates({
    required DateTime date,
    required String base,
    required List<String> symbols,
  }) async {
    final available = ratesByBase[base] ?? {};
    final result = <String, double>{};
    for (final symbol in symbols) {
      final rate = available[symbol];
      if (rate != null) {
        result[symbol] = rate;
      }
    }
    return result;
  }

  @override
  Future<double?> latestRate({String base = 'EUR', required String symbol}) async {
    return ratesByBase[base]?[symbol];
  }
}

void main() {
  group('ExpenseService.prepareExpense', () {
    test('fills base currency and rates from forex data', () async {
      final forex = FakeForexService({
        'INR': {'EUR': 0.011},
      });
      final service = ExpenseService(forexService: forex);
      final expense = Expense.create(
        title: 'Test',
        amount: 1000,
        currency: 'INR',
        category: 'Misc',
        date: DateTime(2025, 1, 15),
      );

      final prepared = await service.prepareExpense(
        expense,
        baseCurrency: 'EUR',
        budgets: const <Budget>[],
      );

      expect(prepared.baseCurrency, 'EUR');
      expect(prepared.baseRate, 0.011);
      expect(prepared.amountInBaseCurrency, closeTo(11.0, 0.0001));
      expect(prepared.amountEur, closeTo(11.0, 0.0001));
    });

    test('defaults base currency to active budget currency', () async {
      final forex = FakeForexService({});
      final service = ExpenseService(forexService: forex);
      final expense = Expense.create(
        title: 'Groceries',
        amount: 500,
        currency: 'INR',
        category: 'Food',
        date: DateTime(2025, 1, 12),
      );
      final budget = Budget.create(
        amount: 2000,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 31),
        currency: 'INR',
      );

      final prepared = await service.prepareExpense(
        expense,
        budgets: [budget],
      );

      expect(prepared.baseCurrency, 'INR');
      expect(prepared.baseRate, 1);
      expect(prepared.amountInBaseCurrency, 500);
      expect(prepared.budgetCurrency, 'INR');
      expect(prepared.amountInBudgetCurrency, 500);
    });
  });
}
