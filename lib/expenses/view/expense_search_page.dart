import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/payment_source_key.dart';
import 'package:morpheus/expenses/utils/expense_amounts.dart';

enum _QuickDateRange { all, month, last30, year }

class ExpenseSearchPage extends StatefulWidget {
  const ExpenseSearchPage({super.key});

  @override
  State<ExpenseSearchPage> createState() => _ExpenseSearchPageState();
}

class _ExpenseSearchPageState extends State<ExpenseSearchPage> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  String _query = '';
  _QuickDateRange _dateRange = _QuickDateRange.all;
  final Set<String> _sourceFilters = {};
  final Set<String> _transactionFilters = {};
  final Set<String> _categoryFilters = {};
  bool _notesOnly = false;
  List<_ExpenseSearchEntry> _searchIndex = const [];
  Map<String, String> _indexedCategoryLabels = const {};
  int _indexedExpenseSignature = 0;
  int _indexedCardSignature = 0;
  int _indexedAccountSignature = 0;
  String _indexedDisplayCurrency = '';
  double? _indexedBudgetToEur;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final value = _searchController.text.trim();
    if (value == _query) return;
    setState(() => _query = value);
  }

  bool _labelsMatch(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  int _signatureForExpenses(List<Expense> expenses) {
    var hash = 0;
    for (final expense in expenses) {
      hash = Object.hash(
        hash,
        expense.id,
        expense.title,
        expense.amount,
        expense.currency,
        expense.category,
        expense.date.millisecondsSinceEpoch,
        expense.note ?? '',
        expense.paymentSourceType,
        expense.paymentSourceId ?? '',
        expense.transactionType,
      );
    }
    return hash;
  }

  int _signatureForCards(List<CreditCard> cards) {
    var hash = 0;
    for (final card in cards) {
      hash = Object.hash(hash, card.id, card.bankName, card.cardNumber);
    }
    return hash;
  }

  int _signatureForAccounts(List<AccountCredential> accounts) {
    var hash = 0;
    for (final account in accounts) {
      hash = Object.hash(hash, account.id, account.bankName);
    }
    return hash;
  }

  void _syncSearchIndex({
    required Map<String, String> categoryLabels,
    required List<Expense> expenses,
    required String displayCurrency,
    required double? budgetToEur,
    required List<CreditCard> cards,
    required List<AccountCredential> accounts,
  }) {
    final sameLabels = _labelsMatch(_indexedCategoryLabels, categoryLabels);
    final sameDisplay = _indexedDisplayCurrency == displayCurrency && _indexedBudgetToEur == budgetToEur;

    final expenseSignature = _signatureForExpenses(expenses);
    final cardSignature = _signatureForCards(cards);
    final accountSignature = _signatureForAccounts(accounts);

    final sameData =
        sameLabels &&
        sameDisplay &&
        _indexedExpenseSignature == expenseSignature &&
        _indexedCardSignature == cardSignature &&
        _indexedAccountSignature == accountSignature;

    _indexedExpenseSignature = expenseSignature;
    _indexedCardSignature = cardSignature;
    _indexedAccountSignature = accountSignature;

    if (sameData) {
      return;
    }
    _searchIndex = _buildSearchIndex(
      categoryLabels: categoryLabels,
      expenses: expenses,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
      cards: cards,
      accounts: accounts,
    );
    _indexedDisplayCurrency = displayCurrency;
    _indexedBudgetToEur = budgetToEur;
  }

  List<_ExpenseSearchEntry> _buildSearchIndex({
    required Map<String, String> categoryLabels,
    required List<Expense> expenses,
    required String displayCurrency,
    required double? budgetToEur,
    required List<CreditCard> cards,
    required List<AccountCredential> accounts,
  }) {
    _indexedCategoryLabels = Map<String, String>.from(categoryLabels);
    return expenses.map((expense) {
      final normalizedTitle = _normalizeText(expense.title);
      final normalizedNote = _normalizeText(expense.note ?? '');
      final categoryLabel = _normalizeText(_categoryLabel(expense.category, categoryLabels));
      final sourceType = (expense.paymentSourceType.isNotEmpty ? expense.paymentSourceType : 'cash').toLowerCase();
      final sourceLabel = _normalizeText(_labelForSourceKey(_sourceKeyForExpense(expense), cards, accounts));
      final transactionType = _normalizeText(expense.transactionType);
      final currency = _normalizeText(expense.currency);
      final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
      final dateTokens = _dateTokens(expense.date);
      final searchText = [
        normalizedTitle,
        normalizedNote,
        _normalizeText(expense.category),
        categoryLabel,
        sourceLabel,
        sourceType,
        transactionType,
        currency,
        _normalizeText(expense.paymentSourceId ?? ''),
        ...dateTokens,
      ].where((value) => value.isNotEmpty).join(' ');
      final tokens = _tokenize(searchText);

      return _ExpenseSearchEntry(
        expense: expense,
        title: normalizedTitle,
        note: normalizedNote,
        category: expense.category,
        categoryLabel: categoryLabel,
        sourceType: sourceType,
        sourceLabel: sourceLabel,
        transactionType: transactionType,
        currency: currency,
        amount: amount,
        date: expense.date,
        searchText: searchText,
        tokens: tokens,
      );
    }).toList();
  }

  bool get _hasActiveFilters {
    return _dateRange != _QuickDateRange.all ||
        _sourceFilters.isNotEmpty ||
        _transactionFilters.isNotEmpty ||
        _categoryFilters.isNotEmpty ||
        _notesOnly;
  }

  int get _activeFilterCount {
    return (_dateRange == _QuickDateRange.all ? 0 : 1) +
        _sourceFilters.length +
        _transactionFilters.length +
        _categoryFilters.length +
        (_notesOnly ? 1 : 0);
  }

  DateTimeRange? _rangeForQuickDate(_QuickDateRange range) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    switch (range) {
      case _QuickDateRange.all:
        return null;
      case _QuickDateRange.month:
        final start = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: start, end: end);
      case _QuickDateRange.last30:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
        return DateTimeRange(start: start, end: end);
      case _QuickDateRange.year:
        final start = DateTime(now.year, 1, 1);
        return DateTimeRange(start: start, end: end);
    }
  }

  DateTime? _maxDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  DateTime? _minDate(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isBefore(b) ? a : b;
  }

  _ParsedExpenseQuery _parseQuery(String input, Map<String, String> categoryLabels) {
    final tokens = _splitQueryTokens(input);
    final terms = <String>[];
    final noteTerms = <String>[];
    final categoryFilters = <String>{};
    final sourceFilters = <String>{};
    final transactionFilters = <String>{};
    double? minAmount;
    double? maxAmount;
    DateTime? after;
    DateTime? before;
    var requiresNote = false;

    for (final raw in tokens) {
      final token = raw.trim();
      if (token.isEmpty) continue;
      final lower = token.toLowerCase();

      if (lower == 'has:note') {
        requiresNote = true;
        continue;
      }

      if (lower.startsWith('note:')) {
        final value = _stripQuotes(lower.substring('note:'.length));
        if (value.isNotEmpty) noteTerms.add(value);
        continue;
      }

      if (lower.startsWith('cat:') || lower.startsWith('category:')) {
        final value = lower.startsWith('cat:') ? lower.substring(4) : lower.substring(9);
        for (final part in value.split(',')) {
          final cleaned = _stripQuotes(part.trim());
          if (cleaned.isEmpty) continue;
          final match = _matchCategoryFilter(cleaned, categoryLabels);
          if (match != null) {
            categoryFilters.add(match);
          } else {
            terms.add(cleaned);
          }
        }
        continue;
      }

      if (lower.startsWith('src:') || lower.startsWith('source:') || lower.startsWith('pay:')) {
        final value = lower.startsWith('src:')
            ? lower.substring(4)
            : lower.startsWith('pay:')
            ? lower.substring(4)
            : lower.substring(7);
        for (final part in value.split(',')) {
          final cleaned = _stripQuotes(part.trim());
          if (cleaned.isEmpty) continue;
          final source = _sourceFilterForToken(cleaned);
          if (source != null) {
            sourceFilters.add(source);
          } else {
            terms.add(cleaned);
          }
        }
        continue;
      }

      if (lower.startsWith('type:') || lower.startsWith('tx:')) {
        final value = lower.startsWith('type:') ? lower.substring(5) : lower.substring(3);
        for (final part in value.split(',')) {
          final cleaned = _stripQuotes(part.trim());
          if (cleaned.isEmpty) continue;
          final type = _transactionFilterForToken(cleaned);
          if (type != null) {
            transactionFilters.add(type);
          } else {
            terms.add(cleaned);
          }
        }
        continue;
      }

      if (lower.startsWith('before:') || lower.startsWith('to:')) {
        final value = lower.startsWith('before:') ? lower.substring(7) : lower.substring(3);
        final range = _parseDateRange(value);
        if (range != null) before = range.end;
        continue;
      }

      if (lower.startsWith('after:') || lower.startsWith('from:')) {
        final value = lower.startsWith('after:') ? lower.substring(6) : lower.substring(5);
        final range = _parseDateRange(value);
        if (range != null) after = range.start;
        continue;
      }

      if (lower.startsWith('year:')) {
        final range = _parseDateRange(lower.substring(5));
        if (range != null) {
          after = range.start;
          before = range.end;
        }
        continue;
      }

      if (lower.startsWith('month:')) {
        final range = _parseMonthRange(lower.substring(6));
        if (range != null) {
          after = range.start;
          before = range.end;
        }
        continue;
      }

      if (lower.startsWith('min:')) {
        final value = _parseNumber(lower.substring(4));
        if (value != null) minAmount = value;
        continue;
      }

      if (lower.startsWith('max:')) {
        final value = _parseNumber(lower.substring(4));
        if (value != null) maxAmount = value;
        continue;
      }

      final rangeMatch = RegExp(r'^(>=|<=|>|<)(\d+(?:\.\d+)?)$').firstMatch(lower);
      if (rangeMatch != null) {
        final op = rangeMatch.group(1);
        final value = _parseNumber(rangeMatch.group(2) ?? '');
        if (value != null) {
          if (op == '>' || op == '>=') {
            minAmount = value;
          } else {
            maxAmount = value;
          }
        }
        continue;
      }

      final sourceAlias = _sourceFilterForToken(lower);
      if (sourceAlias != null) {
        sourceFilters.add(sourceAlias);
        continue;
      }

      final typeAlias = _transactionFilterForToken(lower);
      if (typeAlias != null) {
        transactionFilters.add(typeAlias);
        continue;
      }

      terms.add(_stripQuotes(lower));
    }

    return _ParsedExpenseQuery(
      terms: terms,
      noteTerms: noteTerms,
      categoryFilters: categoryFilters,
      sourceFilters: sourceFilters,
      transactionFilters: transactionFilters,
      minAmount: minAmount,
      maxAmount: maxAmount,
      after: after,
      before: before,
      requiresNote: requiresNote,
    );
  }

  List<_ExpenseSearchResult> _filterResults(_ParsedExpenseQuery query, DateTimeRange? quickRange) {
    final results = <_ExpenseSearchResult>[];
    final start = _maxDate(query.after, quickRange?.start);
    final end = _minDate(query.before, quickRange?.end);
    final requireNotes = _notesOnly || query.requiresNote;

    for (final entry in _searchIndex) {
      if (start != null && entry.date.isBefore(start)) continue;
      if (end != null && entry.date.isAfter(end)) continue;
      if (_categoryFilters.isNotEmpty && !_categoryFilters.contains(entry.category)) continue;
      if (query.categoryFilters.isNotEmpty && !query.categoryFilters.contains(entry.category)) continue;
      if (_sourceFilters.isNotEmpty && !_sourceFilters.contains(entry.sourceType)) continue;
      if (query.sourceFilters.isNotEmpty && !query.sourceFilters.contains(entry.sourceType)) continue;
      if (_transactionFilters.isNotEmpty && !_transactionFilters.contains(entry.transactionType)) continue;
      if (query.transactionFilters.isNotEmpty && !query.transactionFilters.contains(entry.transactionType)) continue;
      if (requireNotes && entry.note.isEmpty) continue;
      if (query.minAmount != null && entry.amount < query.minAmount!) continue;
      if (query.maxAmount != null && entry.amount > query.maxAmount!) continue;
      if (query.noteTerms.isNotEmpty && !_matchesAll(entry.note, query.noteTerms)) continue;

      var score = 0;
      if (query.terms.isNotEmpty) {
        score = _scoreEntry(entry, query.terms);
        if (score < 0) continue;
      }

      results.add(_ExpenseSearchResult(entry: entry, score: score));
    }

    if (query.terms.isNotEmpty) {
      results.sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        return b.entry.date.compareTo(a.entry.date);
      });
    } else {
      results.sort((a, b) => b.entry.date.compareTo(a.entry.date));
    }

    return results;
  }

  bool _matchesAll(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (!haystack.contains(needle)) return false;
    }
    return true;
  }

  int _scoreEntry(_ExpenseSearchEntry entry, List<String> terms) {
    var score = 0;
    for (final term in terms) {
      var matched = false;
      if (entry.title.contains(term)) {
        score += 6;
        if (entry.title.startsWith(term)) score += 2;
        matched = true;
      }
      if (entry.categoryLabel.contains(term) || entry.category.toLowerCase().contains(term)) {
        score += 4;
        matched = true;
      }
      if (entry.note.contains(term)) {
        score += 2;
        matched = true;
      }
      if (entry.sourceLabel.contains(term) || entry.sourceType.contains(term)) {
        score += 2;
        matched = true;
      }
      if (entry.searchText.contains(term)) {
        score += 1;
        matched = true;
      }
      if (entry.tokens.contains(term)) {
        score += 1;
        matched = true;
      }
      if (!matched) return -1;
    }
    return score;
  }

  List<String> _dateTokens(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return [
      year,
      '$year-$month',
      '$year-$month-$day',
      DateFormat.MMM().format(date).toLowerCase(),
      DateFormat.MMMM().format(date).toLowerCase(),
    ];
  }

  String _normalizeText(String value) => value.trim().toLowerCase();

  Set<String> _tokenize(String value) {
    return value.split(RegExp(r'[^a-z0-9]+')).where((token) => token.isNotEmpty).toSet();
  }

  List<String> _splitQueryTokens(String input) {
    final tokens = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '"') {
        inQuotes = !inQuotes;
        continue;
      }
      if (char.trim().isEmpty && !inQuotes) {
        if (buffer.isNotEmpty) {
          tokens.add(buffer.toString());
          buffer.clear();
        }
        continue;
      }
      buffer.write(char);
    }

    if (buffer.isNotEmpty) {
      tokens.add(buffer.toString());
    }

    return tokens;
  }

  String _stripQuotes(String value) {
    final trimmed = value.trim();
    if (trimmed.length >= 2 && trimmed.startsWith('"') && trimmed.endsWith('"')) {
      return trimmed.substring(1, trimmed.length - 1);
    }
    return trimmed;
  }

  double? _parseNumber(String value) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  DateTimeRange? _parseDateRange(String value) {
    final match = RegExp(r'^(\d{4})(?:[-/](\d{1,2})(?:[-/](\d{1,2}))?)?$').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.tryParse(match.group(1) ?? '');
    if (year == null) return null;
    final month = int.tryParse(match.group(2) ?? '');
    final day = int.tryParse(match.group(3) ?? '');
    if (month == null) {
      return DateTimeRange(start: DateTime(year, 1, 1), end: DateTime(year, 12, 31, 23, 59, 59, 999));
    }
    if (day == null) {
      final lastDay = _daysInMonth(year, month);
      return DateTimeRange(start: DateTime(year, month, 1), end: DateTime(year, month, lastDay, 23, 59, 59, 999));
    }
    return DateTimeRange(start: DateTime(year, month, day), end: DateTime(year, month, day, 23, 59, 59, 999));
  }

  DateTimeRange? _parseMonthRange(String value) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return null;
    final yearMonth = _parseDateRange(trimmed);
    if (yearMonth != null && yearMonth.start.month == yearMonth.end.month) {
      return yearMonth;
    }
    final monthNumber = _monthNumber(trimmed);
    if (monthNumber == null) return null;
    final now = DateTime.now();
    final lastDay = _daysInMonth(now.year, monthNumber);
    return DateTimeRange(
      start: DateTime(now.year, monthNumber, 1),
      end: DateTime(now.year, monthNumber, lastDay, 23, 59, 59, 999),
    );
  }

  int? _monthNumber(String value) {
    const lookup = {
      'jan': 1,
      'january': 1,
      'feb': 2,
      'february': 2,
      'mar': 3,
      'march': 3,
      'apr': 4,
      'april': 4,
      'may': 5,
      'jun': 6,
      'june': 6,
      'jul': 7,
      'july': 7,
      'aug': 8,
      'august': 8,
      'sep': 9,
      'sept': 9,
      'september': 9,
      'oct': 10,
      'october': 10,
      'nov': 11,
      'november': 11,
      'dec': 12,
      'december': 12,
    };
    return lookup[value];
  }

  String? _matchCategoryFilter(String token, Map<String, String> categoryLabels) {
    final normalized = _normalizeText(token);
    if (normalized.isEmpty) return null;
    for (final entry in categoryLabels.entries) {
      final name = _normalizeText(entry.key);
      final label = _normalizeText(entry.value);
      if (name == normalized || label == normalized) return entry.key;
    }
    for (final entry in categoryLabels.entries) {
      final name = _normalizeText(entry.key);
      final label = _normalizeText(entry.value);
      if (name.contains(normalized) || label.contains(normalized)) return entry.key;
    }
    return null;
  }

  String? _sourceFilterForToken(String token) {
    switch (token) {
      case 'cash':
        return 'cash';
      case 'card':
      case 'credit':
      case 'debit':
        return 'card';
      case 'account':
      case 'bank':
        return 'account';
      case 'wallet':
      case 'upi':
        return 'wallet';
    }
    return null;
  }

  String? _transactionFilterForToken(String token) {
    switch (token) {
      case 'spend':
      case 'expense':
        return 'spend';
      case 'transfer':
        return 'transfer';
    }
    return null;
  }

  List<String> _topCategories(
    List<Expense> expenses,
    Map<String, String> categoryLabels,
    String displayCurrency,
    double? budgetToEur,
  ) {
    final totals = <String, double>{};
    for (final expense in expenses) {
      final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur).abs();
      totals[expense.category] = (totals[expense.category] ?? 0) + amount;
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(6).map((e) => e.key).where((e) => categoryLabels.containsKey(e)).toList();
  }

  Future<void> _openFilters({
    required Map<String, String> categoryLabels,
    required List<Expense> expenses,
    required String displayCurrency,
    required double? budgetToEur,
  }) async {
    final result = await showModalBottomSheet<_ExpenseSearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        var localDateRange = _dateRange;
        final localSources = Set<String>.from(_sourceFilters);
        final localTransactions = Set<String>.from(_transactionFilters);
        final localCategories = Set<String>.from(_categoryFilters);
        var localNotesOnly = _notesOnly;
        final topCategories = _topCategories(expenses, categoryLabels, displayCurrency, budgetToEur);

        void applyResult() {
          Navigator.of(context).pop(
            _ExpenseSearchFilters(
              dateRange: localDateRange,
              sourceFilters: localSources,
              transactionFilters: localTransactions,
              categoryFilters: localCategories,
              notesOnly: localNotesOnly,
            ),
          );
        }

        void clearAll() {
          localDateRange = _QuickDateRange.all;
          localSources.clear();
          localTransactions.clear();
          localCategories.clear();
          localNotesOnly = false;
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      Text('Date range', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final range in _QuickDateRange.values)
                            ChoiceChip(
                              label: Text(_quickRangeLabel(range)),
                              selected: localDateRange == range,
                              onSelected: (_) => setModalState(() => localDateRange = range),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Payment source', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Cash'),
                            selected: localSources.contains('cash'),
                            avatar: const Icon(Icons.payments_outlined, size: 18),
                            onSelected: (selected) =>
                                setModalState(() => selected ? localSources.add('cash') : localSources.remove('cash')),
                          ),
                          FilterChip(
                            label: const Text('Card'),
                            selected: localSources.contains('card'),
                            avatar: const Icon(Icons.credit_card, size: 18),
                            onSelected: (selected) =>
                                setModalState(() => selected ? localSources.add('card') : localSources.remove('card')),
                          ),
                          FilterChip(
                            label: const Text('Account'),
                            selected: localSources.contains('account'),
                            avatar: const Icon(Icons.account_balance, size: 18),
                            onSelected: (selected) =>
                                setModalState(() => selected ? localSources.add('account') : localSources.remove('account')),
                          ),
                          FilterChip(
                            label: const Text('Wallet'),
                            selected: localSources.contains('wallet'),
                            avatar: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                            onSelected: (selected) =>
                                setModalState(() => selected ? localSources.add('wallet') : localSources.remove('wallet')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Type', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Spend'),
                            selected: localTransactions.contains('spend'),
                            avatar: const Icon(Icons.trending_down, size: 18),
                            onSelected: (selected) => setModalState(
                              () => selected ? localTransactions.add('spend') : localTransactions.remove('spend'),
                            ),
                          ),
                          FilterChip(
                            label: const Text('Transfer'),
                            selected: localTransactions.contains('transfer'),
                            avatar: const Icon(Icons.swap_horiz, size: 18),
                            onSelected: (selected) => setModalState(
                              () => selected ? localTransactions.add('transfer') : localTransactions.remove('transfer'),
                            ),
                          ),
                          FilterChip(
                            label: const Text('Has note'),
                            selected: localNotesOnly,
                            avatar: const Icon(Icons.sticky_note_2_outlined, size: 18),
                            onSelected: (selected) => setModalState(() => localNotesOnly = selected),
                          ),
                        ],
                      ),
                      if (topCategories.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Top categories', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in topCategories)
                              FilterChip(
                                label: Text(_categoryLabel(category, categoryLabels)),
                                selected: localCategories.contains(category),
                                onSelected: (selected) => setModalState(
                                  () => selected ? localCategories.add(category) : localCategories.remove(category),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () => setModalState(clearAll),
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear'),
                          ),
                          const Spacer(),
                          FilledButton(onPressed: applyResult, child: const Text('Apply')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;
    setState(() {
      _dateRange = result.dateRange;
      _sourceFilters
        ..clear()
        ..addAll(result.sourceFilters);
      _transactionFilters
        ..clear()
        ..addAll(result.transactionFilters);
      _categoryFilters
        ..clear()
        ..addAll(result.categoryFilters);
      _notesOnly = result.notesOnly;
    });
  }

  void _clearFilters() {
    setState(() {
      _dateRange = _QuickDateRange.all;
      _sourceFilters.clear();
      _transactionFilters.clear();
      _categoryFilters.clear();
      _notesOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = context.watch<ExpenseBloc>().state;
    final cards = context.watch<CardCubit>().state.cards;
    final accounts = context.watch<AccountsCubit>().state.items;
    final expenses = expenseState.expenses;
    final displayCurrency = expenseState.displayCurrency;
    final budgetToEur = expenseState.budgetToEur;
    final eurToInr = expenseState.eurToInr;
    final theme = Theme.of(context);
    final categories = context.watch<CategoryCubit>().state.items;
    final categoryLabels = {for (final c in categories) c.name: c.label};
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};
    _syncSearchIndex(
      categoryLabels: categoryLabels,
      expenses: expenses,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
      cards: cards,
      accounts: accounts,
    );

    final quickRange = _rangeForQuickDate(_dateRange);
    final parsed = _parseQuery(_query, categoryLabels);
    final showResults = _query.isNotEmpty || _hasActiveFilters || !parsed.isEmpty;
    final results = showResults ? _filterResults(parsed, quickRange) : const <_ExpenseSearchResult>[];

    final total = results.fold<double>(0, (sum, result) => sum + result.entry.amount);
    final summaryStart = _maxDate(parsed.after, quickRange?.start);
    final summaryEnd = _minDate(parsed.before, quickRange?.end);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search expenses'),
        actions: [
          IconButton(
            tooltip: _activeFilterCount == 0 ? 'Filters' : 'Filters ($_activeFilterCount)',
            icon: const Icon(Icons.tune),
            onPressed: () => _openFilters(
              categoryLabels: categoryLabels,
              expenses: expenses,
              displayCurrency: displayCurrency,
              budgetToEur: budgetToEur,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    hintText: 'Search (cat:, source:, type:, >100, before:2024-01-01)',
                    leading: const Icon(Icons.search),
                    trailing: _query.isEmpty
                        ? [
                            IconButton(
                              tooltip: 'Filters',
                              icon: const Icon(Icons.tune),
                              onPressed: () => _openFilters(
                                categoryLabels: categoryLabels,
                                expenses: expenses,
                                displayCurrency: displayCurrency,
                                budgetToEur: budgetToEur,
                              ),
                            ),
                          ]
                        : [
                            IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () => _searchController.clear(),
                            ),
                          ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tip: cat:Food source:card type:transfer >50 before:2024-01-01',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  if (_hasActiveFilters || parsed.isEmpty == false) ...[
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceContainerHigh,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    '${results.length} results',
                                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(fmt.format(total), style: theme.textTheme.bodyMedium),
                                  if (summaryStart != null && summaryEnd != null)
                                    Text(
                                      '${DateFormat.yMMMd().format(summaryStart)} - ${DateFormat.yMMMd().format(summaryEnd)}',
                                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                    ),
                                ],
                              ),
                            ),
                            if (_hasActiveFilters)
                              TextButton.icon(
                                onPressed: _clearFilters,
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text('Clear'),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!showResults)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Text('Start typing to search expenses.', style: theme.textTheme.titleMedium),
              ),
            )
          else if (results.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Text('No expenses match your search.', style: theme.textTheme.titleMedium),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final result = results[index];
                  final expense = result.entry.expense;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _ExpenseSearchResultTile(
                      expense: expense,
                      displayCurrency: displayCurrency,
                      budgetToEur: budgetToEur,
                      eurToInr: eurToInr,
                      categoryLabel: _categoryLabel(expense.category, categoryLabels),
                      categoryEmoji: categoryEmojis[expense.category] ?? '',
                      sourceLabel: _sourceLabelFor(expense, cards, accounts),
                    ),
                  );
                }, childCount: results.length),
              ),
            ),
        ],
      ),
    );
  }

  String _sourceLabelFor(Expense expense, List<CreditCard> cards, List<AccountCredential> accounts) {
    final type = (expense.paymentSourceType.isNotEmpty ? expense.paymentSourceType : 'cash').toLowerCase();
    if (type == 'cash') return 'Cash';
    final key = _sourceKeyForExpense(expense);
    final label = _labelForSourceKey(key, cards, accounts);
    switch (type) {
      case 'card':
        return 'Card $label';
      case 'account':
        return 'Account $label';
      case 'wallet':
        return label.isNotEmpty ? 'Wallet $label' : 'Wallet';
    }
    return label;
  }

  String _quickRangeLabel(_QuickDateRange range) {
    switch (range) {
      case _QuickDateRange.all:
        return 'All time';
      case _QuickDateRange.month:
        return 'This month';
      case _QuickDateRange.last30:
        return 'Last 30d';
      case _QuickDateRange.year:
        return 'This year';
    }
  }
}

class _ExpenseSearchFilters {
  const _ExpenseSearchFilters({
    required this.dateRange,
    required this.sourceFilters,
    required this.transactionFilters,
    required this.categoryFilters,
    required this.notesOnly,
  });

  final _QuickDateRange dateRange;
  final Set<String> sourceFilters;
  final Set<String> transactionFilters;
  final Set<String> categoryFilters;
  final bool notesOnly;
}

class _ParsedExpenseQuery {
  const _ParsedExpenseQuery({
    required this.terms,
    required this.noteTerms,
    required this.categoryFilters,
    required this.sourceFilters,
    required this.transactionFilters,
    required this.minAmount,
    required this.maxAmount,
    required this.after,
    required this.before,
    required this.requiresNote,
  });

  final List<String> terms;
  final List<String> noteTerms;
  final Set<String> categoryFilters;
  final Set<String> sourceFilters;
  final Set<String> transactionFilters;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? after;
  final DateTime? before;
  final bool requiresNote;

  bool get isEmpty =>
      terms.isEmpty &&
      noteTerms.isEmpty &&
      categoryFilters.isEmpty &&
      sourceFilters.isEmpty &&
      transactionFilters.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      after == null &&
      before == null &&
      !requiresNote;
}

class _ExpenseSearchEntry {
  const _ExpenseSearchEntry({
    required this.expense,
    required this.title,
    required this.note,
    required this.category,
    required this.categoryLabel,
    required this.sourceType,
    required this.sourceLabel,
    required this.transactionType,
    required this.currency,
    required this.amount,
    required this.date,
    required this.searchText,
    required this.tokens,
  });

  final Expense expense;
  final String title;
  final String note;
  final String category;
  final String categoryLabel;
  final String sourceType;
  final String sourceLabel;
  final String transactionType;
  final String currency;
  final double amount;
  final DateTime date;
  final String searchText;
  final Set<String> tokens;
}

class _ExpenseSearchResult {
  const _ExpenseSearchResult({required this.entry, required this.score});

  final _ExpenseSearchEntry entry;
  final int score;
}

class _ExpenseSearchResultTile extends StatelessWidget {
  const _ExpenseSearchResultTile({
    required this.expense,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.categoryLabel,
    required this.categoryEmoji,
    required this.sourceLabel,
  });

  final Expense expense;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final String categoryLabel;
  final String categoryEmoji;
  final String sourceLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
    final isNegative = amount < 0;
    final altCurrency = alternateCurrency(displayCurrency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    final altAmount = altFmt == null
        ? null
        : convertToAlternateCurrency(
            amount: amount,
            currency: displayCurrency,
            baseToSecondaryRate: eurToInr,
            currencyToBaseRate: budgetToEur,
          );
    final color = Colors.primaries[expense.category.hashCode % Colors.primaries.length];
    final note = expense.note?.trim();
    final dateLabel = DateFormat.MMMd().format(expense.date);
    final emoji = categoryEmoji.isNotEmpty ? categoryEmoji : '💰';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category emoji avatar with colored background
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          categoryLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
                        ),
                      ),
                      Text(dateLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  if (sourceLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          _iconForSourceType(expense.paymentSourceType),
                          size: 12,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            sourceLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fmt.format(amount.abs()),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isNegative ? theme.colorScheme.tertiary : theme.colorScheme.onSurface,
                  ),
                ),
                if (isNegative)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: theme.colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'Credit',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (altAmount != null && altFmt != null && !isNegative) ...[
                  const SizedBox(height: 2),
                  Text(
                    '≈ ${altFmt.format(altAmount.abs())}',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForSourceType(String type) {
    switch (type.toLowerCase()) {
      case 'card':
        return Icons.credit_card;
      case 'account':
        return Icons.account_balance;
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}

String _categoryLabel(String name, Map<String, String> labels) {
  final label = labels[name];
  return label == null || label.isEmpty ? name : label;
}

PaymentSourceKey _sourceKeyForExpense(Expense expense) {
  final type = (expense.paymentSourceType.isNotEmpty ? expense.paymentSourceType : 'cash').toLowerCase();
  return PaymentSourceKey(type: type, id: expense.paymentSourceId ?? type);
}

String _labelForSourceKey(PaymentSourceKey key, List<CreditCard> cards, List<AccountCredential> accounts) {
  if (key.type == 'card') {
    final card = cards.firstWhere(
      (c) => c.id == key.id,
      orElse: () => CreditCard(
        id: key.id,
        bankName: 'Card',
        cardNumber: key.id,
        holderName: '',
        expiryDate: '',
        cvv: '',
        cardColor: Colors.indigo,
        textColor: Colors.white,
        billingDay: 1,
        graceDays: 15,
        reminderEnabled: false,
        reminderOffsets: const [],
      ),
    );
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
    return '${card.bankName}${tail.isNotEmpty ? ' - $tail' : ''}';
  }
  if (key.type == 'account') {
    final acct = accounts.firstWhere(
      (a) => a.id == key.id,
      orElse: () => AccountCredential(id: key.id, bankName: key.id, username: '', password: '', lastUpdated: DateTime.now()),
    );
    return acct.bankName;
  }
  if (key.type == 'wallet') {
    return key.id.isNotEmpty ? key.id : 'Wallet';
  }
  return 'Cash';
}

int _daysInMonth(int year, int month) {
  final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}
