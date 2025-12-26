import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:morpheus/bills_calendar_page.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/utils/statement_dates.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows autopay and manual badges', (tester) async {
    final now = DateTime.now();
    final autopayCard = CreditCard(
      id: 'card_auto',
      bankName: 'Revolut',
      cardNumber: '4242 4242 4242 4242',
      holderName: 'Alex',
      expiryDate: '10/28',
      cvv: '123',
      cardColor: Colors.deepPurple,
      textColor: Colors.white,
      billingDay: 5,
      graceDays: 10,
      currency: 'EUR',
      autopayEnabled: true,
    );
    final manualCard = CreditCard(
      id: 'card_manual',
      bankName: 'HDFC',
      cardNumber: '5555 5555 5555 4444',
      holderName: 'Alex',
      expiryDate: '11/27',
      cvv: '456',
      cardColor: Colors.teal,
      textColor: Colors.white,
      billingDay: 12,
      graceDays: 12,
      currency: 'EUR',
      autopayEnabled: false,
    );

    final autoWindow = buildStatementWindow(
      now: now,
      billingDay: autopayCard.billingDay,
      graceDays: autopayCard.graceDays,
    );
    final manualWindow = buildStatementWindow(
      now: now,
      billingDay: manualCard.billingDay,
      graceDays: manualCard.graceDays,
    );

    final expenses = [
      Expense(
        title: 'Coffee',
        amount: 20,
        currency: 'EUR',
        category: 'Food',
        date: autoWindow.start.add(const Duration(days: 1)),
        paymentSourceType: 'card',
        paymentSourceId: autopayCard.id,
      ),
      Expense(
        title: 'Fuel',
        amount: 50,
        currency: 'EUR',
        category: 'Transport',
        date: manualWindow.start.add(const Duration(days: 1)),
        paymentSourceType: 'card',
        paymentSourceId: manualCard.id,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: BillsCalendarPage(
          cards: [autopayCard, manualCard],
          expenses: expenses,
          baseCurrency: 'EUR',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Autopay'), findsOneWidget);
    expect(find.text('Manual'), findsOneWidget);
    expect(find.text(autopayCard.bankName), findsOneWidget);
    expect(find.text(manualCard.bankName), findsOneWidget);
  });
}
