import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/services/export_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/expense_classifier_cubit.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/expense_group.dart';
import 'package:morpheus/expenses/models/next_occurrence.dart';
import 'package:morpheus/expenses/models/payment_source_key.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/models/recurrence_frequency.dart';
import 'package:morpheus/expenses/models/recurring_transaction.dart';
import 'package:morpheus/expenses/models/spending_anomaly.dart';
import 'package:morpheus/expenses/models/subscription.dart';
import 'package:morpheus/expenses/utils/expense_amounts.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/view/widgets/budget_sheet.dart';
import 'package:morpheus/expenses/view/widgets/expense_form_sheet.dart';
import 'package:morpheus/expenses/view/widgets/planned_expense_sheet.dart';
import 'package:morpheus/expenses/view/widgets/recurring_transaction_sheet.dart';
import 'package:morpheus/expenses/view/widgets/subscription_sheet.dart';
import 'package:morpheus/expenses/view/expense_search_page.dart';
import 'package:morpheus/expenses/view/receipt_scan_page.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/utils/card_balances.dart';
import 'package:morpheus/utils/error_mapper.dart';

part 'all_expenses_page.dart';

class ExpenseDashboardPage extends StatelessWidget {
  const ExpenseDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ExpenseBloc(ExpenseRepository(), baseCurrency: baseCurrency)..add(const LoadExpenses())),
        BlocProvider(create: (_) => ExpenseClassifierCubit()),
        BlocProvider(create: (_) => CardCubit(CardRepository())..loadCards()),
        BlocProvider(create: (_) => AccountsCubit(AccountsRepository())..load()),
      ],
      child: _ExpenseDashboardView(),
    );
  }
}

class _ExpenseDashboardView extends StatelessWidget {
  const _ExpenseDashboardView();

  @override
  Widget build(BuildContext context) {
    final categoryLabels = {for (final c in context.watch<CategoryCubit>().state.items) c.name: c.label};
    Future<void> refreshAll() async {
      context.read<ExpenseBloc>().add(const LoadExpenses());
      await context.read<CardCubit>().loadCards();
      await context.read<AccountsCubit>().load();
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<CardCubit, CardState>(
          listenWhen: (previous, current) => previous.cards != current.cards,
          listener: (context, state) {
            NotificationService.instance.scheduleCardReminders(state.cards).catchError((error, stack) async {
              await ErrorReporter.recordError(error, stack, reason: 'Schedule card reminders failed');
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(errorMessage(error, action: 'Schedule card reminders'))));
            });
          },
        ),
        BlocListener<ExpenseBloc, ExpenseState>(
          listenWhen: (previous, current) => previous.subscriptions != current.subscriptions,
          listener: (context, state) {
            NotificationService.instance.scheduleSubscriptionReminders(state.subscriptions).catchError((error, stack) async {
              await ErrorReporter.recordError(error, stack, reason: 'Schedule subscription reminders failed');
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(errorMessage(error, action: 'Schedule subscription reminders'))));
            });
          },
        ),
        BlocListener<SettingsCubit, SettingsState>(
          listenWhen: (previous, current) => previous.baseCurrency != current.baseCurrency,
          listener: (context, state) {
            context.read<ExpenseBloc>().add(SetBaseCurrency(state.baseCurrency));
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses & Budget'),
          actions: [IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded), onPressed: () => refreshAll())],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'expenses_fab',
          onPressed: () => _openExpenseForm(context),
          // onPressed: () {
          //   throw StateError('This is test exception');
          // },
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          icon: const Icon(Icons.add_chart),
          label: const Text('Add expense'),
          elevation: 6,
        ),
        body: BlocConsumer<ExpenseBloc, ExpenseState>(
          listenWhen: (previous, current) => previous.error != current.error && current.error != null,
          listener: (context, state) {
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          builder: (context, state) {
            if (state.loading && state.expenses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final cardState = context.watch<CardCubit>().state;
            final accountState = context.watch<AccountsCubit>().state;

            return RefreshIndicator(
              onRefresh: () => refreshAll(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                children: [
                  _ForexBadge(rate: state.eurToInr),
                  const SizedBox(height: 12),
                  _MetricsRow(state: state),
                  const SizedBox(height: 12),
                  _ExpenseQuickActions(
                    onViewAll: () => _openAllExpenses(context, state, cardState.cards, accountState.items),
                    onScanReceipt: () => _openReceiptScan(context),
                  ),
                  const SizedBox(height: 12),
                  _SourceBreakdownCard(
                    expenses: state.expenses,
                    focusMonth: state.focusMonth,
                    displayCurrency: state.displayCurrency,
                    budgetToEur: state.budgetToEur,
                    eurToInr: state.eurToInr,
                    cards: cardState.cards,
                    accounts: accountState.items,
                  ),
                  const SizedBox(height: 12),
                  _CardSpendPanel(
                    expenses: state.expenses,
                    displayCurrency: state.displayCurrency,
                    cards: cardState.cards,
                    eurToInr: state.eurToInr,
                  ),
                  const SizedBox(height: 12),
                  _UsableBudgetCard(state: state),
                  const SizedBox(height: 12),
                  _ForecastCard(state: state),
                  const SizedBox(height: 12),
                  _RecurringPanel(
                    state: state,
                    onAddRecurring: () => _openRecurringSheet(context),
                    onAddSubscription: () => _openSubscriptionSheet(context),
                    onEditRecurring: (tx) => _openRecurringSheet(context, existing: tx),
                    onEditSubscription: (sub) => _openSubscriptionSheet(context, existing: sub),
                    onDeleteRecurring: (tx) => _confirmDeleteRecurring(context, tx),
                    onDeleteSubscription: (sub) => _confirmDeleteSubscription(context, sub),
                    onRecordRecurring: (tx) => _recordRecurring(context, tx),
                  ),
                  const SizedBox(height: 12),
                  _BurnChart(state: state),
                  const SizedBox(height: 12),
                  _AnomalyCard(state: state),
                  const SizedBox(height: 12),
                  _CategoryChart(state: state, categoryLabels: categoryLabels),
                  const SizedBox(height: 12),
                  _BudgetCard(state: state, categoryLabels: categoryLabels),
                  const SizedBox(height: 12),
                  _ExpenseList(
                    state: state,
                    cards: cardState.cards,
                    accounts: accountState.items,
                    categoryLabels: categoryLabels,
                    onEdit: (expense) => _openExpenseForm(context, existing: expense),
                    onDelete: (expense) => _confirmDeleteExpense(context, expense),
                    onExport: () => _exportExpenses(
                      context,
                      state,
                      cards: cardState.cards,
                      accounts: accountState.items,
                      categoryLabels: categoryLabels,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openExpenseForm(BuildContext context, {Expense? existing}) async {
    final cardCubit = context.read<CardCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    final categoryCubit = context.read<CategoryCubit>();
    final classifierCubit = context.read<ExpenseClassifierCubit>();
    final expenseBloc = context.read<ExpenseBloc>();
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: expenseBloc),
          BlocProvider.value(value: categoryCubit),
          BlocProvider.value(value: classifierCubit),
          BlocProvider.value(value: cardCubit),
          BlocProvider.value(value: accountsCubit),
        ],
        child: ExpenseFormSheet(existing: existing),
      ),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      if (existing == null) {
        context.read<ExpenseBloc>().add(AddExpense(result));
      } else {
        context.read<ExpenseBloc>().add(UpdateExpense(result));
      }
      classifierCubit.clearCache();
    }
  }

  Future<void> _openRecurringSheet(BuildContext context, {RecurringTransaction? existing}) async {
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    final categoryCubit = context.read<CategoryCubit>();
    final result = await showModalBottomSheet<RecurringTransaction>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: categoryCubit,
        child: RecurringTransactionSheet(existing: existing, defaultCurrency: baseCurrency),
      ),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(SaveRecurringTransaction(result));
    }
  }

  Future<void> _openSubscriptionSheet(BuildContext context, {Subscription? existing}) async {
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    final categoryCubit = context.read<CategoryCubit>();
    final result = await showModalBottomSheet<Subscription>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: categoryCubit,
        child: SubscriptionSheet(existing: existing, defaultCurrency: baseCurrency),
      ),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(SaveSubscription(result));
    }
  }

  Future<void> _confirmDeleteRecurring(BuildContext context, RecurringTransaction transaction) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete recurring transaction'),
            content: Text('Remove "${transaction.title}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (shouldDelete) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(DeleteRecurringTransaction(transaction.id));
    }
  }

  Future<void> _confirmDeleteSubscription(BuildContext context, Subscription subscription) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete subscription'),
            content: Text('Remove "${subscription.name}"?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (shouldDelete) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(DeleteSubscription(subscription.id));
    }
  }

  void _recordRecurring(BuildContext context, RecurringTransaction transaction) {
    context.read<ExpenseBloc>().add(RecordRecurringTransaction(transaction));
  }

  Future<void> _openReceiptScan(BuildContext context) async {
    if (!AppConfig.enableReceiptScanning) return;
    final expenseBloc = context.read<ExpenseBloc>();
    final categoryCubit = context.read<CategoryCubit>();
    final settingsCubit = context.read<SettingsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: expenseBloc),
            BlocProvider.value(value: categoryCubit),
            BlocProvider.value(value: settingsCubit),
          ],
          child: const ReceiptScanPage(),
        ),
      ),
    );
  }

  Future<void> _openAllExpenses(
    BuildContext context,
    ExpenseState state,
    List<CreditCard> cards,
    List<AccountCredential> accounts,
  ) async {
    final categoryCubit = context.read<CategoryCubit>();
    final expenseBloc = context.read<ExpenseBloc>();
    final cardCubit = context.read<CardCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: expenseBloc),
            BlocProvider.value(value: cardCubit),
            BlocProvider.value(value: accountsCubit),
            BlocProvider.value(value: categoryCubit),
          ],
          child: AllExpensesPage(
            expenses: state.expenses,
            displayCurrency: state.displayCurrency,
            budgetToEur: state.budgetToEur,
            eurToInr: state.eurToInr,
            cards: cards,
            accounts: accounts,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteExpense(BuildContext context, Expense expense) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete expense'),
            content: Text('Remove "${expense.title}" from your records?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (shouldDelete) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(DeleteExpense(expense.id));
    }
  }

  Future<void> _exportExpenses(
    BuildContext context,
    ExpenseState state, {
    required List<CreditCard> cards,
    required List<AccountCredential> accounts,
    required Map<String, String> categoryLabels,
  }) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );

    if (range == null) return;

    final start = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);

    final filtered = state.expenses.where((e) {
      return !e.date.isBefore(start) && !e.date.isAfter(end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    String csvField(Object? value) {
      final text = value?.toString() ?? '';
      final needsQuotes = text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r');
      if (!needsQuotes) return text;
      final escaped = text.replaceAll('"', '""');
      return '"$escaped"';
    }

    String csvRow(List<Object?> values) => values.map(csvField).join(',');
    String formatAmount(double? amount) => amount == null ? '' : amount.toStringAsFixed(2);
    String formatDate(DateTime? date) => date == null ? '' : DateFormat('yyyy-MM-dd').format(date);

    String categoryLabelFor(String category) => categoryLabels[category] ?? category;

    String paymentSourceLabelFor(Expense expense) {
      final type = expense.paymentSourceType.toLowerCase();
      if (type == 'card') {
        final card = cards.firstWhere(
          (c) => c.id == expense.paymentSourceId,
          orElse: () => CreditCard(
            id: expense.paymentSourceId ?? 'card',
            bankName: 'Card',
            cardNumber: expense.paymentSourceId ?? '',
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
        final digits = card.cardNumber.replaceAll(RegExp(r'\\D'), '');
        final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
        return '${card.bankName}${tail.isNotEmpty ? ' - $tail' : ''}';
      }
      if (type == 'account') {
        final acct = accounts.firstWhere(
          (a) => a.id == expense.paymentSourceId,
          orElse: () => AccountCredential(
            id: expense.paymentSourceId ?? 'account',
            bankName: expense.paymentSourceId ?? 'Account',
            username: '',
            password: '',
            lastUpdated: DateTime.now(),
          ),
        );
        return acct.bankName;
      }
      if (type == 'wallet') {
        final wallet = expense.paymentSourceId?.trim();
        return wallet == null || wallet.isEmpty ? 'Wallet' : 'Wallet $wallet';
      }
      return 'Cash';
    }

    final expenseBuffer = StringBuffer();
    expenseBuffer.writeln(
      csvRow([
        'Id',
        'Title',
        'Amount',
        'Currency',
        'Category',
        'CategoryLabel',
        'Date',
        'TransactionType',
        'PaymentSourceType',
        'PaymentSourceLabel',
        'PaymentSourceId',
        'Note',
        'BaseCurrency',
        'AmountInBaseCurrency',
        'BudgetCurrency',
        'AmountInBudgetCurrency',
      ]),
    );
    for (final e in filtered) {
      expenseBuffer.writeln(
        csvRow([
          e.id,
          e.title,
          formatAmount(e.amount),
          e.currency,
          e.category,
          categoryLabelFor(e.category),
          formatDate(e.date),
          e.transactionType,
          e.paymentSourceType,
          paymentSourceLabelFor(e),
          e.paymentSourceId ?? '',
          e.note ?? '',
          e.baseCurrency ?? '',
          formatAmount(e.amountInBaseCurrency),
          e.budgetCurrency ?? '',
          formatAmount(e.amountInBudgetCurrency),
        ]),
      );
    }

    final exportService = ExportService();
    final exports = <ExportResult>[];
    final rangeLabel = '${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}';
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final expensesFileName = 'expenses_${rangeLabel}_$stamp.csv';

    try {
      exports.add(await exportService.exportCsv(fileName: expensesFileName, contents: expenseBuffer.toString()));

      final budget = state.activeBudget;
      int plannedCount = 0;
      if (budget != null) {
        final budgetBuffer = StringBuffer();
        budgetBuffer.writeln(csvRow(['BudgetId', 'Amount', 'Currency', 'StartDate', 'EndDate', 'Reserved', 'Usable']));
        budgetBuffer.writeln(
          csvRow([
            budget.id,
            formatAmount(budget.amount),
            budget.currency,
            formatDate(budget.startDate),
            formatDate(budget.endDate),
            formatAmount(state.reservedPlanned),
            formatAmount(state.usableBudget),
          ]),
        );

        final budgetFileName = 'budget_summary_${rangeLabel}_$stamp.csv';
        exports.add(await exportService.exportCsv(fileName: budgetFileName, contents: budgetBuffer.toString()));

        if (budget.plannedExpenses.isNotEmpty) {
          plannedCount = budget.plannedExpenses.length;
          final plannedBuffer = StringBuffer();
          plannedBuffer.writeln(csvRow(['PlannedId', 'Title', 'Amount', 'Currency', 'DueDate', 'Category', 'CategoryLabel']));
          for (final p in budget.plannedExpenses) {
            plannedBuffer.writeln(
              csvRow([
                p.id,
                p.title,
                formatAmount(p.amount),
                budget.currency,
                formatDate(p.dueDate),
                p.category ?? '',
                p.category == null ? '' : categoryLabelFor(p.category!),
              ]),
            );
          }

          final plannedFileName = 'planned_expenses_${rangeLabel}_$stamp.csv';
          exports.add(await exportService.exportCsv(fileName: plannedFileName, contents: plannedBuffer.toString()));
        }
      }

      if (!context.mounted) return;
      final location = exports.first.path ?? exports.first.label;
      final extraCount = exports.length - 1;
      final extraLabel = extraCount > 0 ? ' (+$extraCount more file${extraCount == 1 ? '' : 's'})' : '';
      final summary = [
        '${filtered.length} expenses',
        if (budget != null) 'budget summary',
        if (plannedCount > 0) '$plannedCount planned expenses',
      ].join(', ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported $summary to $location$extraLabel')));
    } on ExportException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Export expenses failed');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(e, action: 'Export expenses'))));
    }
  }
}

class _ForexBadge extends StatelessWidget {
  const _ForexBadge({required this.rate});

  final double? rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = rate == null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer.withOpacity(0.7)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.currency_exchange, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppConfig.baseCurrency} to ${AppConfig.secondaryCurrency}',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
                ),
                const SizedBox(height: 2),
                isLoading
                    ? Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onPrimaryContainer),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Fetching rate...',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                          ),
                        ],
                      )
                    : Text(
                        '1 ${AppConfig.baseCurrency} = ${rate!.toStringAsFixed(2)} ${AppConfig.secondaryCurrency}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
              ],
            ),
          ),
          if (!isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Today',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _UsableBudgetCard extends StatelessWidget {
  const _UsableBudgetCard({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = state.activeBudget;
    final currency = budget?.currency ?? state.displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final usable = state.usableBudget;
    final range = budget == null
        ? 'No budget set'
        : '${DateFormat.MMMd().format(budget.startDate)} - ${DateFormat.MMMd().format(budget.endDate)}';
    final budgetToEur = state.budgetToEur ?? (currency == AppConfig.baseCurrency ? 1.0 : null);
    final altCurrency = alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    double? altAmount() {
      if (altFmt == null) return null;
      return convertToAlternateCurrency(
        amount: usable,
        currency: currency,
        baseToSecondaryRate: state.eurToInr,
        currencyToBaseRate: budgetToEur,
      );
    }

    final isNegative = usable < 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNegative
              ? [Colors.red.shade100, Colors.red.shade50]
              : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isNegative ? Colors.red.withOpacity(0.2) : theme.colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isNegative ? Icons.warning_amber_rounded : Icons.account_balance_wallet,
                size: 26,
                color: isNegative ? Colors.red.shade700 : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Usable budget',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isNegative ? theme.colorScheme.onPrimaryFixedVariant : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (isNegative) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            'Over budget',
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    range,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isNegative ? theme.colorScheme.onPrimaryFixedVariant : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    budget == null ? '-' : fmt.format(usable.abs()),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isNegative ? Colors.red.shade700 : null,
                    ),
                  ),
                  if (budget != null && altAmount() != null && altFmt != null)
                    Text(
                      '\u2248 ${altFmt.format(altAmount()!.abs())} today',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isNegative ? theme.colorScheme.onPrimaryFixedVariant : theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final forecastTotal = state.forecastTotal;
    if (forecastTotal == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: state.displayCurrency);
    final daily = state.forecastDaily;
    final overBudget = state.forecastOverBudget;
    final isOver = overBudget != null && overBudget >= 0;
    final isUnder = overBudget != null && overBudget < 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOver
              ? [Colors.orange.shade100, Colors.orange.shade50]
              : isUnder
              ? [Colors.green.shade100, Colors.green.shade50]
              : [theme.colorScheme.secondaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isOver
                    ? Colors.orange.withOpacity(0.2)
                    : isUnder
                    ? Colors.green.withOpacity(0.2)
                    : theme.colorScheme.secondary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isOver
                    ? Icons.warning_amber_rounded
                    : isUnder
                    ? Icons.check_circle_outline
                    : Icons.trending_up,
                size: 26,
                color: isOver
                    ? Colors.orange.shade700
                    : isUnder
                    ? Colors.green.shade700
                    : theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Forecast',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryFixedVariant,
                        ),
                      ),
                      if (isOver || isUnder) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOver ? Colors.orange.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isOver ? 'Over budget' : 'On track',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isOver ? Colors.orange.shade800 : Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Projected month-end spend',
                    style: theme.textTheme.bodySmall!.copyWith(color: theme.colorScheme.onPrimaryFixedVariant),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    fmt.format(forecastTotal),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryFixedVariant,
                    ),
                  ),
                  if (daily != null)
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 14, color: theme.colorScheme.onPrimaryFixedVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${fmt.format(daily)} daily burn',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryFixedVariant),
                        ),
                      ],
                    ),
                  if (overBudget != null)
                    Row(
                      children: [
                        Icon(
                          isOver ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: isOver ? Colors.orange.shade700 : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOver ? 'Over by ${fmt.format(overBudget)}' : 'Under by ${fmt.format(overBudget.abs())}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isOver ? Colors.orange.shade700 : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringPanel extends StatelessWidget {
  const _RecurringPanel({
    required this.state,
    required this.onAddRecurring,
    required this.onAddSubscription,
    required this.onEditRecurring,
    required this.onEditSubscription,
    required this.onDeleteRecurring,
    required this.onDeleteSubscription,
    required this.onRecordRecurring,
  });

  final ExpenseState state;
  final VoidCallback onAddRecurring;
  final VoidCallback onAddSubscription;
  final ValueChanged<RecurringTransaction> onEditRecurring;
  final ValueChanged<Subscription> onEditSubscription;
  final ValueChanged<RecurringTransaction> onDeleteRecurring;
  final ValueChanged<Subscription> onDeleteSubscription;
  final ValueChanged<RecurringTransaction> onRecordRecurring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    final recurring =
        state.recurringTransactions
            .where((t) => t.active)
            .map(
              (t) => NextRecurring(
                transaction: t,
                nextDate: t.nextOccurrence(from: now),
              ),
            )
            .toList()
          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

    final subscriptions =
        state.subscriptions
            .where((s) => s.active)
            .map(
              (s) => NextSubscription(
                subscription: s,
                nextDate: s.nextRenewal(from: now),
              ),
            )
            .toList()
          ..sort((a, b) => a.nextDate.compareTo(b.nextDate));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.autorenew, size: 24, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recurring & subscriptions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        '${recurring.length + subscriptions.length} active items',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddRecurring,
                    icon: const Icon(Icons.autorenew, size: 18),
                    label: const Text('Recurring'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddSubscription,
                    icon: const Icon(Icons.subscriptions, size: 18),
                    label: const Text('Subscription'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: subscriptions.isEmpty && recurring.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Add recurring income/expenses or subscriptions to track renewals.',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (subscriptions.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.subscriptions, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text('Subscriptions', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final item in subscriptions.take(4))
                          _RecurringItemTile(
                            icon: Icons.subscriptions,
                            title: item.subscription.name,
                            subtitle:
                                'Next ${DateFormat.MMMd().format(item.nextDate)} \u2022 ${_frequencyLabel(item.subscription.frequency)}',
                            amount: NumberFormat.simpleCurrency(
                              name: item.subscription.currency,
                            ).format(item.subscription.amount),
                            onEdit: () => onEditSubscription(item.subscription),
                            onDelete: () => onDeleteSubscription(item.subscription),
                          ),
                        const SizedBox(height: 12),
                      ],
                      if (recurring.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(Icons.autorenew, size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Recurring transactions',
                              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final item in recurring.take(4))
                          _RecurringItemTile(
                            icon: Icons.autorenew,
                            title: item.transaction.title,
                            subtitle:
                                'Next ${DateFormat.MMMd().format(item.nextDate)} \u2022 ${_frequencyLabel(item.transaction.frequency)}',
                            amount: NumberFormat.simpleCurrency(name: item.transaction.currency).format(item.transaction.amount),
                            onEdit: () => onEditRecurring(item.transaction),
                            onDelete: () => onDeleteRecurring(item.transaction),
                            onRecord: () => onRecordRecurring(item.transaction),
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecurringItemTile extends StatelessWidget {
  const _RecurringItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.onEdit,
    required this.onDelete,
    this.onRecord,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onRecord != null)
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
                        tooltip: 'Record now',
                        onPressed: onRecord,
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16),
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  const _AnomalyCard({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final anomalies = state.anomalies;
    if (anomalies.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: state.displayCurrency);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade100, Colors.amber.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade700.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(child: Text('\u26a0\ufe0f', style: TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anomaly watch',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.orange.shade900),
                      ),
                      Text(
                        '${anomalies.length} unusual spending pattern${anomalies.length > 1 ? 's' : ''} detected',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Anomaly items
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (var i = 0; i < anomalies.take(4).length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                          child: Center(
                            child: Text(
                              anomalies.elementAt(i).type == AnomalyType.category ? '\ud83c\udff7\ufe0f' : '\ud83c\udfea',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anomalies.elementAt(i).label,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                anomalies.elementAt(i).type == AnomalyType.category ? 'Category spike' : 'Merchant spike',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(anomalies.elementAt(i).currentAmount),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                '+${fmt.format(anomalies.elementAt(i).delta)} vs avg',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _frequencyLabel(RecurrenceFrequency frequency) {
  switch (frequency) {
    case RecurrenceFrequency.daily:
      return 'Daily';
    case RecurrenceFrequency.weekly:
      return 'Weekly';
    case RecurrenceFrequency.monthly:
      return 'Monthly';
    case RecurrenceFrequency.yearly:
      return 'Yearly';
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final currency = state.displayCurrency;
    final altCurrency = alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      return convertToAlternateCurrency(
        amount: value,
        currency: currency,
        baseToSecondaryRate: state.eurToInr,
        currencyToBaseRate: state.budgetToEur,
      );
    }

    String? altValue(double value) {
      final converted = altAmount(value);
      if (converted == null) return null;
      return '~ ${altFmt!.format(converted)}';
    }

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'This month',
            value: _money(state.monthlyTotal, currency),
            altValue: altValue(state.monthlyTotal),
            subtitle: 'Spent in ${DateFormat.MMM().format(state.focusMonth)}',
            icon: Icons.calendar_month,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'This year',
            value: _money(state.annualTotal, currency),
            altValue: altValue(state.annualTotal),
            subtitle: 'Year-to-date',
            icon: Icons.timeline,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  String _money(double amount, String currency) {
    final fmt = NumberFormat.simpleCurrency(name: currency);
    return fmt.format(amount);
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.altValue,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? altValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (altValue != null) ...[
              const SizedBox(height: 2),
              Text(altValue!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 4),
            Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _BurnChart extends StatelessWidget {
  const _BurnChart({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    return _MonthlyLineChart(
      expenses: state.expenses,
      focusMonth: state.focusMonth,
      displayCurrency: state.displayCurrency,
      budgetToEur: state.budgetToEur,
    );
  }
}

class _MonthlyLineChart extends StatelessWidget {
  const _MonthlyLineChart({required this.expenses, required this.focusMonth, required this.displayCurrency, this.budgetToEur});

  final List<Expense> expenses;
  final DateTime focusMonth;
  final String displayCurrency;
  final double? budgetToEur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime(focusMonth.year, focusMonth.month, 1);
    final months = List.generate(6, (i) => DateTime(now.year, now.month - (5 - i), 1));
    final values = <double>[];
    for (final m in months) {
      final start = DateTime(m.year, m.month, 1);
      final end = DateTime(m.year, m.month + 1, 0, 23, 59, 59);
      final total = expenses
          .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
          .fold<double>(0, (sum, e) => sum + _amount(e));
      values.add(total);
    }

    final maxY = ((values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0).clamp(0, double.infinity) as double) + 50;
    final avgMonthly = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
    final currentMonth = values.isNotEmpty ? values.last : 0.0;
    final trend = values.length >= 2 ? values.last - values[values.length - 2] : 0.0;
    final trendUp = trend > 0;
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade100, Colors.blue.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.show_chart, size: 24, color: Colors.indigo.shade700),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '6-month burn',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.indigo.shade900),
                      ),
                      Text(
                        'Avg ${fmt.format(avgMonthly)}/month',
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.indigo.shade700),
                      ),
                    ],
                  ),
                ),
                // Trend indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: trendUp ? Colors.red.shade100 : Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: trendUp ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        fmt.format(trend.abs()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: trendUp ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            child: SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY / 4,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: theme.colorScheme.outlineVariant.withOpacity(0.3), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              NumberFormat.compact().format(value),
                              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) return const SizedBox.shrink();
                          final isCurrentMonth = index == months.length - 1;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              DateFormat.MMM().format(months[index]),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: isCurrentMonth ? FontWeight.w700 : FontWeight.w500,
                                color: isCurrentMonth ? Colors.indigo : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                      gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.blue.shade400]),
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: index == values.length - 1 ? Colors.indigo : Colors.indigo.shade200,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [Colors.indigo.withOpacity(0.2), Colors.indigo.withOpacity(0.02)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _amount(Expense expense) {
    if (expense.transactionType == 'transfer') return 0;
    return amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({required this.state, required this.categoryLabels});

  final ExpenseState state;
  final Map<String, String> categoryLabels;

  @override
  Widget build(BuildContext context) {
    return _CategoryPieChart(categoryTotals: state.categoryTotals, categoryLabels: categoryLabels);
  }
}

class _CategoryPieChart extends StatelessWidget {
  const _CategoryPieChart({required this.categoryTotals, required this.categoryLabels});

  final Map<String, double> categoryTotals;
  final Map<String, String> categoryLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<CategoryCubit>().state.items;
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};
    final items = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = items.fold<double>(0, (sum, e) => sum + e.value);

    if (items.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.pie_chart_outline, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
              const SizedBox(height: 8),
              Text(
                'No category data yet',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                'Add expenses to see where your money goes',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('\ud83c\udfaf', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Category mix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 36,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].value,
                        title: '${((items[i].value / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.primaries[i % Colors.primaries.length],
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        titlePositionPercentageOffset: 0.6,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Enhanced category list with emojis
            ...items.take(5).map((entry) {
              final i = items.indexOf(entry);
              final emoji = categoryEmojis[entry.key] ?? '\ud83c\udff7\ufe0f';
              final percentage = ((entry.value / total) * 100).toStringAsFixed(1);
              final color = Colors.primaries[i % Colors.primaries.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _categoryLabel(entry.key, categoryLabels),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: entry.value / total,
                              backgroundColor: color.withOpacity(0.15),
                              valueColor: AlwaysStoppedAnimation(color),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          entry.value.toStringAsFixed(0),
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '$percentage%',
                          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            if (items.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${items.length - 5} more categories',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.state, required this.categoryLabels});

  final ExpenseState state;
  final Map<String, String> categoryLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = state.activeBudget;
    final currency = budget?.currency ?? state.displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final spent = state.monthlyTotal;
    final budgetToEur = state.budgetToEur ?? (currency == AppConfig.baseCurrency ? 1.0 : null);
    final altCurrency = alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      return convertToAlternateCurrency(
        amount: value,
        currency: currency,
        baseToSecondaryRate: state.eurToInr,
        currencyToBaseRate: budgetToEur,
      );
    }

    String? altText(double value) {
      final converted = altAmount(value);
      if (converted == null) return null;
      return '~ ${altFmt!.format(converted)}';
    }

    final overBudget = budget != null && spent > budget.amount;
    final progress = budget != null && budget.amount > 0 ? (spent / budget.amount).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: overBudget
                    ? [theme.colorScheme.errorContainer, theme.colorScheme.error.withOpacity(0.5)]
                    : [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: (overBudget ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer).withOpacity(
                      0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    overBudget ? Icons.warning_amber_rounded : Icons.savings,
                    size: 24,
                    color: overBudget ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget planner',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: overBudget ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      if (budget != null)
                        Text(
                          '${DateFormat.MMMd().format(budget.startDate)} - ${DateFormat.MMMd().format(budget.endDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: (overBudget ? theme.colorScheme.onErrorContainer : theme.colorScheme.onPrimaryContainer)
                                .withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openBudgetSheet(context, budget),
                  icon: const Icon(Icons.savings, size: 18),
                  label: Text(budget == null ? 'Set budget' : 'Adjust'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (budget == null) ...[
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Set a monthly/period budget and we will track it for you.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // Progress bar with labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fmt.format(spent), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                          if (altFmt != null)
                            Builder(
                              builder: (context) {
                                final altSpent = altAmount(spent);
                                if (altSpent == null) return const SizedBox.shrink();
                                return Text(
                                  '~ ${altFmt.format(altSpent)}',
                                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                );
                              },
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'of ${fmt.format(budget.amount)}',
                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}% used',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: overBudget ? theme.colorScheme.error : theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: progress,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(overBudget ? theme.colorScheme.error : theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick stats row
                  Row(
                    children: [
                      Expanded(
                        child: _BudgetStatTile(
                          icon: Icons.event_note,
                          label: 'Planned',
                          value: fmt.format(state.reservedPlanned),
                          altValue: altText(state.reservedPlanned),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BudgetStatTile(
                          icon: Icons.account_balance_wallet,
                          label: 'Usable',
                          value: fmt.format(state.usableBudget),
                          altValue: altText(state.usableBudget),
                          highlight: state.usableBudget < 0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Future expenses section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text('Future expenses', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => _openPlannedExpenseSheet(context, budget.id),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  if (budget.plannedExpenses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No future expenses yet',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  else
                    Column(
                      children: budget.plannedExpenses.map((p) {
                        final categoryLabel = p.category == null ? null : _categoryLabel(p.category!, categoryLabels);
                        final altValue = altAmount(p.amount);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.push_pin, size: 18, color: theme.colorScheme.primary),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      Text(
                                        categoryLabel == null
                                            ? DateFormat.MMMd().format(p.dueDate)
                                            : '${DateFormat.MMMd().format(p.dueDate)} \u2022 $categoryLabel',
                                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      fmt.format(p.amount),
                                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    if (altValue != null && altFmt != null)
                                      Text(
                                        '~ ${altFmt.format(altValue)}',
                                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBudgetSheet(BuildContext context, Budget? existing) async {
    final result = await showModalBottomSheet<Budget>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetSheet(existing: existing),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(SaveBudget(result));
    }
  }

  Future<void> _openPlannedExpenseSheet(BuildContext context, String budgetId) async {
    final categoryCubit = context.read<CategoryCubit>();
    final result = await showModalBottomSheet<PlannedExpense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(value: categoryCubit, child: const PlannedExpenseSheet()),
    );
    if (result != null) {
      // ignore: use_build_context_synchronously
      context.read<ExpenseBloc>().add(AddPlannedExpense(budgetId: budgetId, expense: result));
    }
  }
}

class _BudgetStatTile extends StatelessWidget {
  const _BudgetStatTile({required this.icon, required this.label, required this.value, this.altValue, this.highlight = false});

  final IconData icon;
  final String label;
  final String value;
  final String? altValue;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? theme.colorScheme.errorContainer.withOpacity(0.3) : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight ? theme.colorScheme.error : null,
            ),
          ),
          if (altValue != null)
            Text(altValue!, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ExpenseQuickActions extends StatelessWidget {
  const _ExpenseQuickActions({required this.onViewAll, this.onScanReceipt});

  final VoidCallback onViewAll;
  final VoidCallback? onScanReceipt;

  @override
  Widget build(BuildContext context) {
    final showScan = AppConfig.enableReceiptScanning && onScanReceipt != null;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onViewAll,
            icon: const Icon(Icons.list_alt),
            label: const Text('All expenses'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (showScan) ...[
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: onScanReceipt!,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan receipt'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String emoji;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(color: color, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.state,
    required this.cards,
    required this.accounts,
    required this.categoryLabels,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final ExpenseState state;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;
  final Map<String, String> categoryLabels;
  final void Function(Expense expense) onEdit;
  final void Function(Expense expense) onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<CategoryCubit>().state.items;
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};

    if (state.expenses.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
              const SizedBox(height: 12),
              Text('No expenses yet', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                'Add your first expense to start seeing charts and trends.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final eurFmt = NumberFormat.simpleCurrency(name: AppConfig.baseCurrency);
    final inrFmt = NumberFormat.simpleCurrency(name: AppConfig.secondaryCurrency);
    final monthLabel = DateFormat.yMMM().format(state.focusMonth);
    final items = state.expenses.take(10).toList();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.receipt_long, color: theme.colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent expenses',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        'Latest 10 entries',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      monthLabel,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 6),
                    FilledButton.tonalIcon(
                      onPressed: onExport,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Export'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondaryFixedDim,
                        foregroundColor: theme.colorScheme.onSecondaryFixedVariant,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < items.length; i++) ...[
            InkWell(
              onTap: () => onEdit(items[i]),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.primaries[items[i].category.hashCode % Colors.primaries.length].withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          categoryEmojis[items[i].category] ?? '\ud83c\udff7\ufe0f',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_categoryLabel(items[i].category, categoryLabels)} - ${DateFormat.MMMd().format(items[i].date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          if (_sourceLabel(items[i]) != null)
                            Text(
                              _sourceLabel(items[i])!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _dualAmount(items[i], theme, eurFmt, inrFmt),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () => onEdit(items[i]),
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline, size: 18),
                              onPressed: () => onDelete(items[i]),
                              visualDensity: VisualDensity.compact,
                              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (i != items.length - 1) const Divider(height: 1),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _dualAmount(Expense expense, ThemeData theme, NumberFormat eurFmt, NumberFormat inrFmt) {
    final eur = _amountInEur(expense);
    final inr = AppConfig.enableSecondaryCurrency ? _amountInInr(expense, eur) : null;
    final lines = <Widget>[];

    if (eur != null) {
      lines.add(Text(eurFmt.format(eur), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)));
    }
    if (inr != null) {
      lines.add(Text(inrFmt.format(inr), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)));
    }
    if (lines.isEmpty) {
      final fallbackFmt = NumberFormat.simpleCurrency(name: state.displayCurrency);
      lines.add(
        Text(
          fallbackFmt.format(expense.amountForCurrency(state.displayCurrency)),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: lines);
  }

  double? _amountInEur(Expense expense) {
    if (expense.currency == AppConfig.baseCurrency) return expense.amount;
    if (expense.amountEur != null) return expense.amountEur;
    final rate = state.eurToInr;
    if (expense.currency == AppConfig.secondaryCurrency && rate != null && rate > 0) {
      return expense.amount / rate;
    }
    return null;
  }

  double? _amountInInr(Expense expense, double? eurAmount) {
    if (expense.currency == AppConfig.secondaryCurrency) return expense.amount;
    final rate = state.eurToInr;
    if (eurAmount != null && rate != null) return eurAmount * rate;
    return null;
  }

  String? _sourceLabel(Expense expense) {
    final type = expense.paymentSourceType.toLowerCase();
    if (type == 'cash') return null;
    if (type == 'card') {
      final card = cards.firstWhere(
        (c) => c.id == expense.paymentSourceId,
        orElse: () => CreditCard(
          id: expense.paymentSourceId ?? 'card',
          bankName: 'Card',
          cardNumber: expense.paymentSourceId ?? '',
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
      final digits = card.cardNumber.replaceAll(RegExp(r'\\D'), '');
      final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
      return 'Card ${card.bankName}${tail.isNotEmpty ? ' - $tail' : ''}';
    }
    if (type == 'account') {
      final acct = accounts.firstWhere(
        (a) => a.id == expense.paymentSourceId,
        orElse: () => AccountCredential(
          id: expense.paymentSourceId ?? 'account',
          bankName: expense.paymentSourceId ?? 'Account',
          username: '',
          password: '',
          lastUpdated: DateTime.now(),
        ),
      );
      return 'Account ${acct.bankName}';
    }
    if (type == 'wallet') {
      return 'Wallet ${expense.paymentSourceId ?? ''}'.trim();
    }
    return expense.paymentSourceType;
  }
}

class _SourceBreakdownCard extends StatefulWidget {
  const _SourceBreakdownCard({
    required this.expenses,
    required this.focusMonth,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
  });

  final List<Expense> expenses;
  final DateTime focusMonth;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;

  @override
  State<_SourceBreakdownCard> createState() => _SourceBreakdownCardState();
}

enum _SourceRange { month, year, all }

class _SourceBreakdownCardState extends State<_SourceBreakdownCard> {
  _SourceRange _range = _SourceRange.month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.tertiaryContainer;
    final onAccent = theme.colorScheme.onTertiaryContainer;
    final fmt = NumberFormat.simpleCurrency(name: widget.displayCurrency);
    final altCurrency = alternateCurrency(widget.displayCurrency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      return convertToAlternateCurrency(
        amount: value,
        currency: widget.displayCurrency,
        baseToSecondaryRate: widget.eurToInr,
        currencyToBaseRate: widget.budgetToEur,
      );
    }

    final filtered = _filtered(widget.expenses, widget.focusMonth, _range);
    final totals = <PaymentSourceKey, double>{};
    for (final e in filtered) {
      final type = (e.paymentSourceType.isNotEmpty ? e.paymentSourceType : 'cash').toLowerCase();
      final key = PaymentSourceKey(type: type, id: e.paymentSourceId ?? type);
      totals[key] = (totals[key] ?? 0) + amountInDisplayCurrency(e, widget.displayCurrency, widget.budgetToEur);
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      elevation: 0,
      color: accent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment sources',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onAccent),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final r in _SourceRange.values)
                      ChoiceChip(
                        label: Text(_labelForRange(r)),
                        selected: _range == r,
                        labelStyle: TextStyle(color: theme.colorScheme.onTertiaryFixedVariant),
                        selectedColor: theme.colorScheme.tertiaryFixedDim,
                        backgroundColor: theme.colorScheme.tertiaryFixedDim.withOpacity(0.75),
                        onSelected: (v) {
                          if (v) setState(() => _range = r);
                        },
                        avatarBorder: Border.all(color: Colors.white),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entries.isEmpty)
              Text('No expenses for the selected window', style: theme.textTheme.bodySmall?.copyWith(color: onAccent))
            else
              Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i != 0) Divider(height: 10, color: onAccent.withOpacity(0.2)),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: onAccent.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
                          child: Icon(_iconForSourceType(entries[i].key.type), color: onAccent),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _labelFor(entries[i].key),
                                style: TextStyle(fontWeight: FontWeight.w700, color: onAccent),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detailFor(entries[i].key),
                                style: theme.textTheme.bodySmall?.copyWith(color: onAccent.withOpacity(0.8)),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(entries[i].value),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: onAccent),
                            ),
                            if (altAmount(entries[i].value) != null && altFmt != null)
                              Text(
                                '~ ${altFmt.format(altAmount(entries[i].value))}',
                                style: theme.textTheme.bodySmall?.copyWith(color: onAccent.withOpacity(0.8)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Expense> _filtered(List<Expense> all, DateTime focusMonth, _SourceRange range) {
    if (range == _SourceRange.all) {
      return all.where((e) => e.transactionType != 'transfer').toList();
    }
    if (range == _SourceRange.year) {
      return all.where((e) => e.transactionType != 'transfer').where((e) => e.date.year == focusMonth.year).toList();
    }
    final start = DateTime(focusMonth.year, focusMonth.month, 1);
    final end = DateTime(focusMonth.year, focusMonth.month + 1, 0, 23, 59, 59, 999);
    return all
        .where((e) => e.transactionType != 'transfer')
        .where((e) => !e.date.isBefore(start) && !e.date.isAfter(end))
        .toList();
  }

  String _labelFor(PaymentSourceKey key) {
    if (key.type == 'card') {
      final card = widget.cards.firstWhere(
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
      final digits = card.cardNumber.replaceAll(RegExp(r'\\D'), '');
      final tail = digits.length >= 4 ? digits.substring(digits.length - 4) : '';
      return '${card.bankName}${tail.isNotEmpty ? ' - $tail' : ''}';
    }
    if (key.type == 'account') {
      final acct = widget.accounts.firstWhere(
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

  String _detailFor(PaymentSourceKey key) {
    switch (key.type) {
      case 'card':
        return 'Card spend';
      case 'account':
        return 'Bank transfer';
      case 'wallet':
        return 'Wallet / UPI';
      default:
        return 'Cash';
    }
  }

  String _labelForRange(_SourceRange r) {
    switch (r) {
      case _SourceRange.month:
        return 'This month';
      case _SourceRange.year:
        return 'This year';
      case _SourceRange.all:
        return 'All';
    }
  }
}

class _CardSpendPanel extends StatelessWidget {
  const _CardSpendPanel({required this.expenses, required this.displayCurrency, required this.cards, required this.eurToInr});

  final List<Expense> expenses;
  final String displayCurrency;
  final List<CreditCard> cards;
  final double? eurToInr;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cards.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Card spend', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 6),
              Text('Link a card to start tracking statement spend and dues.'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Per-card spend', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(Icons.schedule, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: 12),
            ...cards.map((card) {
              final cardCurrency = card.currency.isNotEmpty ? card.currency : displayCurrency;
              final fmt = NumberFormat.simpleCurrency(name: cardCurrency);
              final altCurrency = alternateCurrency(cardCurrency);
              final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
              final now = DateTime.now();
              final primary = computeCardBalance(expenses: expenses, card: card, currency: cardCurrency, now: now);
              double? altAmount(double value) {
                if (altFmt == null) return null;
                return convertToAlternateCurrency(amount: value, currency: cardCurrency, baseToSecondaryRate: eurToInr);
              }

              final outstanding = primary.totalBalance;
              final limit = card.usageLimit;
              final utilization = (limit != null && limit > 0) ? ((outstanding > 0 ? outstanding : 0) / limit) : null;
              final isOver = utilization != null && utilization >= 1;
              final nearing = utilization != null && utilization >= 0.9 && !isOver;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.credit_card, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(card.bankName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                'Stmt: ${DateFormat.MMMd().format(primary.window.start)} - ${DateFormat.MMMd().format(primary.window.end)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              fmt.format(outstanding),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            if (altAmount(outstanding) != null && altFmt != null)
                              Text('~ ${altFmt.format(altAmount(outstanding))}', style: theme.textTheme.bodySmall),
                            if (limit != null) ...[
                              Text('of ${fmt.format(limit)}', style: theme.textTheme.bodySmall),
                              if (altAmount(limit) != null && altFmt != null)
                                Text('~ ${altFmt.format(altAmount(limit))}', style: theme.textTheme.bodySmall),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _infoPill(theme, icon: Icons.event, label: 'Due ${DateFormat.MMMd().format(primary.window.due)}'),
                        _infoPill(theme, icon: Icons.receipt_long, label: 'Billing day ${card.billingDay}'),
                        _infoPill(
                          theme,
                          icon: Icons.description_outlined,
                          label: altAmount(primary.statementBalance) == null || altFmt == null
                              ? 'Statement ${fmt.format(primary.statementBalance)}'
                              : 'Statement ${fmt.format(primary.statementBalance)} (~ ${altFmt.format(altAmount(primary.statementBalance))})',
                        ),
                        _infoPill(
                          theme,
                          icon: Icons.swap_vert,
                          label: altAmount(primary.unbilledBalance) == null || altFmt == null
                              ? 'Unbilled ${fmt.format(primary.unbilledBalance)}'
                              : 'Unbilled ${fmt.format(primary.unbilledBalance)} (~ ${altFmt.format(altAmount(primary.unbilledBalance))})',
                        ),
                        if (card.reminderEnabled)
                          _infoPill(theme, icon: Icons.notifications_active, label: _reminderLabel(card), highlight: true),
                        if (utilization != null)
                          _infoPill(theme, icon: Icons.percent, label: 'Utilization ${(utilization * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                    if (limit != null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(6),
                        value: utilization != null ? utilization.clamp(0, 1) : 0,
                        backgroundColor: Colors.black.withOpacity(0.05),
                        color: isOver
                            ? Colors.redAccent
                            : nearing
                            ? Colors.orange
                            : theme.colorScheme.primary,
                      ),
                    ],
                    if (isOver || nearing) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: isOver ? Colors.redAccent : Colors.orange, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isOver ? 'Over the usage limit' : 'Nearing the usage limit',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isOver ? Colors.redAccent : Colors.orange,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _reminderLabel(CreditCard card) {
    if (!card.reminderEnabled) return '';
    if (card.reminderOffsets.isEmpty) return 'Reminder on due';
    final sorted = [...card.reminderOffsets]..sort();
    return 'Remind: ${sorted.map((d) => '${d}d').join(', ')}';
  }

  Widget _infoPill(ThemeData theme, {required IconData icon, required String label, bool highlight = false}) {
    final bg = highlight ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceVariant.withOpacity(0.5);
    final fg = highlight ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

int _daysInMonth(int year, int month) {
  final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}
