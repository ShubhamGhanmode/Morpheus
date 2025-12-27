import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/banks/bank_repository.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

class BankSearchState {
  final String query;
  final List<String> suggestions;
  final bool loading;
  final String? error;

  const BankSearchState({
    this.query = '',
    this.suggestions = const [],
    this.loading = false,
    this.error,
  });

  BankSearchState copyWith({
    String? query,
    List<String>? suggestions,
    bool? loading,
    String? error,
  }) {
    return BankSearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

/// Debounced, tiny-footprint bank lookup to keep the dropdown snappy.
class BankSearchCubit extends Cubit<BankSearchState> {
  BankSearchCubit(this._repository) : super(const BankSearchState());

  final BankRepository _repository;
  Timer? _debounce;

  Future<void> preload() async {
    await search('');
  }

  Future<void> search(String query) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 180), () async {
      emit(state.copyWith(query: query, loading: true, error: null));
      try {
        final banks = await _repository.searchBanks(query);
        emit(
          state.copyWith(
            suggestions: banks,
            loading: false,
            error: banks.isEmpty && query.isNotEmpty ? 'No matches' : null,
          ),
        );
      } catch (e, stack) {
        await ErrorReporter.recordError(
          e,
          stack,
          reason: 'Bank search failed',
        );
        emit(
          state.copyWith(
            loading: false,
            error: errorMessage(e, action: 'Search banks'),
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
