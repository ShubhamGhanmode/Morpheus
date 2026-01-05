class AppConfig {
  static const String baseCurrency = 'EUR';
  static const String secondaryCurrency = 'INR';
  static const bool enableSecondaryCurrency = true;
  static const bool enableReceiptScanning = false;
  static const ReceiptOcrProvider defaultReceiptOcrProvider = ReceiptOcrProvider.documentAi;

  static List<String> get supportedCurrencies => enableSecondaryCurrency ? [baseCurrency, secondaryCurrency] : [baseCurrency];

  static const List<ExpenseCategorySeed> defaultExpenseCategories = [
    ExpenseCategorySeed(name: 'Groceries', emoji: '🛒'),
    ExpenseCategorySeed(name: 'Alcohol', emoji: '🍺'),
    ExpenseCategorySeed(name: 'Rent', emoji: '🏠'),
    ExpenseCategorySeed(name: 'Tuition', emoji: '🎓'),
    ExpenseCategorySeed(name: 'Utilities', emoji: '💡'),
    ExpenseCategorySeed(name: 'Fuel', emoji: '⛽'),
    ExpenseCategorySeed(name: 'Healthcare', emoji: '🏥'),
    ExpenseCategorySeed(name: 'Dining Out', emoji: '🍽️'),
    ExpenseCategorySeed(name: 'Entertainment', emoji: '🎬'),
    ExpenseCategorySeed(name: 'Travel', emoji: '✈️'),
    ExpenseCategorySeed(name: 'Gadgets', emoji: '📱'),
    ExpenseCategorySeed(name: 'Subscriptions', emoji: '🔁'),
    ExpenseCategorySeed(name: 'Savings', emoji: '💰'),
    ExpenseCategorySeed(name: 'Card Payment', emoji: '💳'),
  ];
}

class ExpenseCategorySeed {
  const ExpenseCategorySeed({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

enum ReceiptOcrProvider { documentAi, vision }

extension ReceiptOcrProviderLabel on ReceiptOcrProvider {
  String get label {
    switch (this) {
      case ReceiptOcrProvider.documentAi:
        return 'Document AI';
      case ReceiptOcrProvider.vision:
        return 'Cloud Vision';
    }
  }
}
