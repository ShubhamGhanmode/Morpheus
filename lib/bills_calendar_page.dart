import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/utils/card_balances.dart';
import 'package:morpheus/utils/statement_dates.dart';

class BillsCalendarPage extends StatefulWidget {
  const BillsCalendarPage({super.key, required this.cards, required this.expenses, required this.baseCurrency});

  final List<CreditCard> cards;
  final List<Expense> expenses;
  final String baseCurrency;

  @override
  State<BillsCalendarPage> createState() => _BillsCalendarPageState();
}

class _BillsCalendarPageState extends State<BillsCalendarPage> {
  final ForexService _forexService = ForexService();
  final Map<String, Future<double?>> _rateCache = {};

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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bills = widget.cards.map((card) {
      final cardCurrency = card.currency.isNotEmpty ? card.currency : widget.baseCurrency;
      final stats = _cardStats(card, cardCurrency);
      final baseStats = _cardStats(card, widget.baseCurrency);
      final due = stats.window.due;
      final dueAmount = stats.statementBalance;
      final baseAmount = baseStats.statementBalance;
      final hasDue = dueAmount > 0;
      return _BillItem(
        card: card,
        due: due,
        amount: dueAmount,
        amountInBase: baseAmount,
        currency: cardCurrency,
        overdue: hasDue && due.isBefore(now),
      );
    }).toList()..sort((a, b) => a.due.compareTo(b.due));

    final horizon = now.add(const Duration(days: 30));
    final upcoming = bills.where((b) => b.due.isBefore(horizon)).toList();
    final totalImpact = upcoming.fold<double>(0, (sum, b) => sum + b.amountInBase);
    final autopayImpact = upcoming.where((b) => b.card.autopayEnabled).fold<double>(0, (sum, b) => sum + b.amountInBase);
    final manualImpact = totalImpact - autopayImpact;
    final baseFmt = NumberFormat.simpleCurrency(name: widget.baseCurrency);
    final altCurrency = _alternateCurrency(widget.baseCurrency);
    final altRateFuture = altCurrency != null ? _rateFor(widget.baseCurrency, altCurrency) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Bills calendar')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryCard(
            baseFmt: baseFmt,
            totalImpact: totalImpact,
            autopayImpact: autopayImpact,
            manualImpact: manualImpact,
            altCurrency: altCurrency,
            altRateFuture: altRateFuture,
          ),
          const SizedBox(height: 12),
          if (bills.isEmpty) const _EmptyBillsState() else ..._buildSections(context, bills),
        ],
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, List<_BillItem> bills) {
    final widgets = <Widget>[];
    String? currentKey;
    for (final bill in bills) {
      final key = DateFormat.yMMMM().format(bill.due);
      if (key != currentKey) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 6),
            child: Text(key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
        );
        currentKey = key;
      }
      final altCurrency = _alternateCurrency(bill.currency);
      widgets.add(
        _BillRow(
          item: bill,
          altCurrency: altCurrency,
          altRateFuture: altCurrency != null ? _rateFor(bill.currency, altCurrency) : null,
        ),
      );
    }
    return widgets;
  }

  _CardSpendStats _cardStats(CreditCard card, String currency) {
    final balance = computeCardBalance(expenses: widget.expenses, card: card, currency: currency);
    return _CardSpendStats(
      window: balance.window,
      statementBalance: balance.statementBalance,
      unbilledBalance: balance.unbilledBalance,
      totalBalance: balance.totalBalance,
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.baseFmt,
    required this.totalImpact,
    required this.autopayImpact,
    required this.manualImpact,
    required this.altCurrency,
    required this.altRateFuture,
  });

  final NumberFormat baseFmt;
  final double totalImpact;
  final double autopayImpact;
  final double manualImpact;
  final String? altCurrency;
  final Future<double?>? altRateFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    Widget buildSummary(double? rate) {
      String? altText(double value) {
        if (altFmt == null) return null;
        final converted = rate != null ? value * rate : value;
        return '~ ${altFmt.format(converted)}';
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next 30 days cash-flow impact', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(baseFmt.format(totalImpact), style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          if (altText(totalImpact) != null)
            Text(altText(totalImpact)!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _pill(theme, 'Autopay', baseFmt.format(autopayImpact), altText(autopayImpact)),
              _pill(theme, 'Manual', baseFmt.format(manualImpact), altText(manualImpact)),
            ],
          ),
        ],
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: altRateFuture == null
            ? buildSummary(null)
            : FutureBuilder<double?>(future: altRateFuture, builder: (context, snap) => buildSummary(snap.data)),
      ),
    );
  }

  Widget _pill(ThemeData theme, String label, String value, String? altValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
              if (altValue != null)
                Text(altValue, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyBillsState extends StatelessWidget {
  const _EmptyBillsState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text('No bills yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Add cards with due dates to populate the calendar'),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.item, required this.altCurrency, required this.altRateFuture});

  final _BillItem item;
  final String? altCurrency;
  final Future<double?>? altRateFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: item.currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    final hasDue = item.amount > 0;
    final isCredit = item.amount < 0;
    final amountColor = isCredit
        ? theme.colorScheme.primary
        : hasDue
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurfaceVariant;
    final badges = <Widget>[
      if (hasDue)
        item.card.autopayEnabled
            ? _badge(theme, 'Autopay', theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer)
            : _badge(theme, 'Manual', theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant)
      else if (isCredit)
        _badge(theme, 'Credit', theme.colorScheme.tertiaryContainer, theme.colorScheme.onTertiaryContainer)
      else
        _badge(theme, 'No due', theme.colorScheme.surfaceVariant, theme.colorScheme.onSurfaceVariant),
      if (item.overdue) _badge(theme, 'Overdue', theme.colorScheme.errorContainer, theme.colorScheme.onErrorContainer),
    ];

    Widget buildAmount(double? rate) {
      String? altText(double value) {
        if (altFmt == null) return null;
        final converted = rate != null ? value * rate : value;
        return '~ ${altFmt.format(converted)}';
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            fmt.format(item.amount),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: amountColor),
          ),
          if (altText(item.amount) != null)
            Text(altText(item.amount)!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.credit_card, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.card.bankName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${DateFormat.MMMd().format(item.due)} - ${item.currency}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: badges),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              altRateFuture == null
                  ? buildAmount(null)
                  : FutureBuilder<double?>(future: altRateFuture, builder: (context, snap) => buildAmount(snap.data)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BillItem {
  _BillItem({
    required this.card,
    required this.due,
    required this.amount,
    required this.amountInBase,
    required this.currency,
    required this.overdue,
  });

  final CreditCard card;
  final DateTime due;
  final double amount;
  final double amountInBase;
  final String currency;
  final bool overdue;
}

class _CardSpendStats {
  _CardSpendStats({
    required this.window,
    required this.statementBalance,
    required this.unbilledBalance,
    required this.totalBalance,
  });

  final StatementWindow window;
  final double statementBalance;
  final double unbilledBalance;
  final double totalBalance;
}
