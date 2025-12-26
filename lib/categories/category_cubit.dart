import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/categories/category_repository.dart';
import 'package:morpheus/categories/expense_category.dart';

class CategoryState extends Equatable {
  const CategoryState({
    this.items = const [],
    this.loading = false,
    this.error,
  });

  final List<ExpenseCategory> items;
  final bool loading;
  final String? error;

  CategoryState copyWith({
    List<ExpenseCategory>? items,
    bool? loading,
    String? error,
  }) {
    return CategoryState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [items, loading, error];
}

class CategoryCubit extends Cubit<CategoryState> {
  CategoryCubit(this._repository) : super(const CategoryState());

  final CategoryRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repository.fetchCategories();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addDefaultCategories() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addDefaultCategories();
      final items = await _repository.fetchCategories();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> addCategory({required String name, required String emoji}) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      await _repository.addCategory(name: name, emoji: emoji);
      final items = await _repository.fetchCategories();
      emit(state.copyWith(loading: false, items: items));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
