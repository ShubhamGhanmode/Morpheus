import 'package:morpheus/expenses/models/receipt_line_item.dart';

class ReceiptScanResult {
  ReceiptScanResult({
    required this.items,
    this.total,
    this.subtotal,
    this.tax,
    this.currency,
    this.merchant,
    this.rawText,
    this.date,
    this.receiptImageUri,
  });

  final List<ReceiptLineItem> items;
  final double? total;
  final double? subtotal;
  final double? tax;
  final String? currency;
  final String? merchant;
  final String? rawText;
  final DateTime? date;
  final String? receiptImageUri;

  factory ReceiptScanResult.fromMap(Map<String, dynamic> map) {
    final items = <ReceiptLineItem>[];
    final rawItems = map['items'];
    if (rawItems is List) {
      for (final entry in rawItems.whereType<Map>()) {
        items.add(ReceiptLineItem.fromMap(Map<String, dynamic>.from(entry)));
      }
    }

    double? parseNum(Object? value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    DateTime? parseDate(Object? value) {
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    final scanMeta = map['scanMeta'];
    String? receiptImageUri;
    if (scanMeta is Map) {
      receiptImageUri =
          scanMeta['imageUri']?.toString() ?? scanMeta['imagePath']?.toString();
    }

    return ReceiptScanResult(
      items: items,
      total: parseNum(map['total']),
      subtotal: parseNum(map['subtotal']),
      tax: parseNum(map['tax']),
      currency: map['currency']?.toString(),
      merchant: map['merchant']?.toString(),
      rawText: map['rawText']?.toString(),
      date: parseDate(map['date']),
      receiptImageUri: receiptImageUri,
    );
  }
}
