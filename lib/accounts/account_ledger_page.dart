import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/accounts/models/account_credential.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/services/forex_service.dart';

class AccountLedgerPage extends StatelessWidget {
  const AccountLedgerPage({super.key, required this.account, required this.expenses});

  final AccountCredential account;
  final List<Expense> expenses;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = NumberFormat.simpleCurrency(name: account.currency);
    final altCurrency = _alternateCurrency(account.currency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;
    final rateFuture = altCurrency != null ? ForexService().latestRate(base: account.currency, symbol: altCurrency) : null;

    final entries =
        expenses.where((e) => e.paymentSourceType.toLowerCase() == 'account' && e.paymentSourceId == account.id).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final balance = account.balance - entries.fold<double>(0, (sum, e) => sum + e.amountForCurrency(account.currency));

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
                  Text(fmt.format(balance), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (altText(balance) != null)
                    Text(
                      altText(balance)!,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
      appBar: AppBar(title: Text('${account.bankName} ledger')),
      body: rateFuture == null
          ? buildBody(null)
          : FutureBuilder<double?>(future: rateFuture, builder: (context, snap) => buildBody(snap.data)),
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
          subtitle: Text(
            '${DateFormat.yMMMd().format(entry.date)}${entry.note != null ? ' - ${entry.note}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
