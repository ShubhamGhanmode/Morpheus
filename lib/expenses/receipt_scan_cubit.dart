import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/constants/category_rule_suggestions.dart';
import 'package:morpheus/expenses/models/receipt_line_item.dart';
import 'package:morpheus/expenses/models/receipt_scan_result.dart';
import 'package:morpheus/expenses/services/expense_classifier_service.dart';
import 'package:morpheus/expenses/services/receipt_scan_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

enum ReceiptScanStatus { idle, scanning, ready, error }

class ReceiptScanState extends Equatable {
  const ReceiptScanState({
    this.status = ReceiptScanStatus.idle,
    this.items = const [],
    this.currency,
    this.merchant,
    this.receiptDate,
    this.total,
    this.subtotal,
    this.tax,
    this.error,
    this.category,
    this.imagePath,
    this.imageBytes,
    this.mimeType,
    this.receiptImageUri,
    this.suggestedCategories = const [],
    this.suggestionLoading = false,
    this.ruleBasedApplied = false,
  });

  final ReceiptScanStatus status;
  final List<ReceiptLineItem> items;
  final String? currency;
  final String? merchant;
  final DateTime? receiptDate;
  final double? total;
  final double? subtotal;
  final double? tax;
  final String? error;
  final String? category;
  final String? imagePath;
  final Uint8List? imageBytes;
  final String? mimeType;
  final String? receiptImageUri;
  final List<String> suggestedCategories;
  final bool suggestionLoading;
  final bool ruleBasedApplied;

  ReceiptScanState copyWith({
    ReceiptScanStatus? status,
    List<ReceiptLineItem>? items,
    String? currency,
    String? merchant,
    DateTime? receiptDate,
    double? total,
    double? subtotal,
    double? tax,
    String? error,
    String? category,
    String? imagePath,
    Uint8List? imageBytes,
    String? mimeType,
    String? receiptImageUri,
    List<String>? suggestedCategories,
    bool? suggestionLoading,
    bool? ruleBasedApplied,
  }) {
    return ReceiptScanState(
      status: status ?? this.status,
      items: items ?? this.items,
      currency: currency ?? this.currency,
      merchant: merchant ?? this.merchant,
      receiptDate: receiptDate ?? this.receiptDate,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      error: error,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      mimeType: mimeType ?? this.mimeType,
      receiptImageUri: receiptImageUri ?? this.receiptImageUri,
      suggestedCategories: suggestedCategories ?? this.suggestedCategories,
      suggestionLoading: suggestionLoading ?? this.suggestionLoading,
      ruleBasedApplied: ruleBasedApplied ?? this.ruleBasedApplied,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        currency,
        merchant,
        receiptDate,
        total,
        subtotal,
        tax,
        error,
        category,
        imagePath,
        imageBytes,
        mimeType,
        receiptImageUri,
        suggestedCategories,
        suggestionLoading,
        ruleBasedApplied,
      ];
}

class ReceiptScanCubit extends Cubit<ReceiptScanState> {
  ReceiptScanCubit({
    ReceiptScanService? service,
    ExpenseClassifierService? classifierService,
    required String defaultCurrency,
    ReceiptOcrProvider? ocrProvider,
    String? defaultCategory,
  })  : _service = service ?? ReceiptScanService(),
        _classifier = classifierService ?? ExpenseClassifierService(),
        _provider = ocrProvider ?? AppConfig.defaultReceiptOcrProvider,
        super(
          ReceiptScanState(
            currency: defaultCurrency,
            category: defaultCategory,
          ),
        );

  final ReceiptScanService _service;
  final ExpenseClassifierService _classifier;
  final ReceiptOcrProvider _provider;

  void setCategory(String? category) {
    if (category == null || category.isEmpty) return;
    emit(state.copyWith(category: category));
  }

  void setMerchant(String? merchant) {
    emit(state.copyWith(merchant: merchant));
  }

  void setCurrency(String? currency) {
    if (currency == null || currency.isEmpty) return;
    emit(state.copyWith(currency: currency));
  }

  void updateItemName(String id, String name) {
    final updated = state.items
        .map((item) => item.id == id ? item.copyWith(name: name) : item)
        .toList();
    emit(state.copyWith(items: updated));
  }

  void updateItemAmount(String id, String amountText) {
    final updated = state.items
        .map((item) => item.id == id ? item.copyWith(amountText: amountText) : item)
        .toList();
    emit(state.copyWith(items: updated));
  }

  void setItemCategory(String id, String category) {
    final updated = state.items
        .map((item) => item.id == id ? item.copyWith(category: category) : item)
        .toList();
    emit(state.copyWith(items: updated));
  }

  void addEmptyItem() {
    final updated = [
      ...state.items,
      ReceiptLineItem(name: '', amountText: ''),
    ];
    emit(state.copyWith(items: updated));
  }

  void removeItem(String id) {
    final updated = state.items.where((item) => item.id != id).toList();
    emit(state.copyWith(items: updated));
  }

  Future<void> scanReceipt({
    required Uint8List bytes,
    String? mimeType,
    String? imagePath,
  }) async {
    emit(
      ReceiptScanState(
        status: ReceiptScanStatus.scanning,
        currency: state.currency,
        category: state.category,
        imageBytes: bytes,
        mimeType: mimeType,
        imagePath: imagePath,
        ruleBasedApplied: false,
      ),
    );
    try {
      final result = await _service.scanReceipt(
        bytes: bytes,
        mimeType: mimeType,
        provider: _provider,
      );
      emit(
        state.copyWith(
          status: ReceiptScanStatus.ready,
          items: result.items,
          currency: result.currency ?? state.currency,
          merchant: result.merchant,
          receiptDate: result.date,
          total: result.total,
          subtotal: result.subtotal,
          tax: result.tax,
          receiptImageUri: result.receiptImageUri,
          imagePath: imagePath ?? state.imagePath,
          error: null,
          ruleBasedApplied: false,
        ),
      );
      // Global category suggestions removed; per-item rules handle suggestions.
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Receipt scan failed',
      );
      emit(
        state.copyWith(
          status: ReceiptScanStatus.error,
          error: errorMessage(e, action: 'Scan receipt'),
        ),
      );
    }
  }

  Future<void> retryScan() async {
    final bytes = state.imageBytes;
    if (bytes == null) return;
    await scanReceipt(
      bytes: bytes,
      mimeType: state.mimeType,
      imagePath: state.imagePath,
    );
  }

  void applyRuleBasedCategories(List<ExpenseCategory> categories) {
    if (state.ruleBasedApplied || categories.isEmpty) return;
    if (state.items.isEmpty) {
      emit(state.copyWith(ruleBasedApplied: true));
      return;
    }

    final fallbackCategory =
        state.category ?? (categories.isNotEmpty ? categories.first.name : null);
    final updated = state.items.map((item) {
      if (item.category != null && item.category!.isNotEmpty) {
        return item;
      }
      final suggestions = ruleBasedCategorySuggestions(
        title: item.name,
        categories: categories,
        limit: 1,
      );
      if (suggestions.isNotEmpty) {
        return item.copyWith(category: suggestions.first);
      }
      if (fallbackCategory != null && fallbackCategory.isNotEmpty) {
        return item.copyWith(category: fallbackCategory);
      }
      return item;
    }).toList();

    emit(state.copyWith(items: updated, ruleBasedApplied: true));
  }

  Future<void> _loadSuggestions(ReceiptScanResult result) async {
    final text = _buildSuggestionText(result);
    if (text.isEmpty || isClosed) return;
    emit(state.copyWith(suggestionLoading: true));
    try {
      final prediction = await _classifier.predictCategoriesWithMeta(text);
      if (isClosed) return;
      final suggestions = prediction.predictions
          .map((item) => item.category)
          .where((category) => category.isNotEmpty)
          .toList();
      emit(
        state.copyWith(
          suggestedCategories: suggestions,
          suggestionLoading: false,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(suggestionLoading: false));
    }
  }

  String _buildSuggestionText(ReceiptScanResult result) {
    final parts = <String>[];
    if (result.merchant != null && result.merchant!.trim().isNotEmpty) {
      parts.add(result.merchant!.trim());
    }
    for (final item in result.items) {
      final name = item.name.trim();
      if (name.isNotEmpty) {
        parts.add(name);
      }
      if (parts.length >= 5) break;
    }
    return parts.join(' ');
  }

  void reset() {
    emit(
      ReceiptScanState(
        currency: state.currency,
        category: state.category,
      ),
    );
  }
}
