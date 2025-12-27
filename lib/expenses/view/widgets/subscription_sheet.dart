import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/recurrence_frequency.dart';
import 'package:morpheus/expenses/models/subscription.dart';

class SubscriptionSheet extends StatefulWidget {
  const SubscriptionSheet({
    super.key,
    this.existing,
    required this.defaultCurrency,
  });

  final Subscription? existing;
  final String defaultCurrency;

  @override
  State<SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<SubscriptionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _intervalCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  late DateTime _renewalDate;
  late RecurrenceFrequency _frequency;
  late String _currency;
  late String _category;
  bool _active = true;
  final Set<int> _reminderOffsets = {7, 1};

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _renewalDate = existing?.renewalDate ?? DateTime.now().add(const Duration(days: 7));
    _frequency = existing?.frequency ?? RecurrenceFrequency.monthly;
    _currency = existing?.currency ?? widget.defaultCurrency;
    _category = existing?.category ?? '';
    _active = existing?.active ?? true;
    _intervalCtrl.text = (existing?.interval ?? 1).toString();
    _nameCtrl.text = existing?.name ?? '';
    _amountCtrl.text =
        existing != null ? existing.amount.toStringAsFixed(2) : '';
    _noteCtrl.text = existing?.note ?? '';
    _reminderOffsets
      ..clear()
      ..addAll(existing?.reminderOffsets ?? const [7, 1]);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _intervalCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final interval = int.tryParse(_intervalCtrl.text.trim()) ?? 1;
    final amount = double.parse(_amountCtrl.text.trim());
    final subscription = Subscription.create(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      amount: amount,
      currency: _currency,
      renewalDate: _renewalDate,
      frequency: _frequency,
      interval: interval,
      reminderOffsets: _reminderOffsets.toList(),
      active: _active,
      category: _category.trim().isEmpty ? null : _category.trim(),
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      lastNotified: widget.existing?.lastNotified,
    );

    Navigator.of(context).pop(subscription);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final categoryState = context.watch<CategoryCubit>().state;
    final categories = categoryState.items;
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
                        ? 'Add subscription'
                        : 'Edit subscription',
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
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
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
              DropdownButtonFormField<String>(
                value: _category.isEmpty ? '' : _category,
                items: _categoryItems(categories, _category),
                onChanged: (v) => setState(() => _category = v ?? ''),
                decoration: InputDecoration(
                  labelText: 'Category (optional)',
                  helperText: categories.isEmpty
                      ? 'Add default categories in Settings'
                      : null,
                  suffixIcon: categoryState.loading
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
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
                    initialDate: _renewalDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _renewalDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next renewal'),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${_renewalDate.year}-${_renewalDate.month.toString().padLeft(2, '0')}-${_renewalDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Reminder offsets',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [14, 7, 3, 1]
                    .map(
                      (offset) => FilterChip(
                        label: Text('$offset days before'),
                        selected: _reminderOffsets.contains(offset),
                        onSelected: (v) => setState(() {
                          if (v) {
                            _reminderOffsets.add(offset);
                          } else {
                            _reminderOffsets.remove(offset);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
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
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('No category')),
      ...categories.map(
        (c) => DropdownMenuItem(value: c.name, child: Text(c.label)),
      ),
    ];
    if (selected.isNotEmpty && !categories.any((c) => c.name == selected)) {
      items.add(DropdownMenuItem(value: selected, child: Text(selected)));
    }
    return items;
  }
}
