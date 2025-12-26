import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/banks/bank_repository.dart';
import 'package:morpheus/banks/bank_search_cubit.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/widgets/color_picker.dart';

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, this.existing});

  final AccountCredential? existing;

  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bankCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _balanceCtrl;
  late final BankSearchCubit _bankSearchCubit;
  late String _currency;
  Color? _brandColor;
  String? _bankIconUrl;

  @override
  void initState() {
    super.initState();
    _bankSearchCubit = BankSearchCubit(BankRepository())..preload();
    _bankCtrl = TextEditingController(text: widget.existing?.bankName ?? '');
    _usernameCtrl = TextEditingController(
      text: widget.existing?.username ?? '',
    );
    _passwordCtrl = TextEditingController(
      text: widget.existing?.password ?? '',
    );
    _websiteCtrl = TextEditingController(text: widget.existing?.website ?? '');
    _balanceCtrl = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.balance.toStringAsFixed(2)
          : '',
    );
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    _currency = widget.existing?.currency ?? baseCurrency;
    _brandColor = widget.existing?.brandColor ?? AppColorPicker.defaultColor;
    _bankIconUrl = widget.existing?.bankIconUrl;
  }

  @override
  void dispose() {
    _bankCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _websiteCtrl.dispose();
    _balanceCtrl.dispose();
    _bankSearchCubit.close();
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
            children: [
              Row(
                children: [
                  Text(
                    widget.existing == null ? 'Add account' : 'Edit account',
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
                controller: _bankCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Bank name'),
                onChanged: (v) => _bankSearchCubit.search(v),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              _buildBankSuggestions(),
              const SizedBox(height: 10),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Login / username',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _websiteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Website (optional)',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _balanceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Opening balance',
                  helperText: 'Set the starting balance for this account',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final parsed = double.tryParse(v.trim());
                  if (parsed == null) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: const InputDecoration(labelText: 'Account currency'),
                items: AppConfig.supportedCurrencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _currency = v ?? _currency),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select currency' : null,
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: AppColorPicker(
                  selected: _brandColor ?? AppColorPicker.defaultColor,
                  onChanged: (color) => setState(() => _brandColor = color),
                ),
              ),
              const SizedBox(height: 16),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final account = AccountCredential(
      id: widget.existing?.id,
      bankName: _bankCtrl.text.trim(),
      bankIconUrl: _bankIconUrl,
      username: _usernameCtrl.text.trim(),
      password: _passwordCtrl.text.trim(),
      website: _websiteCtrl.text.trim().isEmpty
          ? null
          : _websiteCtrl.text.trim(),
      lastUpdated: DateTime.now(),
      brandColor: _brandColor,
      currency: _currency,
      balance: double.tryParse(_balanceCtrl.text.trim()) ??
          (widget.existing?.balance ?? 0),
    );
    Navigator.of(context).pop(account);
  }

  Widget _buildBankSuggestions() {
    return BlocBuilder<BankSearchCubit, BankSearchState>(
      bloc: _bankSearchCubit,
      builder: (context, state) {
        if (state.suggestions.isEmpty && state.loading) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading banks...'),
              ],
            ),
          );
        }

        if (state.suggestions.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Suggestions',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (state.loading) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.suggestions
                    .map(
                      (name) => ActionChip(
                        label: Text(name),
                        onPressed: () => _onBankSelected(name),
                        avatar: const Icon(Icons.account_balance, size: 16),
                      ),
                    )
                    .toList(),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 6),
                Text(
                  state.error!,
                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _onBankSelected(String name) {
    _bankCtrl.text = name;
    _bankCtrl.selection = TextSelection.collapsed(offset: name.length);
    _prefillIcon();
  }

  Future<void> _prefillIcon() async {
    if (_bankCtrl.text.isEmpty) return;
    final repo = BankRepository();
    final icon = await repo.findIconByName(_bankCtrl.text.trim());
    if (mounted) {
      setState(() => _bankIconUrl = icon);
    }
  }
}
