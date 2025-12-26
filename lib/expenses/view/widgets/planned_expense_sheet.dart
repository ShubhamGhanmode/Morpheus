import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';

class PlannedExpenseSheet extends StatefulWidget {
  const PlannedExpenseSheet({super.key});

  @override
  State<PlannedExpenseSheet> createState() => _PlannedExpenseSheetState();
}

class _PlannedExpenseSheetState extends State<PlannedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _category = '';

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Planned expense',
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
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final val = double.tryParse(v ?? '');
                  if (val == null || val <= 0) return 'Enter amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (categories.isEmpty)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    helperText: 'Add categories in Settings',
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
                  value: _category,
                  items: _categoryItems(categories),
                  onChanged: (value) =>
                      setState(() => _category = value ?? ''),
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                  ),
                ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due date'),
                subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
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
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
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
    final planned = PlannedExpense(
      title: _titleCtrl.text.trim(),
      amount: double.parse(_amountCtrl.text.trim()),
      dueDate: _dueDate,
      category: _category.isEmpty ? null : _category,
    );
    Navigator.of(context).pop(planned);
  }

  List<DropdownMenuItem<String>> _categoryItems(
    List<ExpenseCategory> categories,
  ) {
    return [
      const DropdownMenuItem(
        value: '',
        child: Text('No category'),
      ),
      ...categories.map(
        (c) => DropdownMenuItem(value: c.name, child: Text(c.label)),
      ),
    ];
  }
}
