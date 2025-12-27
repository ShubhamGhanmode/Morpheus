import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/utils/error_mapper.dart';

class AccountsState extends Equatable {
  const AccountsState({
    this.loading = false,
    this.items = const [],
    this.error,
  });

  final bool loading;
  final List<AccountCredential> items;
  final String? error;

  AccountsState copyWith({
    bool? loading,
    List<AccountCredential>? items,
    String? error,
  }) {
    return AccountsState(
      loading: loading ?? this.loading,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, items, error];
}

class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit(this._repository) : super(const AccountsState());

  final AccountsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repository.fetchAccounts();
      emit(state.copyWith(loading: false, items: items));
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Load accounts failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Load accounts'),
        ),
      );
    }
  }

  Future<void> save(AccountCredential account) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.saveAccount(account);
      final updated = [
        account,
        ...state.items.where((a) => a.id != account.id),
      ];
      emit(state.copyWith(loading: false, items: updated));
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Save account failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Save account'),
        ),
      );
    }
  }

  Future<void> delete(String id) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.deleteAccount(id);
      emit(
        state.copyWith(
          loading: false,
          items: state.items.where((a) => a.id != id).toList(),
        ),
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Delete account failed',
      );
      emit(
        state.copyWith(
          loading: false,
          error: errorMessage(e, action: 'Delete account'),
        ),
      );
    }
  }
}
