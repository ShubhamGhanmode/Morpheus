import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/utils/statement_dates.dart';

class CardBalance {
  CardBalance({
    required this.window,
    required this.unbilledStart,
    required this.statementBalance,
    required this.unbilledBalance,
    required this.totalBalance,
    required this.statementCharges,
    required this.statementPayments,
  });

  final StatementWindow window;
  final DateTime unbilledStart;
  final double statementBalance;
  final double unbilledBalance;
  final double totalBalance;
  final double statementCharges;
  final double statementPayments;
}

CardBalance computeCardBalance({
  required List<Expense> expenses,
  required CreditCard card,
  required String currency,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final window = buildStatementWindow(
    now: clock,
    billingDay: card.billingDay,
    graceDays: card.graceDays,
  );
  final relevant = expenses.where((e) {
    final type = e.paymentSourceType.toLowerCase();
    if (type != 'card' && type != 'credit' && type != 'credit_card') {
      return false;
    }
    final sourceId = (e.paymentSourceId ?? '').trim();
    if (sourceId.isEmpty) return false;
    if (sourceId == card.id) return true;
    final sourceDigits = sourceId.replaceAll(RegExp(r'\D'), '');
    final cardDigits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    return sourceDigits.isNotEmpty &&
        cardDigits.isNotEmpty &&
        sourceDigits == cardDigits;
  }).toList();

  double statementCharges = 0;
  double statementPayments = 0;
  double unbilledBalance = 0;

  for (final e in relevant) {
    final amount = e.amountForCurrency(currency);
    if (!e.date.isBefore(window.start) && !e.date.isAfter(window.end)) {
      if (amount >= 0) {
        statementCharges += amount;
      } else {
        statementPayments += amount.abs();
      }
    } else if (e.date.isAfter(window.end) && !e.date.isAfter(clock)) {
      unbilledBalance += amount;
    }
  }

  final statementBalance = statementCharges - statementPayments;
  final totalBalance = statementBalance + unbilledBalance;
  return CardBalance(
    window: window,
    unbilledStart: window.end.add(const Duration(milliseconds: 1)),
    statementBalance: statementBalance,
    unbilledBalance: unbilledBalance,
    totalBalance: totalBalance,
    statementCharges: statementCharges,
    statementPayments: statementPayments,
  );
}
