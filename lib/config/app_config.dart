class AppConfig {
  static const String baseCurrency = 'EUR';
  static const String secondaryCurrency = 'INR';
  static const bool enableSecondaryCurrency = true;

  static List<String> get supportedCurrencies =>
      enableSecondaryCurrency ? [baseCurrency, secondaryCurrency] : [baseCurrency];

  static const List<ExpenseCategorySeed> defaultExpenseCategories = [
    ExpenseCategorySeed(name: 'Groceries', emoji: '??'),
    ExpenseCategorySeed(name: 'Vegetables', emoji: '??'),
    ExpenseCategorySeed(name: 'Fruits', emoji: '??'),
    ExpenseCategorySeed(name: 'Milk', emoji: '??'),
    ExpenseCategorySeed(name: 'Alcohol', emoji: '??'),
    ExpenseCategorySeed(name: 'Rent', emoji: '??'),
    ExpenseCategorySeed(name: 'Tuition', emoji: '??'),
    ExpenseCategorySeed(name: 'Utilities', emoji: '??'),
    ExpenseCategorySeed(name: 'Fuel', emoji: '?'),
    ExpenseCategorySeed(name: 'Healthcare', emoji: '??'),
    ExpenseCategorySeed(name: 'Dining Out', emoji: '???'),
    ExpenseCategorySeed(name: 'Entertainment', emoji: '??'),
    ExpenseCategorySeed(name: 'Travel', emoji: '??'),
    ExpenseCategorySeed(name: 'Gadgets', emoji: '??'),
    ExpenseCategorySeed(name: 'Subscriptions', emoji: '??'),
    ExpenseCategorySeed(name: 'Savings', emoji: '??'),
    ExpenseCategorySeed(name: 'Card Payment', emoji: '??'),
  ];
}

class ExpenseCategorySeed {
  const ExpenseCategorySeed({required this.name, required this.emoji});

  final String name;
  final String emoji;
}
