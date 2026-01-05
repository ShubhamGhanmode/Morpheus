import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:morpheus/config/app_config.dart';

part 'expense_category.freezed.dart';
part 'expense_category.g.dart';

@freezed
abstract class ExpenseCategory with _$ExpenseCategory {
  const ExpenseCategory._();

  factory ExpenseCategory({required String id, required String name, @Default('') String emoji}) = _ExpenseCategory;

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => _$ExpenseCategoryFromJson(json);

  String get label {
    final trimmed = emoji.trim();
    final resolved = _resolveEmoji(trimmed, name);
    return resolved.isEmpty ? name : '$resolved $name';
  }

  /// Returns the emoji, resolving placeholder characters to defaults.
  String get resolvedEmoji {
    final trimmed = emoji.trim();
    return _resolveEmoji(trimmed, name);
  }

  String _resolveEmoji(String value, String name) {
    if (!_isPlaceholderEmoji(value)) {
      return value;
    }
    final seed = AppConfig.defaultExpenseCategories.firstWhere(
      (entry) => entry.name.toLowerCase() == name.toLowerCase(),
      orElse: () => const ExpenseCategorySeed(name: '', emoji: ''),
    );
    return seed.emoji;
  }

  bool _isPlaceholderEmoji(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return true;
    return trimmed.runes.every((r) => r == 0x3F || r == 0xFFFD);
  }
}
