import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/expenses/constants/expense_categories.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/cards/card_cubit.dart';

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
  late String _currency;
  late String _category;
  late DateTime _date;
  late String _paymentSourceType;
  String? _paymentSourceId;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
    _amountCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.amount.toStringAsFixed(2)
          : '',
    );
    _noteCtrl = TextEditingController(text: widget.existing?.note ?? '');
    _currency = widget.existing?.currency ?? 'EUR';
    _category = widget.existing?.category ?? expenseCategories.first;
    _date = widget.existing?.date ?? DateTime.now();
    _paymentSourceType = widget.existing?.paymentSourceType ?? 'cash';
    _paymentSourceId = widget.existing?.paymentSourceId;
    _sourceIdCtrl = TextEditingController(text: widget.existing?.paymentSourceId ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _sourceIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Item / description',
                ),
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
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = double.tryParse(v ?? '');
                        if (parsed == null || parsed <= 0)
                          return 'Enter amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _currency,
                      items: const ['EUR', 'INR', 'USD', 'GBP']
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _currency = v ?? 'EUR'),
                      decoration: const InputDecoration(labelText: 'Currency'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _category,
                items: expenseCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _category = v ?? expenseCategories.first),
                decoration: const InputDecoration(labelText: 'Category'),
              ),
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
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
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
    );
  }

  Widget _buildPaymentSourceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
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
              final hasSelection = cards.any((c) => c.id == _paymentSourceId);
              final value = hasSelection ? _paymentSourceId : null;
              final items = cards
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text('${c.bankName} • ${_maskCard(c.cardNumber)}'),
                    ),
                  )
                  .toList();
              if (!hasSelection && _paymentSourceId != null) {
                items.add(
                  DropdownMenuItem(
                    value: _paymentSourceId,
                    child: Text('Linked to ${_paymentSourceId}'),
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                value: value,
                items: items,
                decoration: InputDecoration(
                  labelText: 'Select card',
                  suffixIcon: state.loading
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
                validator: (v) {
                  if (_paymentSourceType == 'card' &&
                      (v == null || v.isEmpty)) {
                    return 'Choose a card';
                  }
                  return null;
                },
                onChanged: (v) => setState(() => _paymentSourceId = v),
              );
            },
          )
        else if (_paymentSourceType == 'account')
          BlocBuilder<AccountsCubit, AccountsState>(
            builder: (context, state) {
              final accounts = state.items;
              final hasSelection =
                  accounts.any((a) => a.id == _paymentSourceId);
              if (accounts.isEmpty) {
                return TextFormField(
                  controller: _sourceIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Account label',
                    helperText: 'Enter bank / account name',
                  ),
                  validator: (v) {
                    if (_paymentSourceType == 'account' &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Enter an account';
                    }
                    return null;
                  },
                  onChanged: (v) => _paymentSourceId = v.trim(),
                );
              }
              final items = accounts
                  .map(
                    (a) => DropdownMenuItem<String>(
                      value: a.id,
                      child: Text('${a.bankName} (${a.username})'),
                    ),
                  )
                  .toList();
              if (!hasSelection && _paymentSourceId != null) {
                items.add(
                  DropdownMenuItem(
                    value: _paymentSourceId,
                    child: Text('Linked to ${_paymentSourceId}'),
                  ),
                );
              }
              return DropdownButtonFormField<String>(
                value: hasSelection ? _paymentSourceId : null,
                items: items,
                onChanged: (v) {
                  setState(() {
                    _paymentSourceId = v;
                    _sourceIdCtrl.text = v ?? '';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Linked account',
                  suffixIcon: state.loading
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
                validator: (v) {
                  if (_paymentSourceType == 'account' &&
                      (v == null || v.isEmpty)) {
                    return 'Choose an account';
                  }
                  return null;
                },
              );
            },
          )
        else if (_paymentSourceType == 'wallet')
          TextFormField(
            controller: _sourceIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Wallet / handle',
              helperText: 'e.g., GPay, Paytm, Revolut handle',
            ),
            validator: (v) {
              if (_paymentSourceType == 'wallet' &&
                  (v == null || v.trim().isEmpty)) {
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

  String _maskCard(String number) {
    final digits = number.replaceAll(RegExp(r'\\D'), '');
    if (digits.length < 4) return digits;
    return '•••• ${digits.substring(digits.length - 4)}';
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final note = _noteCtrl.text.trim();
    final expense = Expense(
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
      paymentSourceType: _paymentSourceType,
      paymentSourceId: _paymentSourceType == 'cash'
          ? null
          : _paymentSourceType == 'wallet'
          ? _sourceIdCtrl.text.trim()
          : _paymentSourceType == 'account'
          ? (_paymentSourceId ?? _sourceIdCtrl.text.trim())
          : _paymentSourceId,
    );
    Navigator.of(context).pop(expense);
  }
}
