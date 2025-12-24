import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class Expense extends Equatable {
  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.note,
    this.amountEur,
    this.budgetCurrency,
    this.budgetRate,
    this.amountInBudgetCurrency,
    this.paymentSourceType = 'cash',
    this.paymentSourceId,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String title;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String? note;
  final double? amountEur;
  final String? budgetCurrency;
  final double? budgetRate;
  final double? amountInBudgetCurrency;
  final String paymentSourceType;
  final String? paymentSourceId;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    String? note,
    double? amountEur,
    String? budgetCurrency,
    double? budgetRate,
    double? amountInBudgetCurrency,
    String? paymentSourceType,
    String? paymentSourceId,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      amountEur: amountEur ?? this.amountEur,
      budgetCurrency: budgetCurrency ?? this.budgetCurrency,
      budgetRate: budgetRate ?? this.budgetRate,
      amountInBudgetCurrency:
          amountInBudgetCurrency ?? this.amountInBudgetCurrency,
      paymentSourceType: paymentSourceType ?? this.paymentSourceType,
      paymentSourceId: paymentSourceId ?? this.paymentSourceId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'currency': currency,
    'category': category,
    'date': date.millisecondsSinceEpoch,
    'note': note,
    'amountEur': amountEur,
    'budgetCurrency': budgetCurrency,
    'budgetRate': budgetRate,
    'amountInBudgetCurrency': amountInBudgetCurrency,
    'paymentSourceType': paymentSourceType,
    'paymentSourceId': paymentSourceId,
  };

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: (map['id'] ?? '').toString(),
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      category: map['category'] as String,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      amountEur: (map['amountEur'] as num?)?.toDouble(),
      budgetCurrency: map['budgetCurrency'] as String?,
      budgetRate: (map['budgetRate'] as num?)?.toDouble(),
      amountInBudgetCurrency: (map['amountInBudgetCurrency'] as num?)
          ?.toDouble(),
      paymentSourceType:
          (map['paymentSourceType'] as String?)?.toLowerCase() ?? 'cash',
      paymentSourceId: map['paymentSourceId'] as String?,
    );
  }

  double amountForCurrency(String targetCurrency) {
    if (targetCurrency == currency) return amount;
    if (targetCurrency == 'EUR' && amountEur != null) return amountEur!;
    if (budgetCurrency != null && budgetCurrency == targetCurrency) {
      if (amountInBudgetCurrency != null) return amountInBudgetCurrency!;
      if (budgetRate != null) return amount * budgetRate!;
    }
    return amount;
  }

  @override
  List<Object?> get props => [
    id,
    title,
    amount,
    currency,
    category,
    date,
    note,
    amountEur,
    budgetCurrency,
    budgetRate,
    amountInBudgetCurrency,
    paymentSourceType,
    paymentSourceId,
  ];
}
