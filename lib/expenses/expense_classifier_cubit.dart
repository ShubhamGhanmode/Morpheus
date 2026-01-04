import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/expenses/models/category_prediction.dart';
import 'package:morpheus/expenses/services/expense_classifier_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

class ExpenseClassifierState extends Equatable {
  const ExpenseClassifierState({
    this.predictions = const [],
    this.loading = false,
    this.error,
    this.needsMoreData = false,
    this.totalDocs,
  });

  final List<CategoryPrediction> predictions;
  final bool loading;
  final String? error;
  final bool needsMoreData;
  final int? totalDocs;

  ExpenseClassifierState copyWith({
    List<CategoryPrediction>? predictions,
    bool? loading,
    String? error,
    bool? needsMoreData,
    int? totalDocs,
  }) {
    return ExpenseClassifierState(
      predictions: predictions ?? this.predictions,
      loading: loading ?? this.loading,
      error: error,
      needsMoreData: needsMoreData ?? this.needsMoreData,
      totalDocs: totalDocs ?? this.totalDocs,
    );
  }

  @override
  List<Object?> get props =>
      [predictions, loading, error, needsMoreData, totalDocs];
}

class ExpenseClassifierCubit extends Cubit<ExpenseClassifierState> {
  ExpenseClassifierCubit({ExpenseClassifierService? service})
      : _service = service ?? ExpenseClassifierService(),
        super(const ExpenseClassifierState());

  final ExpenseClassifierService _service;

  /// Debounce timer for prediction requests
  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(milliseconds: 400);

  /// Last title that was predicted to avoid duplicates
  String? _lastPredictedTitle;

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  /// Predict category for a title with debouncing
  void predict(String title) {
    final trimmed = title.trim();

    // Cancel any pending prediction
    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      _lastPredictedTitle = null;
      emit(const ExpenseClassifierState());
      return;
    }

    // Skip if same title was already predicted
    if (trimmed.toLowerCase() == _lastPredictedTitle?.toLowerCase() &&
        state.predictions.isNotEmpty) {
      return;
    }

    // Show loading state immediately
    emit(state.copyWith(loading: true, error: null));

    // Debounce the actual API call
    _debounceTimer = Timer(_debounceDuration, () {
      _performPrediction(trimmed);
    });
  }

  /// Predict immediately without debouncing (for blur events)
  Future<void> predictImmediate(String title) async {
    _debounceTimer?.cancel();
    final trimmed = title.trim();

    if (trimmed.isEmpty) {
      _lastPredictedTitle = null;
      emit(const ExpenseClassifierState());
      return;
    }

    if (trimmed.toLowerCase() == _lastPredictedTitle?.toLowerCase() &&
        state.predictions.isNotEmpty) {
      return;
    }

    await _performPrediction(trimmed);
  }

  Future<void> _performPrediction(String title) async {
    if (isClosed) return;

    emit(state.copyWith(loading: true, error: null));

    try {
      final result = await _service.predictCategoriesWithMeta(title);
      if (isClosed) return;

      _lastPredictedTitle = title;

      emit(state.copyWith(
        loading: false,
        predictions: result.predictions,
        needsMoreData: result.needsMoreData,
        totalDocs: result.totalDocs,
      ));
    } catch (e, stack) {
      if (isClosed) return;

      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Predict expense category failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Predict category'),
        ),
      );
    }
  }

  /// Clear predictions and reset state
  void clear() {
    _debounceTimer?.cancel();
    _lastPredictedTitle = null;
    emit(const ExpenseClassifierState());
  }

  /// Clear the service cache (useful after adding new expenses)
  void clearCache() {
    _service.clearCache();
  }
}
