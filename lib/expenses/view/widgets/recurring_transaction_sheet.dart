import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/recurrence_frequency.dart';
import 'package:morpheus/expenses/models/recurring_transaction.dart';

class RecurringTransactionSheet extends StatefulWidget {
  const RecurringTransactionSheet({
    super.key,
    this.existing,
    required this.defaultCurrency,
  });

  final RecurringTransaction? existing;
  final String defaultCurrency;

  @override
  State<RecurringTransactionSheet> createState() =>
      _RecurringTransactionSheetState();
}

class _RecurringTransactionSheetState
    extends State<RecurringTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late DateTime _startDate;
  late RecurrenceFrequency _frequency;
  late String _currency;
  late String _category;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _startDate = existing?.startDate ?? DateTime.now();
    _frequency = existing?.frequency ?? RecurrenceFrequency.monthly;
    _currency = existing?.currency ?? widget.defaultCurrency;
    _category = existing?.category ?? '';
    _active = existing?.active ?? true;
    _intervalCtrl.text = (existing?.interval ?? 1).toString();
    _titleCtrl.text = existing?.title ?? '';
    _amountCtrl.text =
        existing != null ? existing.amount.toStringAsFixed(2) : '';
    _noteCtrl.text = existing?.note ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _intervalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final categories = context.read<CategoryCubit>().state.items;
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add categories in Settings first.')),
      );
      return;
    }
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final amount = double.parse(_amountCtrl.text.trim());
    final transaction = RecurringTransaction.create(
      id: widget.existing?.id,
      title: _titleCtrl.text.trim(),
      amount: amount,
      currency: _currency,
      category: _category,
      startDate: _startDate,
      frequency: _frequency,
      interval: interval,
      lastGenerated: widget.existing?.lastGenerated,
      active: _active,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      paymentSourceType: widget.existing?.paymentSourceType ?? 'cash',
      paymentSourceId: widget.existing?.paymentSourceId,
    );

    Navigator.of(context).pop(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoryState = context.watch<CategoryCubit>().state;
    final categories = categoryState.items;
    if (categories.isNotEmpty &&
        (_category.isEmpty || !categories.any((c) => c.name == _category))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _category = categories.first.name);
      });
    }
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null
                        ? 'Add recurring transaction'
                        : 'Edit recurring transaction',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: AppConfig.supportedCurrencies
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
              ),
              const SizedBox(height: 8),
              if (categories.isEmpty)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    helperText: 'Add default categories in Settings',
                  ),
                  child: Row(
                    children: [
                      if (categoryState.loading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
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
                  onChanged: (v) => setState(() => _category = v ?? _category),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Select category' : null,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<RecurrenceFrequency>(
                      value: _frequency,
                      decoration:
                          const InputDecoration(labelText: 'Frequency'),
                      items: RecurrenceFrequency.values
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _frequency = v ?? _frequency,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _intervalCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Interval'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return '1+';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _startDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start date'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _categoryItems(
    List<ExpenseCategory> categories,
    String selected,
  ) {
    final items = categories
        .map(
          (c) => DropdownMenuItem(value: c.name, child: Text(c.label)),
        )
        .toList();
    if (selected.isNotEmpty && !categories.any((c) => c.name == selected)) {
      items.add(DropdownMenuItem(value: selected, child: Text(selected)));
    }
    return items;
  }
}
