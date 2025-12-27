import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/expense.dart';

double amountInDisplayCurrency(
  Expense expense,
  String displayCurrency,
  double? budgetToEur,
) {
  final converted = expense.amountForCurrency(displayCurrency);
  if (displayCurrency == expense.currency) return converted;

  if (displayCurrency == AppConfig.baseCurrency && expense.amountEur != null) {
    return expense.amountEur!;
  }

  if (converted != expense.amount) return converted;

  if (displayCurrency == expense.budgetCurrency &&
      expense.amountInBudgetCurrency != null) {
    return expense.amountInBudgetCurrency!;
  }

  if (budgetToEur != null &&
      budgetToEur > 0 &&
      expense.amountEur != null &&
      displayCurrency != AppConfig.baseCurrency) {
    return expense.amountEur! / budgetToEur;
  }

  return converted;
}

String? alternateCurrency(String currency) {
  if (!AppConfig.enableSecondaryCurrency) return null;
  if (currency == AppConfig.baseCurrency) return AppConfig.secondaryCurrency;
  if (currency == AppConfig.secondaryCurrency) return AppConfig.baseCurrency;
  return null;
}

double? convertToAlternateCurrency({
  required double amount,
  required String currency,
  double? baseToSecondaryRate,
  double? currencyToBaseRate,
}) {
  if (currency == AppConfig.baseCurrency) {
    if (baseToSecondaryRate == null) return null;
    return amount * baseToSecondaryRate;
  }
  if (currency == AppConfig.secondaryCurrency) {
    if (currencyToBaseRate != null && currencyToBaseRate > 0) {
      return amount * currencyToBaseRate;
    }
    if (baseToSecondaryRate != null && baseToSecondaryRate > 0) {
      return amount / baseToSecondaryRate;
    }
  }
  return null;
}

double? expenseAmountInBaseCurrency(
  Expense expense,
  double? baseToSecondaryRate,
) {
  if (expense.currency == AppConfig.baseCurrency) return expense.amount;
  if (expense.amountEur != null) return expense.amountEur;
  if (expense.currency == AppConfig.secondaryCurrency &&
      baseToSecondaryRate != null &&
      baseToSecondaryRate > 0) {
    return expense.amount / baseToSecondaryRate;
  }
  return null;
}

double? expenseAmountInSecondaryCurrency(
  Expense expense,
  double? baseToSecondaryRate,
) {
  if (expense.currency == AppConfig.secondaryCurrency) return expense.amount;
  final base = expenseAmountInBaseCurrency(expense, baseToSecondaryRate);
  if (base != null && baseToSecondaryRate != null) {
    return base * baseToSecondaryRate;
  }
  return null;
}
