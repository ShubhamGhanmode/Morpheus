import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/creditcard_management_page.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/utils/card_balances.dart';

class CardLedgerPage extends StatelessWidget {
  const CardLedgerPage({super.key, required this.card, required this.expenses, required this.baseCurrency});

  final CreditCard card;
  final List<Expense> expenses;
  final String baseCurrency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardCurrency = card.currency.isNotEmpty ? card.currency : baseCurrency;
    final fmt = NumberFormat.simpleCurrency(name: cardCurrency);
    final altCurrency = _alternateCurrency(cardCurrency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    final rateFuture = altCurrency != null ? ForexService().latestRate(base: cardCurrency, symbol: altCurrency) : null;

    final stats = computeCardBalance(expenses: expenses, card: card, currency: cardCurrency);
    final entries = expenses.where((e) => _matchesCard(e, card)).toList()..sort((a, b) => b.date.compareTo(a.date));

    Widget buildBody(double? rate) {
      String? altText(double value) {
        if (altFmt == null) return null;
        final converted = rate != null ? value * rate : value;
        return '~ ${altFmt.format(converted)}';
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Current balance', style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Text(fmt.format(stats.totalBalance), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (altText(stats.totalBalance) != null)
                    Text(
                      altText(stats.totalBalance)!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _infoChip(theme, 'Statement', fmt.format(stats.statementBalance), altText(stats.statementBalance)),
                      _infoChip(theme, 'Unbilled', fmt.format(stats.unbilledBalance), altText(stats.unbilledBalance)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.colorScheme.secondaryContainer, thickness: 3, radius: BorderRadius.circular(12)),
          const SizedBox(height: 12),
          Text('Ledger', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Padding(padding: EdgeInsets.all(16), child: Text('No transactions yet'))
          else
            ...entries.map((entry) => _LedgerRow(entry: entry, fmt: fmt, altFmt: altFmt, rate: rate)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${card.bankName} transactions')),
      body: rateFuture == null
          ? buildBody(null)
          : FutureBuilder<double?>(future: rateFuture, builder: (context, snap) => buildBody(snap.data)),
    );
  }

  Widget _infoChip(ThemeData theme, String label, String value, String? altValue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          if (altValue != null)
            Text(altValue, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.fmt, required this.altFmt, required this.rate});

  final Expense entry;
  final NumberFormat fmt;
  final NumberFormat? altFmt;
  final double? rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = entry.amountForCurrency(fmt.currencyName ?? entry.currency);
    final isCredit = amount < 0;
    final displayAmount = isCredit ? amount.abs() : amount;
    final altAmount = altFmt != null ? (rate != null ? displayAmount * rate! : displayAmount) : null;
    final altFormatter = altFmt;
    final subtitle = entry.note?.isNotEmpty == true
        ? '${DateFormat.yMMMd().format(entry.date)} - ${entry.note}'
        : DateFormat.yMMMd().format(entry.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isCredit ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              isCredit ? Icons.call_received : Icons.call_made,
              color: isCredit ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${fmt.format(displayAmount)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isCredit ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
              if (altAmount != null && altFormatter != null)
                Text(
                  '~ ${isCredit ? '+' : '-'}${altFormatter.format(altAmount)}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _alternateCurrency(String currency) {
  if (!AppConfig.enableSecondaryCurrency) return null;
  if (currency == AppConfig.baseCurrency) return AppConfig.secondaryCurrency;
  if (currency == AppConfig.secondaryCurrency) return AppConfig.baseCurrency;
  return null;
}

bool _matchesCard(Expense expense, CreditCard card) {
  final type = expense.paymentSourceType.toLowerCase();
  if (type != 'card' && type != 'credit' && type != 'credit_card') {
    return false;
  }
  final sourceId = (expense.paymentSourceId ?? '').trim();
  if (sourceId.isEmpty) return false;
  if (sourceId == card.id) return true;
  final sourceDigits = sourceId.replaceAll(RegExp(r'\\D'), '');
  final cardDigits = card.cardNumber.replaceAll(RegExp(r'\\D'), '');
  return sourceDigits.isNotEmpty && cardDigits.isNotEmpty && sourceDigits == cardDigits;
}
