import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/constants/category_rule_suggestions.dart';
import 'package:morpheus/expenses/expense_classifier_cubit.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/utils/card_balances.dart';

class ExpenseFormSheet extends StatefulWidget {
  const ExpenseFormSheet({super.key, this.existing});

  final Expense? existing;

  @override
  State<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends State<ExpenseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _sourceIdCtrl;
  late final FocusNode _titleFocus;
  late String _currency;
  late String _category;
  late DateTime _date;
  late String _paymentSourceType;
  String? _paymentSourceId;
  late String _transactionType;
  bool _categoryManuallySelected = false;
  String? _lastPredictionTitle;
  Timer? _titleDebounce;
  List<String> _ruleBasedSuggestions = const [];

  static const double _autoSelectThreshold = 0.8;
  static const Duration _titleDebounceDuration = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _amountCtrl = TextEditingController(text: widget.existing != null ? widget.existing!.amount.toStringAsFixed(2) : '');
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _titleFocus = FocusNode()..addListener(_handleTitleFocusChange);
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    _currency = widget.existing?.currency ?? baseCurrency;
    _category = widget.existing?.category ?? '';
    _date = widget.existing?.date ?? DateTime.now();
    _paymentSourceType = widget.existing?.paymentSourceType ?? 'cash';
    _paymentSourceId = widget.existing?.paymentSourceId;
    _transactionType = widget.existing?.transactionType ?? 'spend';
    _sourceIdCtrl = TextEditingController(text: widget.existing?.paymentSourceId ?? '');
    _categoryManuallySelected = widget.existing != null;
    context.read<ExpenseClassifierCubit>().clear();
    _amountCtrl.addListener(_onAmountChanged);
    if (_titleCtrl.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _updateRuleBasedSuggestions(_titleCtrl.text);
      });
    }
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_onAmountChanged);
    _titleFocus.removeListener(_handleTitleFocusChange);
    _titleDebounce?.cancel();
    _titleCtrl.dispose();
    _titleFocus.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _sourceIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoryState = context.watch<CategoryCubit>().state;
    final categories = categoryState.items;
    final classifierState = context.watch<ExpenseClassifierCubit>().state;
    final recentCategories = _recentCategories(context, categories);
    final ruleBasedSuggestions = _filteredRuleBasedSuggestions(categories, recentCategories);
    final excludedCategories = {...recentCategories, ...ruleBasedSuggestions};
    if (categories.isNotEmpty && (_category.isEmpty || !categories.any((c) => c.name == _category))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _category = categories.first.name);
      });
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BlocListener<ExpenseClassifierCubit, ExpenseClassifierState>(
          listenWhen: (previous, current) => previous.predictions != current.predictions,
          listener: (context, state) => _maybeAutoSelectCategory(categories, state),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.existing == null ? 'Add Expense' : 'Edit Expense',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleCtrl,
                  focusNode: _titleFocus,
                  decoration: const InputDecoration(labelText: 'Item / description'),
                  onChanged: _onTitleChanged,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final parsed = double.tryParse(v ?? '');
                          if (parsed == null || parsed <= 0) return 'Enter amount';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('expense_currency_dropdown'),
                        value: _currency,
                        items: AppConfig.supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (v) => setState(() => _currency = v ?? _currency),
                        decoration: const InputDecoration(labelText: 'Currency'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (categories.isEmpty)
                  InputDecorator(
                    decoration: const InputDecoration(labelText: 'Category', helperText: 'Add default categories in Settings'),
                    child: Row(
                      children: [
                        if (categoryState.loading)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.info_outline, size: 18),
                        const SizedBox(width: 8),
                        const Text('No categories available'),
                      ],
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _category.isEmpty ? categories.first.name : _category,
                    items: _categoryItems(categories, _category),
                    onChanged: (v) => _setCategory(v ?? _category, manual: true),
                    validator: (v) => (v == null || v.isEmpty) ? 'Select category' : null,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                _buildRuleBasedCategoryChips(categories, ruleBasedSuggestions),
                _buildRecentCategoryChips(categories, recentCategories),
                _buildCategorySuggestions(categories, classifierState, excludedCategories),
                const SizedBox(height: 10),
                _buildTransactionType(),
                const SizedBox(height: 10),
                _buildPaymentSourceSection(context),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date'),
                  subtitle: Text(DateFormat.yMMMd().format(_date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _pickDate,
                ),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const Spacer(),
                    FilledButton.icon(
                      icon: const Icon(Icons.save),
                      label: Text(widget.existing == null ? 'Save' : 'Update'),
                      onPressed: _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSourceSection(BuildContext context) {
    final amount = _parsedAmount();
    final expenses = _effectiveExpenses(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: const Key('expense_payment_source_dropdown'),
          value: _paymentSourceType,
          decoration: const InputDecoration(labelText: 'Paid via'),
          items: const [
            DropdownMenuItem(value: 'cash', child: Text('Cash')),
            DropdownMenuItem(value: 'card', child: Text('Card')),
            DropdownMenuItem(value: 'account', child: Text('Bank account')),
            DropdownMenuItem(value: 'wallet', child: Text('Wallet / UPI')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _paymentSourceType = value;
              if (value == 'cash') {
                _paymentSourceId = null;
                _sourceIdCtrl.text = '';
              }
            });
          },
        ),
        const SizedBox(height: 10),
        if (_paymentSourceType == 'card')
          BlocBuilder<CardCubit, CardState>(
            builder: (context, state) {
              final cards = state.cards;
              final availability = {for (final c in cards) c.id: _cardAvailable(c, expenses)};
              final hasSelection = cards.any((c) => c.id == _paymentSourceId);
              final value = hasSelection ? _paymentSourceId : null;
              final theme = Theme.of(context);
              final items = cards.map((c) {
                final available = availability[c.id];
                return DropdownMenuItem<String>(
                  value: c.id,
                  enabled: amount == null || available == null || available >= amount || c.id == _paymentSourceId,
                  child: Row(
                    children: [
                      Expanded(child: Text('${c.bankName} • ${_maskCard(c.cardNumber)}', overflow: TextOverflow.ellipsis)),
                      if (available != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.simpleCurrency(name: c.currency.isNotEmpty ? c.currency : _currency).format(available),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: (amount != null && available < amount)
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
              if (!hasSelection && _paymentSourceId != null) {
                items.add(DropdownMenuItem(value: _paymentSourceId, child: Text('Linked to ${_paymentSourceId}')));
              }
              return DropdownButtonFormField<String>(
                key: const Key('expense_card_dropdown'),
                isExpanded: true,
                value: value,
                items: items,
                decoration: InputDecoration(
                  labelText: 'Select card',
                  suffixIcon: state.loading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                validator: (v) {
                  if (_paymentSourceType == 'card' && (v == null || v.isEmpty)) {
                    return 'Choose a card';
                  }
                  if (_paymentSourceType == 'card' &&
                      v != null &&
                      amount != null &&
                      availability[v] != null &&
                      (availability[v] ?? 0) < amount) {
                    return 'Insufficient available limit';
                  }
                  return null;
                },
                onChanged: (v) {
                  setState(() {
                    _paymentSourceId = v;
                    final card = cards.firstWhere((c) => c.id == v, orElse: () => cards.first);
                    _currency = card.currency;
                  });
                },
              );
            },
          )
        else if (_paymentSourceType == 'account')
          BlocBuilder<AccountsCubit, AccountsState>(
            builder: (context, state) {
              final accounts = state.items;
              final availability = {for (final a in accounts) a.id: _accountAvailable(a, expenses)};
              final hasSelection = accounts.any((a) => a.id == _paymentSourceId);
              if (accounts.isEmpty) {
                return TextFormField(
                  controller: _sourceIdCtrl,
                  decoration: const InputDecoration(labelText: 'Account label', helperText: 'Enter bank / account name'),
                  validator: (v) {
                    if (_paymentSourceType == 'account' && (v == null || v.trim().isEmpty)) {
                      return 'Enter an account';
                    }
                    return null;
                  },
                  onChanged: (v) => _paymentSourceId = v.trim(),
                );
              }
              final items = accounts.map((a) {
                final available = availability[a.id];
                return DropdownMenuItem<String>(
                  value: a.id,
                  enabled: amount == null || available == null || available >= amount || a.id == _paymentSourceId,
                  child: Row(
                    children: [
                      Expanded(child: Text('${a.bankName} (${a.username})', overflow: TextOverflow.ellipsis)),
                      if (available != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          NumberFormat.simpleCurrency(name: a.currency).format(available),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (amount != null && available < amount)
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList();
              if (!hasSelection && _paymentSourceId != null) {
                items.add(DropdownMenuItem(value: _paymentSourceId, child: Text('Linked to ${_paymentSourceId}')));
              }
              return DropdownButtonFormField<String>(
                key: const Key('expense_account_dropdown'),
                isExpanded: true,
                value: hasSelection ? _paymentSourceId : null,
                items: items,
                onChanged: (v) {
                  setState(() {
                    _paymentSourceId = v;
                    _sourceIdCtrl.text = v ?? '';
                    final acct = accounts.firstWhere((a) => a.id == v, orElse: () => accounts.first);
                    _currency = acct.currency;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Linked account',
                  suffixIcon: state.loading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : null,
                ),
                validator: (v) {
                  if (_paymentSourceType == 'account' && (v == null || v.isEmpty)) {
                    return 'Choose an account';
                  }
                  if (_paymentSourceType == 'account' && v != null && amount != null && (availability[v] ?? 0) < amount) {
                    return 'Insufficient account balance';
                  }
                  return null;
                },
              );
            },
          )
        else if (_paymentSourceType == 'wallet')
          TextFormField(
            controller: _sourceIdCtrl,
            decoration: const InputDecoration(labelText: 'Wallet / handle', helperText: 'e.g., GPay, Paytm, Revolut handle'),
            validator: (v) {
              if (_paymentSourceType == 'wallet' && (v == null || v.trim().isEmpty)) {
                return 'Enter a wallet or handle';
              }
              return null;
            },
            onChanged: (v) => _paymentSourceId = v.trim(),
          )
        else
          const Text('Marked as cash'),
      ],
    );
  }

  Widget _buildTransactionType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction type'),
        const SizedBox(height: 6),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'spend', label: Text('Spend')),
            ButtonSegment(value: 'transfer', label: Text('Transfer')),
          ],
          selected: {_transactionType},
          onSelectionChanged: (selection) {
            setState(() => _transactionType = selection.first);
          },
        ),
      ],
    );
  }

  Widget _buildCategorySuggestions(List<ExpenseCategory> categories, ExpenseClassifierState state, Set<String> excluded) {
    if (state.predictions.isEmpty) return const SizedBox.shrink();
    final categoryMap = {for (final category in categories) category.name: category};
    final available = state.predictions
        .where((prediction) => categoryMap.containsKey(prediction.category) && !excluded.contains(prediction.category))
        .toList();
    if (available.isEmpty) return const SizedBox.shrink();
    final topConfidence = available.first.confidence;
    final showChips = _categoryManuallySelected || topConfidence < _autoSelectThreshold;
    if (!showChips) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final prediction in available)
            ChoiceChip(
              label: Text(categoryMap[prediction.category]?.label ?? prediction.category),
              selected: _category == prediction.category,
              onSelected: (_) => _setCategory(prediction.category, manual: true),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentCategoryChips(List<ExpenseCategory> categories, List<String> recentCategories) {
    if (recentCategories.isEmpty) return const SizedBox.shrink();
    final categoryMap = {for (final category in categories) category.name: category};
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final name in recentCategories)
                ChoiceChip(
                  label: Text(categoryMap[name]?.label ?? name),
                  selected: _category == name,
                  onSelected: (_) => _setCategory(name, manual: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBasedCategoryChips(List<ExpenseCategory> categories, List<String> suggestions) {
    if (suggestions.isEmpty) return const SizedBox.shrink();
    final categoryMap = {for (final category in categories) category.name: category};
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Suggested', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final name in suggestions)
                ChoiceChip(
                  label: Text(categoryMap[name]?.label ?? name),
                  selected: _category == name,
                  onSelected: (_) => _setCategory(name, manual: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<String> _recentCategories(BuildContext context, List<ExpenseCategory> categories) {
    if (categories.isEmpty) return const [];
    final allowed = {for (final category in categories) category.name};
    final expenses = context.read<ExpenseBloc>().state.expenses;
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));
    final recent = <String>[];
    for (final expense in sorted) {
      final name = expense.category;
      if (!allowed.contains(name)) continue;
      if (recent.contains(name)) continue;
      recent.add(name);
      if (recent.length >= 3) break;
    }
    return recent;
  }

  List<String> _filteredRuleBasedSuggestions(List<ExpenseCategory> categories, List<String> recentCategories) {
    if (_ruleBasedSuggestions.isEmpty) return const [];
    final allowed = {for (final category in categories) category.name};
    return _ruleBasedSuggestions.where((name) => allowed.contains(name) && !recentCategories.contains(name)).toList();
  }

  void _onAmountChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _handleTitleFocusChange() {
    if (_titleFocus.hasFocus) return;
    _requestPredictionImmediate();
  }

  void _onTitleChanged(String value) {
    final title = value.trim();
    if (title.isEmpty) {
      _titleDebounce?.cancel();
      _lastPredictionTitle = null;
      _clearRuleBasedSuggestions();
      context.read<ExpenseClassifierCubit>().clear();
      return;
    }
    _scheduleRuleBasedSuggestions(title);
    _requestPrediction();
  }

  void _requestPrediction() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _lastPredictionTitle = null;
      _clearRuleBasedSuggestions();
      context.read<ExpenseClassifierCubit>().clear();
      return;
    }
    if (title == _lastPredictionTitle) return;
    _lastPredictionTitle = title;
    // Use debounced predict for typing
    context.read<ExpenseClassifierCubit>().predict(title);
  }

  void _requestPredictionImmediate() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _lastPredictionTitle = null;
      _clearRuleBasedSuggestions();
      context.read<ExpenseClassifierCubit>().clear();
      return;
    }
    _titleDebounce?.cancel();
    _updateRuleBasedSuggestions(title);
    if (title == _lastPredictionTitle) return;
    _lastPredictionTitle = title;
    // Use immediate predict for blur events
    context.read<ExpenseClassifierCubit>().predictImmediate(title);
  }

  void _scheduleRuleBasedSuggestions(String title) {
    _titleDebounce?.cancel();
    _titleDebounce = Timer(_titleDebounceDuration, () {
      if (!mounted) return;
      _updateRuleBasedSuggestions(title);
    });
  }

  void _updateRuleBasedSuggestions(String title) {
    final categories = context.read<CategoryCubit>().state.items;
    final suggestions = ruleBasedCategorySuggestions(title: title, categories: categories, limit: 3);
    if (!mounted) return;
    setState(() => _ruleBasedSuggestions = suggestions);
  }

  void _clearRuleBasedSuggestions() {
    if (_ruleBasedSuggestions.isEmpty) return;
    setState(() => _ruleBasedSuggestions = const []);
  }

  void _maybeAutoSelectCategory(List<ExpenseCategory> categories, ExpenseClassifierState state) {
    if (_titleFocus.hasFocus) return;
    if (_categoryManuallySelected || state.predictions.isEmpty) return;
    final top = state.predictions.first;
    if (top.confidence < _autoSelectThreshold) return;
    if (!categories.any((c) => c.name == top.category)) return;
    if (_category == top.category) return;
    setState(() => _category = top.category);
  }

  void _setCategory(String category, {required bool manual}) {
    setState(() {
      _category = category;
      if (manual) _categoryManuallySelected = true;
    });
  }

  double? _parsedAmount() {
    final raw = _amountCtrl.text.trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  List<Expense> _effectiveExpenses(BuildContext context) {
    final all = context.read<ExpenseBloc>().state.expenses;
    final existingId = widget.existing?.id;
    if (existingId == null) return all;
    return all.where((e) => e.id != existingId).toList();
  }

  double _accountAvailable(AccountCredential acct, List<Expense> expenses) {
    final total = expenses
        .where((e) => e.paymentSourceType.toLowerCase() == 'account' && e.paymentSourceId == acct.id)
        .fold<double>(0, (sum, e) => sum + e.amountForCurrency(acct.currency));
    return acct.balance - total;
  }

  double? _cardAvailable(CreditCard card, List<Expense> expenses) {
    final limit = card.usageLimit;
    if (limit == null) return null;
    final currency = card.currency.isNotEmpty ? card.currency : context.read<SettingsCubit>().state.baseCurrency;
    final stats = computeCardBalance(expenses: expenses, card: card, currency: currency);
    return limit - stats.totalBalance;
  }

  String _maskCard(String number) {
    final digits = number.replaceAll(RegExp(r'\\D'), '');
    if (digits.length < 4) return digits;
    return '**** ${digits.substring(digits.length - 4)}';
  }

  List<DropdownMenuItem<String>> _categoryItems(List<ExpenseCategory> categories, String selected) {
    final items = categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.label))).toList();
    if (selected.isNotEmpty && !categories.any((c) => c.name == selected)) {
      items.add(DropdownMenuItem(value: selected, child: Text(selected)));
    }
    return items;
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final categories = context.read<CategoryCubit>().state.items;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add categories in Settings first.')));
      return;
    }
    final note = _noteCtrl.text.trim();
    final expense = Expense.create(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      currency: _currency,
      category: _category,
      date: _date,
      note: note.isEmpty ? null : note,
      amountEur: widget.existing?.amountEur,
      budgetCurrency: widget.existing?.budgetCurrency,
      budgetRate: widget.existing?.budgetRate,
      amountInBudgetCurrency: widget.existing?.amountInBudgetCurrency,
      paymentSourceType: _paymentSourceType.toLowerCase(),
      paymentSourceId: _paymentSourceType == 'cash'
          ? null
          : _paymentSourceType == 'wallet'
          ? _sourceIdCtrl.text.trim()
          : _paymentSourceType == 'account'
          ? (_paymentSourceId ?? _sourceIdCtrl.text.trim())
          : _paymentSourceId,
      transactionType: _transactionType.toLowerCase(),
    );
    Navigator.of(context).pop(expense);
  }
}
