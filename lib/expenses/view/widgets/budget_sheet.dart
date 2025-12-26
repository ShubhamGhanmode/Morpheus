import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/settings/settings_cubit.dart';

class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key, this.existing});

  final Budget? existing;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late DateTime _startDate;
  late DateTime _endDate;
  late String _currency;

  @override
  void initState() {
    super.initState();
    _startDate =
        widget.existing?.startDate ??
        DateTime(DateTime.now().year, DateTime.now().month, 1);
    _endDate =
        widget.existing?.endDate ??
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    _amountCtrl = TextEditingController(
      text: widget.existing?.amount.toStringAsFixed(0) ?? '',
    );
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    _currency = widget.existing?.currency ?? baseCurrency;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
                  const Text(
                    'Budget',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
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
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Enter budget amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: AppConfig.supportedCurrencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select currency' : null,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(DateFormat.yMMMd().format(_startDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _startDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('End date'),
                subtitle: Text(DateFormat.yMMMd().format(_endDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: _startDate,
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) setState(() => _endDate = picked);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save budget'),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }
    final amount = double.parse(_amountCtrl.text.trim());
    final budget = Budget(
      id: widget.existing?.id,
      amount: amount,
      currency: _currency,
      startDate: _startDate,
      endDate: _endDate,
      plannedExpenses: widget.existing?.plannedExpenses,
    );
    Navigator.of(context).pop(budget);
  }
}
