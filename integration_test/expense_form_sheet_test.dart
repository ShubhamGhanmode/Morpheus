import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/expenses/view/widgets/expense_form_sheet.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';

class FakeSettingsCubit extends Cubit<SettingsState>
    implements SettingsCubit {
  FakeSettingsCubit(String baseCurrency)
      : super(SettingsState(baseCurrency: baseCurrency));

  @override
  void setThemeMode(ThemeMode mode) {}

  @override
  void setContrast(AppContrast contrast) {}

  @override
  Future<bool> setAppLockEnabled(bool enabled) async => true;

  @override
  void setTestModeEnabled(bool enabled) {}

  @override
  Future<void> setBaseCurrency(String currency) async {
    emit(state.copyWith(baseCurrency: currency));
  }

  @override
  Future<void> setCardRemindersEnabled(bool enabled) async {}
}

class FakeCardCubit extends Cubit<CardState> implements CardCubit {
  FakeCardCubit(List<CreditCard> cards) : super(CardState(cards: cards));

  @override
  Future<void> loadCards() async {}

  @override
  Future<void> addCard(CreditCard card) async {}

  @override
  Future<void> deleteCard(String id) async {}
}

class FakeAccountsCubit extends Cubit<AccountsState> implements AccountsCubit {
  FakeAccountsCubit(List<AccountCredential> accounts)
      : super(AccountsState(items: accounts));

  @override
  Future<void> load() async {}

  @override
  Future<void> save(AccountCredential account) async {}

  @override
  Future<void> delete(String id) async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('selecting a card updates currency', (tester) async {
    final card = CreditCard(
      id: 'card_1',
      bankName: 'Axis Bank',
      cardNumber: '4242 4242 4242 4242',
      holderName: 'Alex',
      expiryDate: '12/28',
      cvv: '123',
      cardColor: Colors.blueGrey,
      textColor: Colors.white,
      billingDay: 12,
      graceDays: 15,
      currency: 'INR',
    );

    final settingsCubit = FakeSettingsCubit('EUR');
    final cardCubit = FakeCardCubit([card]);
    final accountsCubit = FakeAccountsCubit(const <AccountCredential>[]);

    addTearDown(() async {
      await settingsCubit.close();
      await cardCubit.close();
      await accountsCubit.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
          BlocProvider<CardCubit>.value(value: cardCubit),
          BlocProvider<AccountsCubit>.value(value: accountsCubit),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExpenseFormSheet()),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('expense_payment_source_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Card').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expense_card_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(card.bankName).last);
    await tester.pumpAndSettle();

    final currencyState = tester.state<FormFieldState<String>>(
      find.byKey(const Key('expense_currency_dropdown')),
    );
    expect(currencyState.value, 'INR');
  });

  testWidgets('selecting an account updates currency', (tester) async {
    final account = AccountCredential(
      id: 'acct_1',
      bankName: 'HDFC',
      username: 'alex',
      password: 'secret',
      lastUpdated: DateTime(2025, 1, 1),
      currency: 'INR',
    );

    final settingsCubit = FakeSettingsCubit('EUR');
    final cardCubit = FakeCardCubit(const []);
    final accountsCubit = FakeAccountsCubit([account]);

    addTearDown(() async {
      await settingsCubit.close();
      await cardCubit.close();
      await accountsCubit.close();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SettingsCubit>.value(value: settingsCubit),
          BlocProvider<CardCubit>.value(value: cardCubit),
          BlocProvider<AccountsCubit>.value(value: accountsCubit),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ExpenseFormSheet()),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('expense_payment_source_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bank account').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expense_account_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(account.bankName).last);
    await tester.pumpAndSettle();

    final currencyState = tester.state<FormFieldState<String>>(
      find.byKey(const Key('expense_currency_dropdown')),
    );
    expect(currencyState.value, 'INR');
  });
}
