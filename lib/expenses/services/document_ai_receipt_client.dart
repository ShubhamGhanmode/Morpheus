import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:morpheus/expenses/models/receipt_line_item.dart';
import 'package:morpheus/expenses/models/receipt_scan_result.dart';

class DocumentAiResponseParser {
  DocumentAiResponseParser({
    Set<String>? lineItemTypes,
    Set<String>? lineItemDescriptionTypes,
    Set<String>? lineItemAmountTypes,
    Set<String>? totalTypes,
    Set<String>? subtotalTypes,
    Set<String>? taxTypes,
    Set<String>? merchantTypes,
    Set<String>? dateTypes,
  })  : _lineItemTypes = _lowerSet(lineItemTypes ?? const {
          'line_item',
          'lineitem',
        }),
        _lineItemDescriptionTypes = _lowerSet(
          lineItemDescriptionTypes ??
              const {
                'description',
                'item',
                'item_description',
                'product',
                'product_description',
                'line_item_description',
              },
        ),
        _lineItemAmountTypes = _lowerSet(
          lineItemAmountTypes ??
              const {
                'amount',
                'total_amount',
                'line_item_amount',
                'price',
                'unit_price',
                'unit_price_amount',
              },
        ),
        _totalTypes = _lowerSet(totalTypes ?? const {
          'total_amount',
          'total',
          'grand_total',
          'amount_due',
        }),
        _subtotalTypes = _lowerSet(subtotalTypes ?? const {
          'subtotal',
          'subtotal_amount',
        }),
        _taxTypes = _lowerSet(taxTypes ?? const {
          'tax',
          'tax_amount',
          'vat',
        }),
        _merchantTypes = _lowerSet(merchantTypes ?? const {
          'supplier_name',
          'merchant_name',
          'vendor_name',
          'supplier',
        }),
        _dateTypes = _lowerSet(dateTypes ?? const {
          'purchase_date',
          'receipt_date',
          'transaction_date',
          'purchase_time',
          'invoice_date',
        });

  final Set<String> _lineItemTypes;
  final Set<String> _lineItemDescriptionTypes;
  final Set<String> _lineItemAmountTypes;
  final Set<String> _totalTypes;
  final Set<String> _subtotalTypes;
  final Set<String> _taxTypes;
  final Set<String> _merchantTypes;
  final Set<String> _dateTypes;

  ReceiptScanResult parse(Map<String, dynamic> response) {
    final document = _mapFrom(response['document']);
    final entities = _listOfMap(document['entities']);
    final rawText = document['text']?.toString();
    final scanMeta = _mapFrom(response['scanMeta']);
    final receiptImageUri = scanMeta['imageUri']?.toString() ??
        scanMeta['imagePath']?.toString();

    final lineItems = _parseLineItems(entities);
    final total = _findMoneyAmount(entities, _totalTypes);
    final subtotal = _findMoneyAmount(entities, _subtotalTypes);
    final tax = _findMoneyAmount(entities, _taxTypes);
    final merchant = _findTextValue(entities, _merchantTypes);
    final date = _findDateValue(entities, _dateTypes);
    final currency = _findCurrency(entities);

    return ReceiptScanResult(
      items: lineItems,
      total: total,
      subtotal: subtotal,
      tax: tax,
      currency: currency,
      merchant: merchant,
      rawText: rawText,
      date: date,
      receiptImageUri: receiptImageUri,
    );
  }

  List<ReceiptLineItem> _parseLineItems(List<Map<String, dynamic>> entities) {
    final items = <ReceiptLineItem>[];
    for (final entity in entities) {
      final type = _normalizeType(entity['type']);
      if (!_lineItemTypes.contains(type)) continue;
      final properties = _listOfMap(entity['properties']);
      final description =
          _findTextValue(properties, _lineItemDescriptionTypes) ??
              entity['mentionText']?.toString();
      final money = _findMoney(properties, _lineItemAmountTypes) ??
          _moneyFromEntity(entity);
      final amountText = money?.amount != null
          ? money!.amount!.toStringAsFixed(2)
          : '';
      items.add(
        ReceiptLineItem(
          name: (description ?? '').trim(),
          amountText: amountText,
        ),
      );
    }
    return items;
  }

  double? _findMoneyAmount(
    List<Map<String, dynamic>> entities,
    Set<String> types,
  ) {
    final money = _findMoney(entities, types);
    return money?.amount;
  }

  String? _findCurrency(List<Map<String, dynamic>> entities) {
    final money = _findMoney(entities, _totalTypes) ??
        _findMoney(entities, _subtotalTypes) ??
        _findMoney(entities, _taxTypes);
    return money?.currency;
  }

  String? _findTextValue(
    List<Map<String, dynamic>> entities,
    Set<String> types,
  ) {
    for (final entity in entities) {
      final type = _normalizeType(entity['type']);
      if (!types.contains(type)) continue;
      final text = _textFromEntity(entity);
      if (text != null && text.trim().isNotEmpty) return text.trim();
    }
    return null;
  }

  DateTime? _findDateValue(
    List<Map<String, dynamic>> entities,
    Set<String> types,
  ) {
    for (final entity in entities) {
      final type = _normalizeType(entity['type']);
      if (!types.contains(type)) continue;
      final date = _dateFromEntity(entity);
      if (date != null) return date;
    }
    return null;
  }

  _MoneyValue? _findMoney(
    List<Map<String, dynamic>> entities,
    Set<String> types,
  ) {
    for (final entity in entities) {
      final type = _normalizeType(entity['type']);
      if (!types.contains(type)) continue;
      final money = _moneyFromEntity(entity);
      if (money != null) return money;
    }
    return null;
  }

  _MoneyValue? _moneyFromEntity(Map<String, dynamic> entity) {
    final normalized = _mapFrom(entity['normalizedValue']);
    if (normalized.isNotEmpty) {
      final moneyValue = _mapFrom(normalized['moneyValue']);
      if (moneyValue.isNotEmpty) {
        final units = moneyValue['units'];
        final nanos = moneyValue['nanos'];
        final currency = moneyValue['currencyCode']?.toString();
        final amount =
            _moneyAmount(units: units, nanos: nanos, text: null);
        if (amount != null) {
          return _MoneyValue(amount: amount, currency: currency);
        }
      }
      final text = normalized['text']?.toString();
      final amount = _parseAmount(text);
      if (amount != null) {
        return _MoneyValue(amount: amount, currency: null);
      }
    }

    final mention = entity['mentionText']?.toString();
    final amount = _parseAmount(mention);
    if (amount != null) {
      return _MoneyValue(amount: amount, currency: null);
    }
    return null;
  }

  DateTime? _dateFromEntity(Map<String, dynamic> entity) {
    final normalized = _mapFrom(entity['normalizedValue']);
    if (normalized.isNotEmpty) {
      final dateValue = _mapFrom(normalized['dateValue']);
      if (dateValue.isNotEmpty) {
        final year = _toInt(dateValue['year']);
        final month = _toInt(dateValue['month']);
        final day = _toInt(dateValue['day']);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
      final datetimeValue = normalized['datetimeValue']?.toString();
      if (datetimeValue != null) {
        return DateTime.tryParse(datetimeValue);
      }
      final text = normalized['text']?.toString();
      if (text != null) {
        return DateTime.tryParse(text);
      }
    }
    final mention = entity['mentionText']?.toString();
    if (mention != null) {
      return DateTime.tryParse(mention);
    }
    return null;
  }

  String? _textFromEntity(Map<String, dynamic> entity) {
    final normalized = _mapFrom(entity['normalizedValue']);
    if (normalized.isNotEmpty && normalized['text'] != null) {
      return normalized['text']?.toString();
    }
    return entity['mentionText']?.toString();
  }

  double? _moneyAmount({Object? units, Object? nanos, String? text}) {
    final parsedUnits = _toInt(units);
    final parsedNanos = _toInt(nanos);
    if (parsedUnits != null) {
      final nanosValue = parsedNanos ?? 0;
      return parsedUnits + (nanosValue / 1000000000);
    }
    if (text != null) return _parseAmount(text);
    return null;
  }

  double? _parseAmount(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final cleaned = trimmed.replaceAll(RegExp(r'[^0-9,.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(_normalizeDecimal(cleaned));
  }

  String _normalizeDecimal(String value) {
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

  List<Map<String, dynamic>> _listOfMap(Object? value) {
    if (value is List) {
      return value.whereType<Map>().map(_mapFrom).toList();
    }
    return const [];
  }

  Map<String, dynamic> _mapFrom(Object? value) {
    if (value is Map) {
      return value.map(
        (key, entry) => MapEntry(key.toString(), entry),
      );
    }
    return const {};
  }

  String _normalizeType(Object? value) {
    final raw = (value?.toString() ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    final lastSegment = raw.contains('/') ? raw.split('/').last : raw;
    final normalized = lastSegment.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return normalized.replaceAll(RegExp(r'^_+|_+$'), '');
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static Set<String> _lowerSet(Set<String> input) {
    return input.map((value) => value.toLowerCase()).toSet();
  }
}

class DocumentAiReceiptClient {
  DocumentAiReceiptClient({
    FirebaseFunctions? functions,
    DocumentAiResponseParser? responseParser,
  })  : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1'),
        _responseParser = responseParser ?? DocumentAiResponseParser();

  final FirebaseFunctions _functions;
  final DocumentAiResponseParser _responseParser;

  Future<ReceiptScanResult> scanReceipt({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final base64Image = base64Encode(bytes);
    final callable = _functions.httpsCallable('scanReceiptDocumentAi');
    final result = await callable.call(<String, dynamic>{
      'imageBase64': base64Image,
      'mimeType': mimeType,
    });

    if (result.data is! Map) {
      throw StateError('Invalid Document AI response.');
    }

    return _responseParser.parse(
      Map<String, dynamic>.from(result.data as Map),
    );
  }
}

class _MoneyValue {
  const _MoneyValue({this.amount, this.currency});

  final double? amount;
  final String? currency;
}
