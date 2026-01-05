import 'package:uuid/uuid.dart';

class ReceiptLineItem {
  ReceiptLineItem({
    String? id,
    required this.name,
    required this.amountText,
    this.category,
  }) : id = id ?? const Uuid().v4();

  final String id;
  final String name;
  final String amountText;
  final String? category;

  double? get amount => parseAmount(amountText);

  ReceiptLineItem copyWith({
    String? name,
    String? amountText,
    String? category,
  }) {
    return ReceiptLineItem(
      id: id,
      name: name ?? this.name,
      amountText: amountText ?? this.amountText,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amountText': amountText,
      'category': category,
    };
  }

  factory ReceiptLineItem.fromMap(Map<String, dynamic> map) {
    final name = (map['name'] ?? map['description'] ?? '').toString().trim();
    final amount = map['amount'];
    final amountText = amount is num
        ? amount.toStringAsFixed(2)
        : (map['amountText'] ?? '').toString().trim();
    return ReceiptLineItem(
      id: map['id']?.toString(),
      name: name,
      amountText: amountText,
      category: map['category']?.toString(),
    );
  }

  static double? parseAmount(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final sanitized = trimmed.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (sanitized.isEmpty) return null;
    final normalized = _normalizeDecimal(sanitized);
    return double.tryParse(normalized);
  }

  static String _normalizeDecimal(String value) {
    if (value.contains(',') && value.contains('.')) {
      final lastComma = value.lastIndexOf(',');
      final lastDot = value.lastIndexOf('.');
      final decimalSep = lastComma > lastDot ? ',' : '.';
      final thousandSep = decimalSep == ',' ? '.' : ',';
      final noThousands = value.replaceAll(thousandSep, '');
      return decimalSep == ',' ? noThousands.replaceFirst(',', '.') : noThousands;
    }

    if (value.contains(',')) {
      final parts = value.split(',');
      final last = parts.last;
      if (last.length == 2) {
        return value.replaceFirst(',', '.');
      }
      return value.replaceAll(',', '');
    }

    if (value.contains('.')) {
      final parts = value.split('.');
      final last = parts.last;
      if (last.length == 2) {
        return value;
      }
      return value.replaceAll('.', '');
    }

    return value;
  }
}
