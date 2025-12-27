import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'accounts/account_ledger_page.dart';
import 'package:morpheus/accounts/account_form_sheet.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/services/expense_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/utils/error_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key, this.tabIndexListenable, this.tabIndex});

  final ValueListenable<int>? tabIndexListenable;
  final int? tabIndex;

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _listController;
  late final AccountsCubit _cubit;
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final ExpenseService _expenseService = ExpenseService();
  final ForexService _forexService = ForexService();
  final Map<String, Future<double?>> _rateCache = {};
  List<Expense> _expenses = [];
  bool _expensesLoading = false;
  VoidCallback? _tabListener;

  @override
  void initState() {
    super.initState();
    _cubit = AccountsCubit(AccountsRepository())..load();
    _loadExpenses();
    _fabController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _listController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);

    _fabController.forward();
    _listController.forward();

    _tabListener = () {
      final selected = widget.tabIndexListenable?.value;
      if (selected == widget.tabIndex) {
        _refreshData();
      }
    };
    widget.tabIndexListenable?.addListener(_tabListener!);
  }

  @override
  void dispose() {
    if (_tabListener != null) {
      widget.tabIndexListenable?.removeListener(_tabListener!);
    }
    _fabController.dispose();
    _listController.dispose();
    _cubit.close();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _expensesLoading = true);
    try {
      final items = await _expenseRepository.fetchExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = items;
        _expensesLoading = false;
      });
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Load account expenses failed');
      if (!mounted) return;
      setState(() => _expensesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e, action: 'Load expenses'))));
    }
  }

  Future<void> _refreshData() async {
    await _cubit.load();
    await _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<AccountsCubit, AccountsState>(
        listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          final items = state.items;
          return Scaffold(
            backgroundColor: colorScheme.surfaceContainerLowest,
            appBar: AppBar(
              elevation: 0,
              scrolledUnderElevation: 3,
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              title: const Text('My Accounts', style: TextStyle(fontWeight: FontWeight.w600)),
              actions: [
                IconButton(
                  onPressed: () => _showSearchDialog(),
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search accounts',
                ),
                const SizedBox(width: 8),
              ],
            ),
            floatingActionButton: ScaleTransition(
              scale: _fabController,
              child: FloatingActionButton.extended(
                onPressed: _onAddAccountPressed,
                label: const Text('Add Account'),
                icon: const Icon(Icons.add_rounded),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                elevation: 6,
              ),
            ),
            body: state.loading && items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _buildEmptyState()
                : AnimatedBuilder(
                    animation: _listController,
                    builder: (context, child) {
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) {
                          final animation = Tween<double>(begin: 0, end: 1).animate(
                            CurvedAnimation(
                              parent: _listController,
                              curve: Interval(
                                (i * 0.1).clamp(0.0, 1.0),
                                ((i * 0.1) + 0.3).clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          );

                          return SlideTransition(
                            position: animation.drive(Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero)),
                            child: FadeTransition(opacity: animation, child: _buildAccountCard(items[i])),
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(Icons.account_balance_rounded, size: 48, color: colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No accounts yet',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first bank account to get started',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _onAddAccountPressed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add account'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(AccountCredential acct) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final balance = _accountBalance(acct);
    final last30Outflow = _accountOutflow(acct, sinceDays: 30);
    final last30Inflow = _accountInflow(acct, sinceDays: 30);
    final fmt = NumberFormat.simpleCurrency(name: acct.currency);
    final altCurrency = _alternateCurrency(acct.currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    Widget buildBalanceSection(double? rate) {
      String? altText(double value) {
        if (altFmt == null) return null;
        final converted = rate != null ? value * rate : value;
        return '~ ${altFmt.format(converted)}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current balance', style: theme.textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(fmt.format(balance), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          if (altText(balance) != null)
            Text(altText(balance)!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _insightChip(
                  theme,
                  Icons.arrow_downward_rounded,
                  'Inflow 30d',
                  fmt.format(last30Inflow),
                  altValue: altText(last30Inflow),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _insightChip(
                  theme,
                  Icons.arrow_upward_rounded,
                  'Outflow 30d',
                  fmt.format(last30Outflow),
                  altValue: altText(last30Outflow),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: acct.brandColor?.withOpacity(0.3) ?? colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: acct.brandColor ?? colorScheme.primary,
              boxShadow: [
                BoxShadow(
                  color: (acct.brandColor ?? colorScheme.primary).withOpacity(0.4),
                  offset: const Offset(0, 4),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            leading: _BankAvatar(
              name: acct.bankName,
              iconUrl: acct.bankIconUrl,
              color: acct.brandColor ?? colorScheme.primary,
              size: 48,
            ),
            title: Text(
              acct.bankName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Updated ${_ago(acct.lastUpdated)} - ${acct.currency}',
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'More options',
              icon: Icon(Icons.more_vert_rounded, color: colorScheme.onSurfaceVariant),
              itemBuilder: (_) => [
                _buildPopupMenuItem(Icons.copy_rounded, 'Copy username', 'copy_user'),
                _buildPopupMenuItem(Icons.key_rounded, 'Copy password', 'copy_pass'),
                _buildPopupMenuItem(Icons.edit_rounded, 'Edit', 'edit'),
                _buildPopupMenuItem(Icons.delete_outline_rounded, 'Delete', 'delete'),
              ],
              onSelected: (value) => _onMenu(value, acct),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
                  child: altCurrency == null
                      ? buildBalanceSection(null)
                      : FutureBuilder<double?>(
                          future: _rateFor(acct.currency, altCurrency),
                          builder: (context, snap) => buildBalanceSection(snap.data),
                        ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      height: 40,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showCredentialsDialog(acct),
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: const Text('Login info'),
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => _openLedger(acct),
                        icon: const Icon(Icons.receipt_long),
                        label: const Text('Transactions'),
                        style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _recordCredit(acct),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Record credit'),
                        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(IconData icon, String title, String value) {
    return PopupMenuItem(
      value: value,
      child: Row(children: [Icon(icon, size: 20), const SizedBox(width: 12), Text(title)]),
    );
  }

  // --- helpers ---

  static String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) return '${(diff.inDays / 30).floor()} mo ago';
    if (diff.inDays >= 1) return '${diff.inDays} d ago';
    if (diff.inHours >= 1) return '${diff.inHours} h ago';
    return '${diff.inMinutes} min ago';
  }

  void _onMenu(String action, AccountCredential acct) async {
    switch (action) {
      case 'copy_user':
        await _copy(acct.username, 'Username copied');
        break;
      case 'copy_pass':
        await _copy(acct.password, 'Password copied');
        break;
      case 'edit':
        _editAccount(acct);
        break;
      case 'delete':
        _deleteAccount(acct);
        break;
    }
  }

  Future<void> _copy(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Text(msg),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _editAccount(AccountCredential acct) {
    showModalBottomSheet<AccountCredential>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AccountFormSheet(existing: acct),
    ).then((value) {
      if (value != null) _cubit.save(value);
    });
  }

  void _deleteAccount(AccountCredential acct) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Text('Are you sure you want to delete ${acct.bankName} account?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _cubit.delete(acct.id);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Account deleted'), behavior: SnackBarBehavior.floating));
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _onAddAccountPressed() {
    showModalBottomSheet<AccountCredential>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AccountFormSheet(),
    ).then((value) {
      if (value != null) _cubit.save(value);
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Accounts'),
        content: const TextField(
          decoration: InputDecoration(hintText: 'Search by bank name...', prefixIcon: Icon(Icons.search_rounded)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Search')),
        ],
      ),
    );
  }

  void _showCredentialsDialog(AccountCredential acct) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final website = acct.website?.trim() ?? '';
        return AlertDialog(
          title: Text('${acct.bankName} login'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _credentialField(
                theme: theme,
                label: 'Username',
                value: acct.username,
                onCopy: () => _copy(acct.username, 'Username copied'),
              ),
              const SizedBox(height: 12),
              _credentialField(
                theme: theme,
                label: 'Password',
                value: acct.password,
                onCopy: () => _copy(acct.password, 'Password copied'),
                isPassword: true,
              ),
              if (website.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Website', style: theme.textTheme.labelSmall),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _openWebsite(ctx, website),
                  child: Text(
                    website,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
        );
      },
    );
  }

  Widget _credentialField({
    required ThemeData theme,
    required String label,
    required String value,
    required VoidCallback onCopy,
    bool isPassword = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              const SizedBox(height: 4),
              SelectableText(value, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: isPassword ? 'monospace' : null)),
            ],
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 18),
          tooltip: 'Copy $label',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Future<void> _openWebsite(BuildContext context, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;
    final uri = _normalizeUrl(trimmed);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link')));
      }
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Open bank website failed');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to open link')));
    }
  }

  Uri _normalizeUrl(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return Uri.parse('https://$raw');
    if (uri.scheme.isEmpty) {
      return Uri.parse('https://$raw');
    }
    return uri;
  }

  Future<void> _openLedger(AccountCredential acct) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountLedgerPage(account: acct, expenses: _expenses),
      ),
    );
  }

  Future<void> _recordCredit(AccountCredential acct) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime entryDate = DateTime.now();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record credit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (${acct.currency})',
                      prefixIcon: const Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(DateFormat.yMMMd().format(entryDate))),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: entryDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setDialogState(() => entryDate = picked);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(amountCtrl.text.trim());
                    if (parsed == null || parsed <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
                      return;
                    }
                    Navigator.pop(context, {'amount': parsed, 'note': noteCtrl.text.trim(), 'date': entryDate});
                  },
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;
    final amount = result['amount'] as double;
    final note = (result['note'] as String).isEmpty ? null : result['note'] as String;
    final date = result['date'] as DateTime;
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;

    try {
      final expense = Expense.create(
        title: 'Account credit',
        amount: -amount,
        currency: acct.currency,
        category: 'Transfer',
        date: date,
        note: note,
        paymentSourceType: 'account',
        paymentSourceId: acct.id,
        transactionType: 'transfer',
      );
      await _expenseService.addExpense(expense, baseCurrency: baseCurrency);
      await _loadExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credit recorded')));
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Record account credit failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to record credit')));
    }
  }

  Widget _insightChip(ThemeData theme, IconData icon, String label, String value, {String? altValue}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelSmall),
                const SizedBox(height: 2),
                Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                if (altValue != null)
                  Text(altValue, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _alternateCurrency(String currency) {
    if (!AppConfig.enableSecondaryCurrency) return null;
    if (currency == AppConfig.baseCurrency) return AppConfig.secondaryCurrency;
    if (currency == AppConfig.secondaryCurrency) return AppConfig.baseCurrency;
    return null;
  }

  Future<double?> _rateFor(String from, String to) {
    final key = '$from:$to';
    return _rateCache.putIfAbsent(key, () => _forexService.latestRate(base: from, symbol: to));
  }

  double _accountBalance(AccountCredential acct) {
    final total = _accountEntries(acct).fold<double>(0, (sum, e) => sum + e.amountForCurrency(acct.currency));
    return acct.balance - total;
  }

  double _accountOutflow(AccountCredential acct, {int? sinceDays}) {
    final entries = _accountEntries(acct, sinceDays: sinceDays);
    return entries
        .where((e) => e.amountForCurrency(acct.currency) > 0)
        .fold(0, (sum, e) => sum + e.amountForCurrency(acct.currency));
  }

  double _accountInflow(AccountCredential acct, {int? sinceDays}) {
    final entries = _accountEntries(acct, sinceDays: sinceDays);
    return entries
        .where((e) => e.amountForCurrency(acct.currency) < 0)
        .fold(0, (sum, e) => sum + e.amountForCurrency(acct.currency).abs());
  }

  List<Expense> _accountEntries(AccountCredential acct, {int? sinceDays}) {
    final since = sinceDays != null ? DateTime.now().subtract(Duration(days: sinceDays)) : null;
    return _expenses.where((e) {
      if (e.paymentSourceType.toLowerCase() != 'account') return false;
      if (e.paymentSourceId != acct.id) return false;
      if (since != null && e.date.isBefore(since)) return false;
      return true;
    }).toList();
  }
}

/// Enhanced circle avatar with bank initials and brand colors.
class _BankAvatar extends StatelessWidget {
  final String name;
  final String? iconUrl;
  final Color color;
  final double size;

  const _BankAvatar({required this.name, required this.color, this.iconUrl, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final initials = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).map((p) => p[0]).join().toUpperCase();

    final fallback = Center(
      child: Text(
        initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: size * 0.32),
      ),
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [BoxShadow(color: color.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: (iconUrl == null || iconUrl!.isEmpty)
          ? fallback
          : ClipOval(
              child: Image.network(
                iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return fallback;
                },
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
            ),
    );
  }
}
