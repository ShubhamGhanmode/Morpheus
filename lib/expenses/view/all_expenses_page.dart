part of 'expense_dashboard_page.dart';

class AllExpensesPage extends StatelessWidget {
  AllExpensesPage({
    super.key,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.eurToInr,
    required this.cards,
    required this.accounts,
    ExpenseRepository? repository,
  }) : repository = repository ?? ExpenseRepository();

  final ExpenseRepository repository;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;

  void _openSearch(BuildContext context) {
    final categoryCubit = context.read<CategoryCubit>();
    final expenseBloc = context.read<ExpenseBloc>();
    final cardCubit = context.read<CardCubit>();
    final accountsCubit = context.read<AccountsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: expenseBloc),
            BlocProvider.value(value: cardCubit),
            BlocProvider.value(value: accountsCubit),
            BlocProvider.value(value: categoryCubit),
          ],
          child: const ExpenseSearchPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final byYear = <int, List<Expense>>{};
    for (final e in expenses) {
      byYear.putIfAbsent(e.date.year, () => []).add(e);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All expenses'),
        actions: [IconButton(tooltip: 'Search expenses', icon: const Icon(Icons.search), onPressed: () => _openSearch(context))],
      ),
      body: StreamBuilder<List<ExpenseGroup>>(
        stream: repository.streamGroups(),
        builder: (context, snapshot) {
          final groups = snapshot.data ?? const <ExpenseGroup>[];
          final groupMap = {for (final g in groups) g.id: g};
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              SearchBar(
                readOnly: true,
                onTap: () => _openSearch(context),
                hintText: 'Search expenses',
                leading: const Icon(Icons.search),
                trailing: const [Icon(Icons.arrow_forward, size: 18)],
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to search with filters and query syntax.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (expenses.isEmpty)
                Text('No expenses yet', style: theme.textTheme.titleMedium)
              else
                for (final year in years)
                  _YearSection(
                    year: year,
                    expenses: byYear[year]!,
                    displayCurrency: displayCurrency,
                    budgetToEur: budgetToEur,
                    eurToInr: eurToInr,
                    cards: cards,
                    accounts: accounts,
                    groups: groupMap,
                  ),
            ],
          );
        },
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
    required this.groups,
  });

  final int year;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;
  final Map<String, ExpenseGroup> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryCubit = context.read<CategoryCubit>();
    final categories = categoryCubit.state.items;
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final total = _totalFor(expenses, displayCurrency, budgetToEur);
    final categoryTotals = _categoryTotalsFor(expenses, displayCurrency, budgetToEur);
    final topCategory = _topEntry(categoryTotals);
    final topCategoryEmoji = topCategory != null ? (categoryEmojis[topCategory.key] ?? '\ud83c\udff7\ufe0f') : '';
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.tertiaryFixedDim]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  year.toString(),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary),
                ),
              ),
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
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer.withOpacity(0.6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Annual total',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    fmt.format(total),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _enhancedInfoChip(theme, Icons.receipt_long, '${expenses.length}', 'expenses'),
                      _enhancedInfoChip(theme, Icons.calendar_month, fmt.format(avgPerMonth), 'avg/mo'),
                      if (topCategory != null)
                        _enhancedInfoChip(
                          theme,
                          null,
                          topCategoryEmoji,
                          _categoryLabelFromContext(context, topCategory.key),
                          isEmoji: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('Monthly breakdown', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
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
              groups: groups,
            ),
          const SizedBox(height: 16),
          Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.outline.withOpacity(0.1),
                  theme.colorScheme.outline.withOpacity(0.3),
                  theme.colorScheme.outline.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _enhancedInfoChip(ThemeData theme, IconData? icon, String value, String label, {bool isEmoji = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEmoji)
            Text(value, style: const TextStyle(fontSize: 16))
          else if (icon != null)
            Icon(icon, size: 16, color: theme.colorScheme.primary),
          if (!isEmoji) ...[
            const SizedBox(width: 6),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
            ),
          ],
          const SizedBox(width: 4),
          Text(removeEmojis(label), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
    required this.groups,
  });

  final int year;
  final int month;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final double? eurToInr;
  final List<CreditCard> cards;
  final List<AccountCredential> accounts;
  final Map<String, ExpenseGroup> groups;

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
                final viewButton = FilledButton.tonalIcon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: categoryCubit,
                        child: _MonthExpensesPage(
                          year: year,
                          month: month,
                          expenses: expenses,
                          groups: groups,
                          displayCurrency: displayCurrency,
                          budgetToEur: budgetToEur,
                        ),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: Text(compact ? 'Expenses' : 'View expenses'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                );
                final analysisButton = FilledButton.tonalIcon(
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
                      Row(mainAxisSize: MainAxisSize.min, children: [viewButton, const SizedBox(width: 8), analysisButton]),
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(spacing: 8, runSpacing: 6, children: [viewButton, analysisButton]),
                    ),
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

class _MonthExpensesPage extends StatelessWidget {
  const _MonthExpensesPage({
    required this.year,
    required this.month,
    required this.expenses,
    required this.groups,
    required this.displayCurrency,
    required this.budgetToEur,
  });

  final int year;
  final int month;
  final List<Expense> expenses;
  final Map<String, ExpenseGroup> groups;
  final String displayCurrency;
  final double? budgetToEur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = context.watch<CategoryCubit>().state.items;
    final categoryLabels = {for (final c in categories) c.name: c.label};
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};
    final monthLabel = DateFormat.MMMM('en_US').format(DateTime(year, month));
    final fullLabel = DateFormat.yMMMM().format(DateTime(year, month));
    final sorted = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    final total = _totalFor(sorted, displayCurrency, budgetToEur);
    final categoryTotals = _categoryTotalsFor(sorted, displayCurrency, budgetToEur);
    final topCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);

    if (sorted.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(fullLabel)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.3), shape: BoxShape.circle),
                child: Icon(Icons.receipt_long_outlined, size: 56, color: theme.colorScheme.primary.withOpacity(0.7)),
              ),
              const SizedBox(height: 24),
              Text(
                'No expenses in $monthLabel',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking by adding your first expense',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<Expense>>{};
    for (final expense in sorted) {
      final groupId = expense.groupId;
      if (groupId == null || groupId.trim().isEmpty) continue;
      grouped.putIfAbsent(groupId, () => []).add(expense);
    }

    // Group by date for section headers
    final byDate = <DateTime, List<_ExpenseOrGroup>>{};
    final seenGroups = <String>{};

    for (final expense in sorted) {
      final dateKey = DateTime(expense.date.year, expense.date.month, expense.date.day);
      byDate.putIfAbsent(dateKey, () => []);

      final groupId = expense.groupId;
      if (groupId != null && groupId.trim().isNotEmpty) {
        final items = grouped[groupId] ?? const [];
        if (items.length > 1) {
          if (seenGroups.add(groupId)) {
            byDate[dateKey]!.add(_ExpenseOrGroup.group(groupId, items, groups[groupId]));
          }
          continue;
        }
      }
      byDate[dateKey]!.add(_ExpenseOrGroup.expense(expense));
    }

    final dates = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(fullLabel), centerTitle: false),
      body: CustomScrollView(
        slivers: [
          // Summary Header Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _MonthSummaryCard(
                theme: theme,
                monthLabel: monthLabel,
                year: year,
                total: total,
                expenseCount: sorted.length,
                topCategories: topCategories.take(3).toList(),
                categoryLabels: categoryLabels,
                categoryEmojis: categoryEmojis,
                fmt: fmt,
              ),
            ),
          ),

          // Expenses by date
          for (final date in dates) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _DateHeader(date: date, theme: theme),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = byDate[date]![index];
                  if (item.isGroup) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ExpenseGroupCard(
                        group: item.groupData,
                        expenses: item.groupExpenses!,
                        displayCurrency: displayCurrency,
                        budgetToEur: budgetToEur,
                        categoryLabels: categoryLabels,
                        categoryEmojis: categoryEmojis,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _EnhancedExpenseCard(
                      expense: item.expense!,
                      displayCurrency: displayCurrency,
                      budgetToEur: budgetToEur,
                      categoryLabels: categoryLabels,
                      categoryEmojis: categoryEmojis,
                    ),
                  );
                }, childCount: byDate[date]!.length),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ExpenseOrGroup {
  final Expense? expense;
  final String? groupId;
  final List<Expense>? groupExpenses;
  final ExpenseGroup? groupData;

  _ExpenseOrGroup.expense(this.expense) : groupId = null, groupExpenses = null, groupData = null;

  _ExpenseOrGroup.group(this.groupId, this.groupExpenses, this.groupData) : expense = null;

  bool get isGroup => groupId != null;
}

class _MonthSummaryCard extends StatelessWidget {
  const _MonthSummaryCard({
    required this.theme,
    required this.monthLabel,
    required this.year,
    required this.total,
    required this.expenseCount,
    required this.topCategories,
    required this.categoryLabels,
    required this.categoryEmojis,
    required this.fmt,
  });

  final ThemeData theme;
  final String monthLabel;
  final int year;
  final double total;
  final int expenseCount;
  final List<MapEntry<String, double>> topCategories;
  final Map<String, String> categoryLabels;
  final Map<String, String> categoryEmojis;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$monthLabel $year',
                    style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onPrimaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_outlined, size: 14, color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Text(
                        '$expenseCount',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Spent',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fmt.format(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
                letterSpacing: -0.5,
              ),
            ),
            if (topCategories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Categories',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: topCategories.map((entry) {
                        final emoji = categoryEmojis[entry.key] ?? '';
                        final label = categoryLabels[entry.key] ?? entry.key;
                        final displayLabel = emoji.isNotEmpty ? '$emoji $label' : label;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$displayLabel · ${fmt.format(entry.value)}',
                            style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.theme});

  final DateTime date;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (date == today) {
      label = 'Today';
    } else if (date == yesterday) {
      label = 'Yesterday';
    } else {
      label = DateFormat.MMMEd().format(date);
    }

    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _EnhancedExpenseCard extends StatelessWidget {
  const _EnhancedExpenseCard({
    required this.expense,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.categoryLabels,
    required this.categoryEmojis,
  });

  final Expense expense;
  final String displayCurrency;
  final double? budgetToEur;
  final Map<String, String> categoryLabels;
  final Map<String, String> categoryEmojis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
    final isNegative = amount < 0;
    final emoji = categoryEmojis[expense.category] ?? '';
    final categoryLabel = categoryLabels[expense.category] ?? expense.category;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // Future: Open expense detail/edit sheet
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Category Emoji Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(emoji.isNotEmpty ? emoji : '💰', style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 14),
              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(categoryLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(amount.abs()),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isNegative ? theme.colorScheme.tertiary : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (isNegative)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Credit',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpenseGroupCard extends StatelessWidget {
  const ExpenseGroupCard({
    super.key,
    required this.group,
    required this.expenses,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.categoryLabels,
    this.categoryEmojis = const {},
  });

  final ExpenseGroup? group;
  final List<Expense> expenses;
  final String displayCurrency;
  final double? budgetToEur;
  final Map<String, String> categoryLabels;
  final Map<String, String> categoryEmojis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupName = group?.name ?? 'Receipt group';
    final itemCount = group?.itemCount ?? expenses.length;
    final receiptUri = group?.receiptImageUri;
    final hasReceipt = receiptUri != null && receiptUri.isNotEmpty;
    final storedTotal = group?.totalAmount;
    final storedCurrency = group?.currency;
    final total = (storedTotal != null && storedCurrency != null)
        ? storedTotal
        : expenses.fold<double>(0, (sum, e) => sum + amountInDisplayCurrency(e, displayCurrency, budgetToEur));
    final totalCurrency = (storedTotal != null && storedCurrency != null) ? storedCurrency : displayCurrency;
    final fmt = NumberFormat.simpleCurrency(name: totalCurrency);
    final receiptDate = group?.receiptDate;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5), width: 1),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          childrenPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.6)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long, color: theme.colorScheme.primary, size: 24),
          ),
          title: Text(
            groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _InfoPill(icon: Icons.shopping_bag_outlined, label: '$itemCount items', theme: theme),
                if (receiptDate != null)
                  _InfoPill(icon: Icons.calendar_today_outlined, label: DateFormat.MMMd().format(receiptDate), theme: theme),
                if (hasReceipt) _InfoPill(icon: Icons.image_outlined, label: 'Receipt', theme: theme, highlighted: true),
              ],
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(10)),
            child: Text(
              fmt.format(total),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < expenses.length; i++) ...[
                    _GroupedExpenseItem(
                      expense: expenses[i],
                      displayCurrency: displayCurrency,
                      budgetToEur: budgetToEur,
                      categoryLabels: categoryLabels,
                      categoryEmojis: categoryEmojis,
                    ),
                    if (i != expenses.length - 1)
                      Divider(height: 1, indent: 52, color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.theme, this.highlighted = false});

  final IconData icon;
  final String label;
  final ThemeData theme;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.tertiaryContainer.withOpacity(0.5)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: highlighted ? theme.colorScheme.tertiary : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: highlighted ? theme.colorScheme.onTertiaryContainer : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedExpenseItem extends StatelessWidget {
  const _GroupedExpenseItem({
    required this.expense,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.categoryLabels,
    required this.categoryEmojis,
  });

  final Expense expense;
  final String displayCurrency;
  final double? budgetToEur;
  final Map<String, String> categoryLabels;
  final Map<String, String> categoryEmojis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
    final emoji = categoryEmojis[expense.category] ?? '';
    final categoryLabel = categoryLabels[expense.category] ?? expense.category;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(emoji.isNotEmpty ? emoji : '💰', style: const TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(categoryLabel, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(fmt.format(amount), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class GroupedExpenseTile extends StatelessWidget {
  const GroupedExpenseTile({
    super.key,
    required this.expense,
    required this.displayCurrency,
    required this.budgetToEur,
    required this.categoryLabels,
    this.compact = false,
  });

  final Expense expense;
  final String displayCurrency;
  final double? budgetToEur;
  final Map<String, String> categoryLabels;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
    final amount = amountInDisplayCurrency(expense, displayCurrency, budgetToEur);
    final subtitle = '${_categoryLabel(expense.category, categoryLabels)} - ${DateFormat.MMMd().format(expense.date)}';

    return ListTile(
      dense: compact,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16, vertical: compact ? 0 : 4),
      title: Text(
        expense.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(fmt.format(amount), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
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

    final categories = context.watch<CategoryCubit>().state.items;
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};
    final topCategoryEmoji = topCategory != null ? (categoryEmojis[topCategory.key] ?? '\ud83c\udff7\ufe0f') : '';

    return Scaffold(
      appBar: AppBar(title: Text(scope == _AnalyticsScope.month ? 'Monthly analytics' : 'Annual analytics'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Enhanced gradient header card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.tertiaryFixed],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          periodLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (changePct != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: change! >= 0 ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                change >= 0 ? Icons.trending_up : Icons.trending_down,
                                color: theme.colorScheme.onPrimary,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${(changePct * 100).abs().toStringAsFixed(1)}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Spent',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(total),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  if (totalEur != null || totalInr != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        if (totalEur != null)
                          Text(
                            '\u2248 ${eurFmt.format(totalEur)}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.75)),
                          ),
                        if (totalInr != null)
                          Text(
                            '\u2248 ${inrFmt.format(totalInr)}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.75)),
                          ),
                      ],
                    ),
                  ],
                  if (changePct != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      '${change! >= 0 ? 'Higher' : 'Lower'} than previous ${scope == _AnalyticsScope.month ? 'month' : 'year'}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withOpacity(0.7)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Enhanced quick stats row
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  Icons.receipt_long,
                  '${filtered.length}',
                  'Expenses',
                  theme.colorScheme.primaryContainer,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickStatCard(
                  theme,
                  Icons.calendar_today,
                  scope == _AnalyticsScope.month ? fmt.format(_avgPerDay(total)) : fmt.format(_avgPerMonth(total)),
                  scope == _AnalyticsScope.month ? 'Per day' : 'Per month',
                  theme.colorScheme.secondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (topCategory != null)
                Expanded(
                  child: _buildQuickStatCard(
                    theme,
                    Icons.keyboard_double_arrow_up,
                    _categoryLabelFromContext(context, topCategory.key),
                    'Top category',
                    theme.colorScheme.tertiaryContainer,
                  ),
                ),
              if (topCategory != null && largest != null) const SizedBox(width: 10),
              if (largest != null)
                Expanded(
                  child: _buildQuickStatCard(
                    theme,
                    Icons.local_fire_department,
                    fmt.format(amountInDisplayCurrency(largest, displayCurrency, budgetToEur)),
                    'Biggest expense',
                    theme.colorScheme.errorContainer.withOpacity(0.6),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTrendChart(theme, filtered),
          const SizedBox(height: 16),
          _buildCategoryMix(theme, categoryTotals, categoryLabels, categoryEmojis),
          const SizedBox(height: 16),
          _buildSources(theme, sourceTotals, fmt),
          const SizedBox(height: 16),
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
      final amount = amountInDisplayCurrency(e, displayCurrency, budgetToEur);
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
      final eur = expenseAmountInBaseCurrency(e, eurToInr);
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
      final inr = expenseAmountInSecondaryCurrency(e, eurToInr);
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

  Widget _buildQuickStatCard(ThemeData theme, IconData icon, String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.onSurface.withOpacity(0.7)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildQuickStatCardEmoji(ThemeData theme, String emoji, String value, String label, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 24, color: Colors.black.withOpacity(0.6))),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
        totals[day - 1] += amountInDisplayCurrency(e, displayCurrency, budgetToEur);
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
      totals[e.date.month - 1] += amountInDisplayCurrency(e, displayCurrency, budgetToEur);
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

  Widget _buildCategoryMix(
    ThemeData theme,
    Map<String, double> totals,
    Map<String, String> categoryLabels,
    Map<String, String> categoryEmojis,
  ) {
    if (totals.isEmpty) {
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
            ],
          ),
        ),
      );
    }
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);
    final fmt = NumberFormat.simpleCurrency(name: displayCurrency);

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
                Icon(Icons.pie_chart, size: 20, color: theme.colorScheme.primary),
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
                    for (var i = 0; i < entries.length; i++)
                      PieChartSectionData(
                        value: entries[i].value,
                        title: '${((entries[i].value / total) * 100).toStringAsFixed(0)}%',
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
            ...entries.take(5).map((entry) {
              final i = entries.indexOf(entry);
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
                        Text(fmt.format(entry.value), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
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
            if (entries.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+${entries.length - 5} more categories',
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

  Widget _buildSources(ThemeData theme, Map<PaymentSourceKey, double> totals, NumberFormat fmt) {
    final entries = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final total = entries.fold<double>(0, (sum, e) => sum + e.value);

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
                Icon(Icons.account_balance_wallet, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Payment sources', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            for (final entry in entries.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_iconForSourceType(entry.key.type), color: theme.colorScheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _labelForSourceKey(entry.key, cards, accounts),
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? entry.value / total : 0,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
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
    MapEntry<PaymentSourceKey, double>? topSource,
    Expense? largest,
    List<Expense> list,
  ) {
    final insightData = <({String icon, String title, String subtitle})>[];

    if (topCategory != null) {
      insightData.add((
        icon: '\ud83c\udfc6',
        title: 'Top Category',
        subtitle: '${_categoryLabelFromContext(context, topCategory.key)} had the most spending',
      ));
    }
    if (topSource != null) {
      insightData.add((
        icon: '\ud83d\udcb3',
        title: 'Most Used',
        subtitle: '${_labelForSourceKey(topSource.key, cards, accounts)} was your go-to',
      ));
    }
    if (largest != null) {
      insightData.add((
        icon: '\ud83d\udd25',
        title: 'Biggest Expense',
        subtitle: '${largest.title} at ${fmt.format(amountInDisplayCurrency(largest, displayCurrency, budgetToEur))}',
      ));
    }
    if (scope == _AnalyticsScope.month) {
      final dayTotals = <int, double>{};
      for (final e in list) {
        dayTotals[e.date.day] = (dayTotals[e.date.day] ?? 0) + amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      }
      final busiest = _topEntry(dayTotals);
      if (busiest != null) {
        insightData.add((
          icon: '\ud83d\udcc5',
          title: 'Peak Day',
          subtitle: '${DateFormat.MMMd().format(DateTime(year, month ?? 1, busiest.key))} was the busiest',
        ));
      }
    } else {
      final monthTotals = <int, double>{};
      for (final e in list) {
        monthTotals[e.date.month] = (monthTotals[e.date.month] ?? 0) + amountInDisplayCurrency(e, displayCurrency, budgetToEur);
      }
      final peak = _topEntry(monthTotals);
      if (peak != null) {
        insightData.add((
          icon: '\ud83d\udcca',
          title: 'Peak Month',
          subtitle: '${DateFormat.MMMM().format(DateTime(year, peak.key))} had the highest spending',
        ));
      }
    }

    if (insightData.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.secondaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('\ud83d\udca1', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'Insights',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            for (final item in insightData)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondaryContainer.withOpacity(0.8),
                            ),
                          ),
                        ],
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

double _totalFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  return expenses.fold(0, (sum, e) {
    if (e.transactionType == 'transfer') return sum;
    return sum + amountInDisplayCurrency(e, displayCurrency, budgetToEur);
  });
}

Map<String, double> _categoryTotalsFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  final totals = <String, double>{};
  for (final e in expenses) {
    if (e.transactionType == 'transfer') continue;
    final amount = amountInDisplayCurrency(e, displayCurrency, budgetToEur);
    totals[e.category] = (totals[e.category] ?? 0) + amount;
  }
  return totals;
}

Map<PaymentSourceKey, double> _sourceTotalsFor(List<Expense> expenses, String displayCurrency, double? budgetToEur) {
  final totals = <PaymentSourceKey, double>{};
  for (final e in expenses) {
    if (e.transactionType == 'transfer') continue;
    final amount = amountInDisplayCurrency(e, displayCurrency, budgetToEur);
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

String removeEmojis(String input) {
  final emojiRegex = RegExp(
    r'[\u{1F300}-\u{1FAFF}'
    r'\u{2600}-\u{27BF}'
    r'\u{1F1E6}-\u{1F1FF}]',
    unicode: true,
  );

  return input.replaceAll(emojiRegex, '');
}

PaymentSourceKey _sourceKeyForExpense(Expense expense) {
  final type = (expense.paymentSourceType.isNotEmpty ? expense.paymentSourceType : 'cash').toLowerCase();
  return PaymentSourceKey(type: type, id: expense.paymentSourceId ?? type);
}

String _labelForSourceKey(PaymentSourceKey key, List<CreditCard> cards, List<AccountCredential> accounts) {
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
