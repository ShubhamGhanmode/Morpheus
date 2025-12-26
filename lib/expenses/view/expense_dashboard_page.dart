import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/models/budget.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/planned_expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/view/widgets/budget_sheet.dart';
import 'package:morpheus/expenses/view/widgets/expense_form_sheet.dart';
import 'package:morpheus/expenses/view/widgets/planned_expense_sheet.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/utils/card_balances.dart';

class ExpenseDashboardPage extends StatelessWidget {
  const ExpenseDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ExpenseBloc(ExpenseRepository(), baseCurrency: baseCurrency)..add(const LoadExpenses())),
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
            NotificationService.instance.scheduleCardReminders(state.cards);
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
          onPressed: () => _openExpenseForm(context),
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
                  _BurnChart(state: state),
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
                    onViewAll: () => _openAllExpenses(context, state, cardState.cards, accountState.items),
                    onEdit: (expense) => _openExpenseForm(context, existing: expense),
                    onDelete: (expense) => _confirmDeleteExpense(context, expense),
                    onExport: () => _exportExpenses(context, state),
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
    final expenseBloc = context.read<ExpenseBloc>();
    final result = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: expenseBloc),
          BlocProvider.value(value: categoryCubit),
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
    }
  }

  Future<void> _openAllExpenses(
    BuildContext context,
    ExpenseState state,
    List<CreditCard> cards,
    List<AccountCredential> accounts,
  ) async {
    final categoryCubit = context.read<CategoryCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: categoryCubit,
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

  Future<void> _exportExpenses(BuildContext context, ExpenseState state) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );

    if (range == null) return;

    // Permissions check before writing to downloads/documents.
    if (Platform.isAndroid) {
      final ok = await _ensureAndroidStoragePermission(context);
      if (!ok) return;
    }

    final filtered = state.expenses.where((e) {
      return !e.date.isBefore(range.start) && !e.date.isAfter(range.end);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final buffer = StringBuffer();
    buffer.writeln('Expenses export (${DateFormat.yMMMd().format(range.start)} - ${DateFormat.yMMMd().format(range.end)})');
    buffer.writeln('Title,Amount,Currency,Category,Date,TransactionType,PaymentSourceType,PaymentSourceId,Note');
    for (final e in filtered) {
      buffer.writeln(
        '"${e.title.replaceAll('"', "'")}",'
        '${e.amount.toStringAsFixed(2)},'
        '${e.currency},'
        '${e.category},'
        '${DateFormat('yyyy-MM-dd').format(e.date)},'
        '${e.transactionType},'
        '${e.paymentSourceType},'
        '${e.paymentSourceId ?? '-'},'
        '"${(e.note ?? '').replaceAll('"', "'")}"',
      );
    }

    final budget = state.activeBudget;
    if (budget != null) {
      buffer.writeln('');
      buffer.writeln('Budget summary');
      buffer.writeln('Amount (${budget.currency}),Start,End,Reserved,Usable');
      buffer.writeln(
        '${budget.amount.toStringAsFixed(2)},${DateFormat('yyyy-MM-dd').format(budget.startDate)},${DateFormat('yyyy-MM-dd').format(budget.endDate)},${state.reservedPlanned.toStringAsFixed(2)},${state.usableBudget.toStringAsFixed(2)}',
      );

      if (budget.plannedExpenses.isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Future expenses');
        buffer.writeln('Title,Amount,Due,Category');
        for (final p in budget.plannedExpenses) {
          buffer.writeln(
            '"${p.title.replaceAll('"', "'")}",${p.amount.toStringAsFixed(2)},${DateFormat('yyyy-MM-dd').format(p.dueDate)},${p.category ?? '-'}',
          );
        }
      }
    }

    // Prefer Downloads on Android; Documents elsewhere.
    Directory baseDir;
    if (Platform.isAndroid) {
      // Force public Downloads so files are visible to user file managers.
      baseDir = Directory('/storage/emulated/0/Download');
      if (!await baseDir.exists()) {
        final candidates = await getExternalStorageDirectories(type: StorageDirectory.downloads);
        baseDir =
            (candidates?.isNotEmpty == true ? candidates!.first : await getExternalStorageDirectory()) ??
            await getApplicationDocumentsDirectory();
      }
    } else {
      baseDir = await getApplicationDocumentsDirectory();
    }

    final exportDir = Directory('${baseDir.path}/morpheus_exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(buffer.toString());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Exported ${filtered.length} expenses to ${file.path}')));
  }

  Future<bool> _ensureAndroidStoragePermission(BuildContext context) async {
    final manageStatus = await Permission.manageExternalStorage.request();
    if (manageStatus.isGranted) return true;

    final storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    if (!context.mounted) return false;
    final permanentlyDenied = storageStatus.isPermanentlyDenied || manageStatus.isPermanentlyDenied;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Storage permission denied. Please allow to export.'),
        action: permanentlyDenied ? SnackBarAction(label: 'Settings', onPressed: openAppSettings) : null,
      ),
    );
    return false;
  }
}

class _ForexBadge extends StatelessWidget {
  const _ForexBadge({required this.rate});

  final double? rate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = rate == null
        ? 'Fetching ${AppConfig.baseCurrency} to ${AppConfig.secondaryCurrency}...'
        : '${AppConfig.baseCurrency} to ${AppConfig.secondaryCurrency} today: ${rate!.toStringAsFixed(2)}';
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.currency_exchange, color: colorScheme.onPrimaryContainer, size: 18),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
            ),
          ],
        ),
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
    final altCurrency = _alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    double? altAmount() {
      if (altFmt == null) return null;
      if (currency == AppConfig.baseCurrency) {
        final rate = state.eurToInr;
        return rate != null ? usable * rate : null;
      }
      if (currency == AppConfig.secondaryCurrency) {
        final rate = budgetToEur ?? (state.eurToInr != null && state.eurToInr! > 0 ? 1 / state.eurToInr! : null);
        return rate != null ? usable * rate : null;
      }
      return null;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.account_balance_wallet, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Usable budget', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(range, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 10),
                  Text(
                    budget == null ? '-' : fmt.format(usable),
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (budget != null && altAmount() != null && altFmt != null)
                    Text(
                      '~ ${altFmt.format(altAmount())} today',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.state});

  final ExpenseState state;

  @override
  Widget build(BuildContext context) {
    final currency = state.displayCurrency;
    final altCurrency = _alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      if (currency == AppConfig.baseCurrency) {
        final rate = state.eurToInr;
        return rate != null ? value * rate : null;
      }
      if (currency == AppConfig.secondaryCurrency) {
        final rate = state.budgetToEur ?? (state.eurToInr != null && state.eurToInr! > 0 ? 1 / state.eurToInr! : null);
        return rate != null ? value * rate : null;
      }
      return null;
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: color.withOpacity(0.09),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            if (altValue != null)
              Text(
                altValue!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 2),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('6-month burn', style: Theme.of(context).textTheme.titleMedium),
            Divider(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2), thickness: 2),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 42)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= months.length) return const SizedBox.shrink();
                          return Text(DateFormat.MMM().format(months[index]), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                      color: Colors.indigo,
                      isCurved: true,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: Colors.indigo.withOpacity(0.15)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _amount(Expense expense) {
    if (expense.transactionType == 'transfer') return 0;
    return _amountForDisplay(expense, displayCurrency, budgetToEur);
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
    final items = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = items.fold<double>(0, (sum, e) => sum + e.value);

    if (items.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Category mix', style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 8),
              Text('Add expenses to see where your money goes.'),
            ],
          ),
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category mix', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    for (var i = 0; i < items.length; i++)
                      PieChartSectionData(
                        value: items[i].value,
                        title: '${((items[i].value / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.primaries[i % Colors.primaries.length],
                        radius: 70,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < items.length; i++)
                  Chip(
                    avatar: CircleAvatar(backgroundColor: Colors.primaries[i % Colors.primaries.length]),
                    label: Text('${_categoryLabel(items[i].key, categoryLabels)} - ${items[i].value.toStringAsFixed(0)}'),
                  ),
              ],
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
    final budget = state.activeBudget;
    final currency = budget?.currency ?? state.displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);
    final spent = state.monthlyTotal;
    final budgetToEur = state.budgetToEur ?? (currency == AppConfig.baseCurrency ? 1.0 : null);
    final altCurrency = _alternateCurrency(currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      if (currency == AppConfig.baseCurrency) {
        final rate = state.eurToInr;
        return rate != null ? value * rate : null;
      }
      if (currency == AppConfig.secondaryCurrency) {
        final rate = budgetToEur ?? (state.eurToInr != null && state.eurToInr! > 0 ? 1 / state.eurToInr! : null);
        return rate != null ? value * rate : null;
      }
      return null;
    }

    String? altText(double value) {
      final converted = altAmount(value);
      if (converted == null) return null;
      return '~ ${altFmt!.format(converted)}';
    }

    Widget amountChip(IconData icon, String label, double value) {
      final altValue = altText(value);
      return Chip(
        avatar: Icon(icon, size: 16),
        label: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label: ${fmt.format(value)}'),
            if (altValue != null)
              Text(
                altValue,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Budget planner', style: Theme.of(context).textTheme.titleMedium),
                FilledButton.icon(
                  onPressed: () => _openBudgetSheet(context, budget),
                  icon: const Icon(Icons.savings),
                  label: Text(budget == null ? 'Set budget' : 'Adjust'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (budget == null) ...[
              const Text('Set a monthly/period budget and we will track it for you.'),
            ] else ...[
              Text('${fmt.format(spent)} spent of ${fmt.format(budget.amount)}', style: Theme.of(context).textTheme.titleSmall),
              if (altFmt != null) ...[
                const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final altSpent = altAmount(spent);
                    final altBudget = altAmount(budget.amount);
                    if (altSpent == null || altBudget == null) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '~ ${altFmt.format(altSpent)} spent of ${altFmt.format(altBudget)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    );
                  },
                ),
              ],
              const SizedBox(height: 8),
              LinearProgressIndicator(
                minHeight: 8,
                borderRadius: BorderRadius.circular(5),
                value: (budget.amount == 0) ? 0 : (spent / budget.amount).clamp(0, 1),
                backgroundColor: Colors.grey.shade200,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text('${DateFormat.MMMd().format(budget.startDate)} - ${DateFormat.MMMd().format(budget.endDate)}'),
                  ),
                  amountChip(Icons.schedule, 'Planned', state.reservedPlanned),
                  amountChip(Icons.balance, 'Usable', state.usableBudget),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Future expenses', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: () => _openPlannedExpenseSheet(context, budget.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              if (budget.plannedExpenses.isEmpty)
                const Text('No future expenses yet')
              else
                Column(
                  children: budget.plannedExpenses.map((p) {
                    final categoryLabel = p.category == null ? null : _categoryLabel(p.category!, categoryLabels);
                    final altValue = altAmount(p.amount);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.push_pin),
                      title: Text(p.title),
                      subtitle: Text(
                        categoryLabel == null
                            ? DateFormat.MMMd().format(p.dueDate)
                            : '${DateFormat.MMMd().format(p.dueDate)} - $categoryLabel',
                      ),
                      trailing: altValue == null || altFmt == null
                          ? Text(fmt.format(p.amount))
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(fmt.format(p.amount)),
                                Text(
                                  '~ ${altFmt.format(altValue)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
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

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.state,
    required this.cards,
    required this.accounts,
    required this.categoryLabels,
    required this.onViewAll,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  final ExpenseState state;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;
  final Map<String, String> categoryLabels;
  final VoidCallback onViewAll;
  final void Function(Expense expense) onEdit;
  final void Function(Expense expense) onDelete;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    if (state.expenses.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text('No expenses yet'),
              const SizedBox(height: 8),
              Text(
                'Add your first expense to start seeing charts and trends.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final theme = Theme.of(context);
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
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.primaries[items[i].category.hashCode % Colors.primaries.length].withOpacity(0.15),
                      child: Icon(Icons.label, color: Colors.primaries[items[i].category.hashCode % Colors.primaries.length]),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: FilledButton.tonalIcon(
                onPressed: onViewAll,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                icon: const Icon(Icons.list_alt),
                label: const Text('View all expenses'),
              ),
            ),
          ),
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

class AllExpensesPage extends StatelessWidget {
  const AllExpensesPage({
    super.key,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
  });

  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (expenses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('All expenses')),
        body: Center(child: Text('No expenses yet', style: theme.textTheme.titleMedium)),
      );
    }

    final byYear = <int, List<Expense>>{};
    for (final e in expenses) {
      byYear.putIfAbsent(e.date.year, () => []).add(e);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('All expenses')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final year in years)
            _YearSection(
              year: year,
              expenses: byYear[year]!,
              displayCurrency: displayCurrency,
              budgetToEur: budgetToEur,
              eurToInr: eurToInr,
              cards: cards,
              accounts: accounts,
            ),
        ],
      ),
    );
  }
}

class _YearSection extends StatelessWidget {
  const _YearSection({
    required this.year,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
  });

  final int year;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryCubit = context.read<CategoryCubit>();
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final total = _totalFor(expenses, displayCurrency, budgetToEur);
    final categoryTotals = _categoryTotalsFor(expenses, displayCurrency, budgetToEur);
    final topCategory = _topEntry(categoryTotals);
    final byMonth = <int, List<Expense>>{};
    for (final e in expenses) {
      byMonth.putIfAbsent(e.date.month, () => []).add(e);
    }
    final months = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));
    final avgPerMonth = months.isEmpty ? 0.0 : total / months.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(year.toString(), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const Spacer(),
              FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BlocProvider.value(
                      value: categoryCubit,
                      child: _ExpenseAnalyticsPage.year(
                        year: year,
                        expenses: expenses,
                        displayCurrency: displayCurrency,
                        budgetToEur: budgetToEur,
                        eurToInr: eurToInr,
                        cards: cards,
                        accounts: accounts,
                      ),
                    ),
                  ),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text('View analytics'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Annual total', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(fmt.format(total), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(theme, Icons.receipt_long, '${expenses.length} expenses'),
                      _infoChip(theme, Icons.calendar_month, '${fmt.format(avgPerMonth)} avg/month'),
                      if (topCategory != null)
                        _infoChip(theme, Icons.category, '${_categoryLabelFromContext(context, topCategory.key)} top'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Monthly breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final month in months)
            _MonthCard(
              year: year,
              month: month,
              expenses: byMonth[month]!,
              displayCurrency: displayCurrency,
              budgetToEur: budgetToEur,
              eurToInr: eurToInr,
              cards: cards,
              accounts: accounts,
            ),
          const SizedBox(height: 16),
          Divider(color: theme.colorScheme.outlineVariant, thickness: 3, radius: BorderRadius.circular(5)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.year,
    required this.month,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
  });

  final int year;
  final int month;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryCubit = context.read<CategoryCubit>();
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final total = _totalFor(expenses, displayCurrency, budgetToEur);
    final categoryTotals = _categoryTotalsFor(expenses, displayCurrency, budgetToEur);
    final topCategory = _topEntry(categoryTotals);
    final monthLabel = DateFormat.MMMM().format(DateTime(year, month));

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final button = FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: categoryCubit,
                        child: _ExpenseAnalyticsPage.month(
                          year: year,
                          month: month,
                          expenses: expenses,
                          displayCurrency: displayCurrency,
                          budgetToEur: budgetToEur,
                          eurToInr: eurToInr,
                          cards: cards,
                          accounts: accounts,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.analytics_outlined, size: 18),
                  label: Text(compact ? 'Analysis' : 'View analysis'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                );

                if (!compact) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(monthLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              '${expenses.length} expenses',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(fmt.format(total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          if (topCategory != null)
                            Text(
                              '${_categoryLabelFromContext(context, topCategory.key)} top',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      button,
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(monthLabel, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(
                                '${expenses.length} expenses',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(fmt.format(total), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            if (topCategory != null)
                              Text(
                                '${_categoryLabelFromContext(context, topCategory.key)} top',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(alignment: Alignment.centerRight, child: button),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _AnalyticsScope { month, year }

class _ExpenseAnalyticsPage extends StatelessWidget {
  const _ExpenseAnalyticsPage._({
    required this.scope,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
    required this.year,
    this.month,
  });

  factory _ExpenseAnalyticsPage.month({
    required int year,
    required int month,
    required List<Expense> expenses,
    required String displayCurrency,
    required double? budgetToEur,
    required double? eurToInr,
    required List<CreditCard> cards,
    required List<AccountCredential> accounts,
  }) {
    return _ExpenseAnalyticsPage._(
      scope: _AnalyticsScope.month,
      year: year,
      month: month,
      expenses: expenses,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
      eurToInr: eurToInr,
      cards: cards,
      accounts: accounts,
    );
  }

  factory _ExpenseAnalyticsPage.year({
    required int year,
    required List<Expense> expenses,
    required String displayCurrency,
    required double? budgetToEur,
    required double? eurToInr,
    required List<CreditCard> cards,
    required List<AccountCredential> accounts,
  }) {
    return _ExpenseAnalyticsPage._(
      scope: _AnalyticsScope.year,
      year: year,
      expenses: expenses,
      displayCurrency: displayCurrency,
      budgetToEur: budgetToEur,
      eurToInr: eurToInr,
      cards: cards,
      accounts: accounts,
    );
  }

  final _AnalyticsScope scope;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;
  final int year;
  final int? month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final eurFmt = NumberFormat.simpleCurrency(name: AppConfig.baseCurrency);
    final inrFmt = NumberFormat.simpleCurrency(name: AppConfig.secondaryCurrency);

    final filtered = expenses.where((e) {
      if (e.transactionType == 'transfer') return false;
      if (e.date.year != year) return false;
      if (scope == _AnalyticsScope.month && e.date.month != month) return false;
      return true;
    }).toList();

    final total = _totalFor(filtered, displayCurrency, budgetToEur);
    final prevTotal = _previousTotal();
    final change = prevTotal == null ? null : total - prevTotal;
    final changePct = (prevTotal == null || prevTotal == 0) ? null : (change! / prevTotal);

    final categoryTotals = _categoryTotalsFor(filtered, displayCurrency, budgetToEur);
    final sourceTotals = _sourceTotalsFor(filtered, displayCurrency, budgetToEur);
    final topCategory = _topEntry(categoryTotals);
    final topSource = _topEntry(sourceTotals);
    final largest = _largestExpense(filtered);
    final categoryLabels = {for (final c in context.watch<CategoryCubit>().state.items) c.name: c.label};

    final totalEur = _sumInEur(filtered);
    final totalInr = _sumInInr(filtered);

    final periodLabel = scope == _AnalyticsScope.month ? DateFormat.yMMMM().format(DateTime(year, month ?? 1)) : year.toString();

    return Scaffold(
      appBar: AppBar(title: Text(scope == _AnalyticsScope.month ? 'Monthly analytics' : 'Annual analytics')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            elevation: 0,
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fmt.format(total),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (totalEur != null)
                        Text(
                          eurFmt.format(totalEur),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      if (totalInr != null)
                        Text(
                          inrFmt.format(totalInr),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (changePct != null)
                    Row(
                      children: [
                        Icon(
                          change! >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${(changePct * 100).abs().toStringAsFixed(1)}% ${change >= 0 ? 'higher' : 'lower'} than previous',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _metricChip(theme, Icons.receipt_long, '${filtered.length} expenses'),
                  _metricChip(
                    theme,
                    Icons.calendar_today,
                    scope == _AnalyticsScope.month
                        ? '${_avgPerDay(total).toStringAsFixed(1)} / day'
                        : '${_avgPerMonth(total).toStringAsFixed(1)} / month',
                  ),
                  if (largest != null)
                    _metricChip(
                      theme,
                      Icons.local_fire_department,
                      '${largest.title} (${fmt.format(_amountForDisplay(largest, displayCurrency, budgetToEur))})',
                    ),
                  if (topCategory != null)
                    _metricChip(theme, Icons.category, '${_categoryLabelFromContext(context, topCategory.key)} top'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildTrendChart(theme, filtered),
          const SizedBox(height: 12),
          _buildCategoryMix(theme, categoryTotals, categoryLabels),
          const SizedBox(height: 12),
          _buildSources(theme, sourceTotals, fmt),
          const SizedBox(height: 12),
          _buildInsights(context, theme, fmt, topCategory, topSource, largest, filtered),
        ],
      ),
    );
  }

  double? _previousTotal() {
    if (scope == _AnalyticsScope.month) {
      final prev = DateTime(year, (month ?? 1) - 1, 1);
      final list = expenses.where((e) => e.date.year == prev.year && e.date.month == prev.month).toList();
      return list.isEmpty ? null : _totalFor(list, displayCurrency, budgetToEur);
    }
    final list = expenses.where((e) => e.date.year == year - 1).toList();
    return list.isEmpty ? null : _totalFor(list, displayCurrency, budgetToEur);
  }

  double _avgPerDay(double total) {
    if (scope != _AnalyticsScope.month) return total / 30;
    final days = _daysInMonth(year, month ?? 1);
    return days == 0 ? 0 : total / days;
  }

  double _avgPerMonth(double total) {
    return total / 12;
  }

  Expense? _largestExpense(List<Expense> list) {
    if (list.isEmpty) return null;
    Expense? largest;
    double max = -1;
    for (final e in list) {
      final amount = _amountForDisplay(e, displayCurrency, budgetToEur);
      if (amount > max) {
        max = amount;
        largest = e;
      }
    }
    return largest;
  }

  double? _sumInEur(List<Expense> list) {
    double sum = 0;
    var has = false;
    for (final e in list) {
      final eur = _expenseAmountEur(e, eurToInr);
      if (eur != null) {
        sum += eur;
        has = true;
      }
    }
    return has ? sum : null;
  }

  double? _sumInInr(List<Expense> list) {
    double sum = 0;
    var has = false;
    for (final e in list) {
      final inr = _expenseAmountInr(e, eurToInr);
      if (inr != null) {
        sum += inr;
        has = true;
      }
    }
    return has ? sum : null;
  }

  Widget _metricChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTrendChart(ThemeData theme, List<Expense> list) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scope == _AnalyticsScope.month ? 'Daily trend' : 'Monthly trend',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: scope == _AnalyticsScope.month ? _buildDailyLineChart(theme, list) : _buildMonthlyBarChart(theme, list),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLineChart(ThemeData theme, List<Expense> list) {
    final days = _daysInMonth(year, month ?? 1);
    final totals = List<double>.filled(days, 0);
    for (final e in list) {
      final day = e.date.day;
      if (day >= 1 && day <= days) {
        totals[day - 1] += _amountForDisplay(e, displayCurrency, budgetToEur);
      }
    }
    final maxY = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);
    return LineChart(
      LineChartData(
        minX: 1,
        maxX: days.toDouble(),
        minY: 0,
        maxY: maxY + 10,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5,
              getTitlesWidget: (value, meta) {
                if (value % 5 != 0) return const SizedBox.shrink();
                return Text(value.toInt().toString(), style: theme.textTheme.bodySmall);
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < totals.length; i++) FlSpot((i + 1).toDouble(), totals[i])],
            isCurved: true,
            barWidth: 3,
            color: theme.colorScheme.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: theme.colorScheme.primary.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBarChart(ThemeData theme, List<Expense> list) {
    final totals = List<double>.filled(12, 0);
    for (final e in list) {
      totals[e.date.month - 1] += _amountForDisplay(e, displayCurrency, budgetToEur);
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 11) return const SizedBox.shrink();
                return Text(DateFormat.MMM().format(DateTime(year, index + 1)), style: theme.textTheme.bodySmall);
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < totals.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: totals[i],
                  color: theme.colorScheme.primary,
                  width: 10,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryMix(ThemeData theme, Map<String, double> totals, Map<String, String> categoryLabels) {
    if (totals.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(padding: EdgeInsets.all(16), child: Text('No category data yet')),
      );
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category mix', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: [
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value,
                        title: '${((entries[i].value / total) * 100).toStringAsFixed(0)}%',
                        color: Colors.primaries[i % Colors.primaries.length],
                        radius: 70,
                        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (var i = 0; i < entries.length; i++)
                  Chip(
                    avatar: CircleAvatar(backgroundColor: Colors.primaries[i % Colors.primaries.length]),
                    label: Text('${_categoryLabel(entries[i].key, categoryLabels)} - ${entries[i].value.toStringAsFixed(0)}'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSources(ThemeData theme, Map<_SourceKey, double> totals, NumberFormat fmt) {
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top payment sources', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            for (final entry in entries.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(_iconForSourceType(entry.key.type), color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _labelForSourceKey(entry.key, cards, accounts),
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(fmt.format(entry.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsights(
    BuildContext context,
    ThemeData theme,
    NumberFormat fmt,
    MapEntry<String, double>? topCategory,
    MapEntry<_SourceKey, double>? topSource,
    Expense? largest,
    List<Expense> list,
  ) {
    final insights = <String>[];
    if (topCategory != null) {
      insights.add('Most spend was on ${_categoryLabelFromContext(context, topCategory.key)}.');
    }
    if (topSource != null) {
      insights.add('Top source: ${_labelForSourceKey(topSource.key, cards, accounts)}.');
    }
    if (largest != null) {
      insights.add(
        'Largest purchase: ${largest.title} at ${fmt.format(_amountForDisplay(largest, displayCurrency, budgetToEur))}.',
      );
    }
    if (scope == _AnalyticsScope.month) {
      final dayTotals = <int, double>{};
      for (final e in list) {
        dayTotals[e.date.day] = (dayTotals[e.date.day] ?? 0) + _amountForDisplay(e, displayCurrency, budgetToEur);
      }
      final busiest = _topEntry(dayTotals);
      if (busiest != null) {
        insights.add('Busiest day: ${DateFormat.MMMd().format(DateTime(year, month ?? 1, busiest.key))}.');
      }
    } else {
      final monthTotals = <int, double>{};
      for (final e in list) {
        monthTotals[e.date.month] = (monthTotals[e.date.month] ?? 0) + _amountForDisplay(e, displayCurrency, budgetToEur);
      }
      final peak = _topEntry(monthTotals);
      if (peak != null) {
        insights.add('Peak month: ${DateFormat.MMMM().format(DateTime(year, peak.key))}.');
      }
    }

    if (insights.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      color: theme.colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            for (final line in insights)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.star, size: 16, color: theme.colorScheme.onSecondaryContainer),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
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

double _amountForDisplay(Expense expense, String displayCurrency, double? budgetToEur) {
  final converted = expense.amountForCurrency(displayCurrency);
  if (displayCurrency == expense.currency) return converted;
  if (displayCurrency == AppConfig.baseCurrency && expense.amountEur != null) {
    return expense.amountEur!;
  }
  if (converted != expense.amount) return converted;
  if (displayCurrency == expense.budgetCurrency && expense.amountInBudgetCurrency != null) {
    return expense.amountInBudgetCurrency!;
  }
  if (budgetToEur != null && budgetToEur > 0 && expense.amountEur != null && displayCurrency != AppConfig.baseCurrency) {
    return expense.amountEur! / budgetToEur;
  }
  return converted;
}

double _totalFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  return expenses.fold(0, (sum, e) {
    if (e.transactionType == 'transfer') return sum;
    return sum + _amountForDisplay(e, displayCurrency, budgetToEur);
  });
}

Map<String, double> _categoryTotalsFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  final totals = <String, double>{};
  for (final e in expenses) {
    if (e.transactionType == 'transfer') continue;
    final amount = _amountForDisplay(e, displayCurrency, budgetToEur);
    totals[e.category] = (totals[e.category] ?? 0) + amount;
  }
  return totals;
}

Map<_SourceKey, double> _sourceTotalsFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  final totals = <_SourceKey, double>{};
  for (final e in expenses) {
    if (e.transactionType == 'transfer') continue;
    final amount = _amountForDisplay(e, displayCurrency, budgetToEur);
    final key = _sourceKeyForExpense(e);
    totals[key] = (totals[key] ?? 0) + amount;
  }
  return totals;
}

MapEntry<K, V>? _topEntry<K, V extends num>(Map<K, V> map) {
  if (map.isEmpty) return null;
  return map.entries.reduce((a, b) => a.value > b.value ? a : b);
}

String _categoryLabel(String name, Map<String, String> labels) {
  final label = labels[name];
  return label == null || label.isEmpty ? name : label;
}

String _categoryLabelFromContext(BuildContext context, String name) {
  final labels = {for (final c in context.watch<CategoryCubit>().state.items) c.name: c.label};
  return _categoryLabel(name, labels);
}

String? _alternateCurrency(String currency) {
  if (!AppConfig.enableSecondaryCurrency) return null;
  if (currency == AppConfig.baseCurrency) return AppConfig.secondaryCurrency;
  if (currency == AppConfig.secondaryCurrency) return AppConfig.baseCurrency;
  return null;
}

_SourceKey _sourceKeyForExpense(Expense expense) {
  final type = (expense.paymentSourceType.isNotEmpty ? expense.paymentSourceType : 'cash').toLowerCase();
  return _SourceKey(type: type, id: expense.paymentSourceId ?? type);
}

double? _expenseAmountEur(Expense expense, double? eurToInr) {
  if (expense.currency == AppConfig.baseCurrency) return expense.amount;
  if (expense.amountEur != null) return expense.amountEur;
  if (expense.currency == AppConfig.secondaryCurrency && eurToInr != null && eurToInr > 0) {
    return expense.amount / eurToInr;
  }
  return null;
}

double? _expenseAmountInr(Expense expense, double? eurToInr) {
  if (expense.currency == AppConfig.secondaryCurrency) return expense.amount;
  final eur = _expenseAmountEur(expense, eurToInr);
  if (eur != null && eurToInr != null) return eur * eurToInr;
  return null;
}

String _labelForSourceKey(_SourceKey key, List<CreditCard> cards, List<AccountCredential> accounts) {
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
    final digits = card.cardNumber.replaceAll(RegExp(r'\\D'), '');
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

IconData _iconForSourceType(String type) {
  switch (type) {
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
    final altCurrency = _alternateCurrency(widget.displayCurrency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    double? altAmount(double value) {
      if (altFmt == null) return null;
      if (widget.displayCurrency == AppConfig.baseCurrency) {
        final rate = widget.eurToInr;
        return rate != null ? value * rate : null;
      }
      if (widget.displayCurrency == AppConfig.secondaryCurrency) {
        final rate = widget.budgetToEur ?? (widget.eurToInr != null && widget.eurToInr! > 0 ? 1 / widget.eurToInr! : null);
        return rate != null ? value * rate : null;
      }
      return null;
    }

    final filtered = _filtered(widget.expenses, widget.focusMonth, _range);
    final totals = <_SourceKey, double>{};
    for (final e in filtered) {
      final type = (e.paymentSourceType.isNotEmpty ? e.paymentSourceType : 'cash').toLowerCase();
      final key = _SourceKey(type: type, id: e.paymentSourceId ?? type);
      totals[key] = (totals[key] ?? 0) + _amountForDisplay(e, widget.displayCurrency, widget.budgetToEur);
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

  String _labelFor(_SourceKey key) {
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

  String _detailFor(_SourceKey key) {
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

class _SourceKey {
  const _SourceKey({required this.type, required this.id});

  final String type;
  final String id;

  @override
  bool operator ==(Object other) {
    return other is _SourceKey && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
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
              final altCurrency = _alternateCurrency(cardCurrency);
              final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
              final now = DateTime.now();
              final primary = computeCardBalance(expenses: expenses, card: card, currency: cardCurrency, now: now);
              double? altAmount(double value) {
                if (altFmt == null) return null;
                if (cardCurrency == AppConfig.baseCurrency) {
                  return eurToInr != null ? value * eurToInr! : null;
                }
                if (cardCurrency == AppConfig.secondaryCurrency) {
                  if (eurToInr == null || eurToInr == 0) return null;
                  return value / eurToInr!;
                }
                return null;
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
