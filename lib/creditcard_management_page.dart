import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/add_card_dialog.dart';
import 'package:morpheus/bills_calendar_page.dart';
import 'package:morpheus/cards/card_ledger_page.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/cards/models/card_payment_draft.dart';
import 'package:morpheus/cards/models/card_spend_stats.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/expenses/services/expense_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/services/forex_service.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/utils/card_balances.dart';
import 'package:morpheus/utils/error_mapper.dart';
import 'package:morpheus/utils/statement_dates.dart';

class CreditCardManagementPage extends StatefulWidget {
  const CreditCardManagementPage({super.key, this.tabIndexListenable, this.tabIndex});

  final ValueListenable<int>? tabIndexListenable;
  final int? tabIndex;

  @override
  State<CreditCardManagementPage> createState() => _CreditCardManagementPageState();
}

class _CreditCardManagementPageState extends State<CreditCardManagementPage> with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _cardTransitionController;
  late AnimationController _detailsController;
  late Animation<double> _cardSlideAnimation;
  late Animation<double> _detailsFadeAnimation;
  late Animation<double> _detailsScaleAnimation;
  late final CardCubit _cardCubit;
  late final AccountsCubit _accountsCubit;
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final ExpenseService _expenseService = ExpenseService();
  final ForexService _forexService = ForexService();
  final Map<String, Future<double?>> _rateCache = {};
  bool _expensesLoading = false;
  List<Expense> _expenses = [];
  bool _revealSensitive = false;
  static const _networkAssets = {'visa': 'assets/visa.svg', 'mastercard': 'assets/mastercard.svg'};
  VoidCallback? _tabListener;

  Future<void> _onAddCard() async {
    final newCard = await showDialog<CreditCard>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddCardDialog(),
    );

    if (newCard == null) return;

    await _cardCubit.addCard(newCard);
    setState(() => selectedCard = newCard);

    // Play the select animation for the newly added card
    _detailsController
      ..reset()
      ..forward();
    _cardTransitionController
      ..reset()
      ..forward();
  }

  Future<void> _editCard(CreditCard card) async {
    final result = await showDialog<CreditCard>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AddCardDialog(existing: card),
    );
    if (result != null) {
      await _cardCubit.addCard(result);
      setState(() => selectedCard = result);
      _detailsController
        ..reset()
        ..forward();
      _cardTransitionController
        ..reset()
        ..forward();
    }
  }

  Future<void> _deleteCard(CreditCard card) async {
    final confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete card'),
            content: Text('Remove ${card.bankName}?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (confirm) {
      await _cardCubit.deleteCard(card.id);
    }
  }

  CreditCard? selectedCard;

  List<CreditCard> cards = [];

  @override
  void initState() {
    super.initState();
    _cardCubit = CardCubit(CardRepository())..loadCards();
    _accountsCubit = AccountsCubit(AccountsRepository())..load();
    selectedCard = null;
    _loadExpenses();

    _shimmerController = AnimationController(vsync: this, duration: Duration(seconds: 3))..repeat();

    _cardTransitionController = AnimationController(vsync: this, duration: Duration(milliseconds: 500));

    _detailsController = AnimationController(vsync: this, duration: Duration(milliseconds: 400));

    _cardSlideAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _cardTransitionController, curve: Curves.easeInOut));

    _detailsFadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _detailsController, curve: Curves.easeOut));

    _detailsScaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1,
    ).animate(CurvedAnimation(parent: _detailsController, curve: Curves.easeOutBack));

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
    _shimmerController.dispose();
    _cardTransitionController.dispose();
    _detailsController.dispose();
    _cardCubit.close();
    _accountsCubit.close();
    super.dispose();
  }

  void _selectCard(CreditCard card) {
    if (selectedCard?.id == card.id) return;

    setState(() {
      selectedCard = card;
      _revealSensitive = false;
    });
    _detailsController.reset();
    _cardTransitionController.reset();

    _cardTransitionController.forward();
    _detailsController.forward();
  }

  Future<void> _refreshData() async {
    await _cardCubit.loadCards();
    await _accountsCubit.load();
    await _loadExpenses();
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
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Load card expenses failed',
      );
      if (!mounted) return;
      setState(() => _expensesLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage(e, action: 'Load expenses'))),
      );
    }
  }

  void _openBillsCalendar(String baseCurrency) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillsCalendarPage(cards: cards, expenses: _expenses, baseCurrency: baseCurrency),
      ),
    );
  }

  void _openCardLedger(CreditCard card, String baseCurrency) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CardLedgerPage(card: card, expenses: _expenses, baseCurrency: baseCurrency),
      ),
    );
  }

  List<CreditCard> get availableCards => cards.where((c) => c.id != selectedCard?.id).toList();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardHeight = screenWidth / 1.586; // credit card ratio
    final textTheme = Theme.of(context).textTheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _cardCubit),
        BlocProvider.value(value: _accountsCubit),
      ],
      child: BlocListener<CardCubit, CardState>(
        listenWhen: (previous, current) => previous.cards != current.cards,
        listener: (context, state) {
          setState(() {
            cards = state.cards;
            if (selectedCard == null && cards.isNotEmpty) {
              selectedCard = cards.first;
              _detailsController.forward();
              _cardTransitionController.forward();
            } else if (selectedCard != null && !cards.any((c) => c.id == selectedCard!.id)) {
              selectedCard = cards.isNotEmpty ? cards.first : null;
            }
          });
        },
        child: BlocBuilder<CardCubit, CardState>(
          builder: (context, state) {
            final loading = state.loading && cards.isEmpty;
            final settings = context.watch<SettingsCubit>().state;
            final baseCurrency = settings.baseCurrency;
            return Scaffold(
              appBar: AppBar(
                title: const Text('My Cards'),
                actions: [
                  IconButton(
                    tooltip: 'Bills calendar',
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () => _openBillsCalendar(settings.baseCurrency),
                  ),
                ],
              ),
              body: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                      children: [
                        SizedBox(
                          height: cardHeight,
                          child: selectedCard != null
                              ? AnimatedBuilder(
                                  animation: Listenable.merge([_detailsFadeAnimation, _detailsScaleAnimation]),
                                  builder: (_, __) => FadeTransition(
                                    opacity: _detailsFadeAnimation,
                                    child: ScaleTransition(
                                      scale: _detailsScaleAnimation,
                                      child: _buildGlassCard(selectedCard!, cardHeight),
                                    ),
                                  ),
                                )
                              : _buildEmptyState(),
                        ),
                        if (selectedCard != null) ...[
                          const SizedBox(height: 12),
                          _buildCardSummary(
                            card: selectedCard!,
                            fmt: NumberFormat.simpleCurrency(
                              name: selectedCard!.currency.isNotEmpty ? selectedCard!.currency : baseCurrency,
                            ),
                            displayCurrency: selectedCard!.currency.isNotEmpty ? selectedCard!.currency : baseCurrency,
                            baseCurrency: baseCurrency,
                            testMode: settings.testModeEnabled,
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text('Your cards', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const Spacer(),
                            if (_expensesLoading)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (state.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(state.error!, style: TextStyle(color: Colors.red.shade400)),
                                ),
                              ],
                            ),
                          ),
                        if (availableCards.isEmpty)
                          _buildListEmpty()
                        else
                          ListView.separated(
                            itemCount: availableCards.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, index) {
                              final card = availableCards[index];
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  GestureDetector(onTap: () => _selectCard(card), child: _buildMiniCard(card)),
                                  if (settings.testModeEnabled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, right: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _testNotification(card),
                                            icon: const Icon(Icons.notifications_active_outlined, size: 16),
                                            label: const Text('Test notification'),
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _testPush(card),
                                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                                            label: const Text('Test push'),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: _onAddCard,
                icon: const Icon(Icons.add_card),
                label: const Text('New card'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassCard(CreditCard card, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          // Frosted glass background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [card.cardColor, card.cardColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.white.withOpacity(0.02)),
          ),

          // Shimmer layer
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (_, __) {
              return Transform.translate(
                offset: Offset((_shimmerController.value * height * 2) - height, 0),
                child: Container(
                  width: height / 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.07), Colors.white.withOpacity(0.0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              );
            },
          ),

          // Card content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Name + Icon
                Row(
                  children: [
                    if (card.bankIconUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(0.15),
                          backgroundImage: NetworkImage(card.bankIconUrl!),
                          radius: 16,
                        ),
                      ),
                    Expanded(
                      child: Text(
                        card.bankName,
                        style: TextStyle(color: card.textColor, fontSize: 20, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _revealSensitive ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: card.textColor,
                      ),
                      tooltip: _revealSensitive ? 'Hide details' : 'Show details',
                      onPressed: () => setState(() {
                        _revealSensitive = !_revealSensitive;
                      }),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: card.textColor),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editCard(card);
                            break;
                          case 'delete':
                            _deleteCard(card);
                            break;
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: card.cardNetwork != null ? _networkBadge(card.cardNetwork!, size: 36) : const SizedBox.shrink(),
                  ),
                ),
                Text(
                  _displayNumber(card),
                  style: TextStyle(color: card.textColor, fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildCardField(
                        "CARD HOLDER",
                        card.holderName,
                        card.textColor,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCardField("EXPIRES", card.expiryDate, card.textColor, align: CrossAxisAlignment.end),
                    const SizedBox(width: 12),
                    _buildCardField("CVV", _displayCvv(card), card.textColor, align: CrossAxisAlignment.end),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardSummary({
    required CreditCard card,
    required NumberFormat fmt,
    required String displayCurrency,
    required String baseCurrency,
    required bool testMode,
  }) {
    final stats = _cardStats(card, displayCurrency, baseCurrency);
    final window = stats.window;
    final periodLabel = '${DateFormat.MMMd().format(window.start)} - ${DateFormat.MMMd().format(window.end)}';
    final dueLabel = DateFormat.MMMd().format(window.due);
    final limit = card.usageLimit;
    final utilization = stats.utilization;
    final nearLimit = utilization != null && utilization >= 0.9;
    final forecast = _buildUtilizationForecast(card, stats, fmt);
    final altCurrency = _alternateCurrency(displayCurrency);
    final altFmt = altCurrency != null ? NumberFormat.simpleCurrency(name: altCurrency) : null;

    Widget buildMetrics(double? rate) {
      String? altText(double value) {
        if (altFmt == null) return null;
        final converted = rate != null ? value * rate : value;
        return '~ ${altFmt.format(converted)}';
      }

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _metricTile(
            icon: Icons.receipt_long,
            label: 'Statement balance',
            value: fmt.format(stats.statementBalance),
            subtitle: altText(stats.statementBalance),
          ),
          _metricTile(
            icon: Icons.trending_up,
            label: 'Unbilled balance',
            value: fmt.format(stats.unbilledBalance),
            subtitle: altText(stats.unbilledBalance),
          ),
          _metricTile(
            icon: Icons.payments_outlined,
            label: 'Payments',
            value: fmt.format(stats.statementPayments),
            subtitle: altText(stats.statementPayments),
          ),
          if (limit != null)
            _metricTile(
              icon: Icons.savings_outlined,
              label: 'Available limit',
              value: fmt.format(stats.available ?? limit),
              subtitle: altText(stats.available ?? limit),
            ),
        ],
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Statement overview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                _infoChip(Icons.event, 'Due $dueLabel'),
              ],
            ),
            const SizedBox(height: 12),
            if (altCurrency == null)
              buildMetrics(null)
            else
              FutureBuilder<double?>(
                future: _rateFor(displayCurrency, altCurrency),
                builder: (context, snap) => buildMetrics(snap.data),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.schedule, periodLabel),
                _infoChip(Icons.calendar_today, 'Billing day ${card.billingDay}'),
                _infoChip(Icons.currency_exchange, 'Currency ${card.currency}'),
                if (card.autopayEnabled) _infoChip(Icons.auto_mode_rounded, 'Autopay on'),
                if (card.reminderEnabled) _infoChip(Icons.notifications_active, _reminderLabel(card)),
              ],
            ),
            if (limit != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  minHeight: 6,
                  value: utilization?.clamp(0, 1) ?? 0,
                  backgroundColor: Colors.black.withOpacity(0.08),
                  color: utilization != null && utilization >= 1
                      ? Colors.redAccent
                      : nearLimit
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
            if (forecast != null) ...[const SizedBox(height: 12), forecast],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _recordPayment(card, displayCurrency),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Record'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _openCardLedger(card, baseCurrency),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Transactions'),
                ),
                if (testMode)
                  OutlinedButton.icon(
                    onPressed: () => _testNotification(card),
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('Test notification'),
                  ),
                if (testMode)
                  OutlinedButton.icon(
                    onPressed: () => _testPush(card),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text('Test push'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({required IconData icon, required String label, required String value, String? subtitle}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildCardField(
    String label,
    String value,
    Color color, {
    TextOverflow? overflow,
    int? maxLines,
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
          overflow: overflow,
          maxLines: maxLines,
        ),
      ],
    );
  }

  Widget? _buildUtilizationForecast(CreditCard card, CardSpendStats stats, NumberFormat fmt) {
    final limit = card.usageLimit;
    if (limit == null || limit <= 0) return null;

    const targetUtilization = 0.3;
    final desiredMax = limit * targetUtilization;
    final payNeeded = stats.totalBalance - desiredMax;
    final theme = Theme.of(context);
    final offsets = card.reminderOffsets.where((d) => d > 0).toList();
    final leadDays = offsets.isNotEmpty ? offsets.reduce((a, b) => a > b ? a : b) : 5;
    final earlyDate = stats.window.due.subtract(Duration(days: leadDays));

    String message;
    if (payNeeded <= 0) {
      message = 'On track to stay under ${(targetUtilization * 100).toStringAsFixed(0)}% utilization.';
    } else {
      message =
          'Pay ${fmt.format(payNeeded)} by ${DateFormat.MMMd().format(earlyDate)} to stay under ${(targetUtilization * 100).toStringAsFixed(0)}% utilization.';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _displayNumber(CreditCard card) {
    if (_revealSensitive) return _groupCard(card.cardNumber);
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.isNotEmpty ? digits.substring(digits.length - (digits.length >= 4 ? 4 : digits.length)) : '****';
    return '**** **** **** $last4';
  }

  String _displayCvv(CreditCard card) {
    if (_revealSensitive) return card.cvv;
    return '***';
  }

  String _maskForList(CreditCard card) {
    final digits = card.cardNumber.replaceAll(RegExp(r'\D'), '');
    final last4 = digits.isNotEmpty ? digits.substring(digits.length - (digits.length >= 4 ? 4 : digits.length)) : '****';
    return '**** **** **** $last4';
  }

  String _groupCard(String digits) {
    final d = digits.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(d[i]);
    }
    return buffer.toString();
  }

  CardSpendStats _cardStats(CreditCard card, String displayCurrency, String baseCurrency) {
    final now = DateTime.now();
    final primary = computeCardBalance(expenses: _expenses, card: card, currency: displayCurrency, now: now);
    final base = displayCurrency == baseCurrency
        ? primary
        : computeCardBalance(expenses: _expenses, card: card, currency: baseCurrency, now: now);

    final limit = card.usageLimit;
    final outstanding = primary.totalBalance;
    final available = limit != null ? (limit - outstanding) : null;
    final utilization = (limit != null && limit > 0) ? ((outstanding > 0 ? outstanding : 0) / limit) : null;

    final availableBase = (limit != null && displayCurrency == baseCurrency) ? (limit - base.totalBalance) : null;

    return CardSpendStats(
      window: primary.window,
      statementBalance: primary.statementBalance,
      unbilledBalance: primary.unbilledBalance,
      totalBalance: outstanding,
      statementCharges: primary.statementCharges,
      statementPayments: primary.statementPayments,
      statementBalanceBase: base.statementBalance,
      unbilledBalanceBase: base.unbilledBalance,
      totalBalanceBase: base.totalBalance,
      statementPaymentsBase: base.statementPayments,
      available: available,
      availableBase: availableBase,
      utilization: utilization,
    );
  }

  StatementWindow _statementWindow(CreditCard card) {
    return buildStatementWindow(now: DateTime.now(), billingDay: card.billingDay, graceDays: card.graceDays);
  }

  double _amountForDisplay(Expense expense, String displayCurrency) {
    return expense.amountForCurrency(displayCurrency);
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

  static String _reminderLabel(CreditCard card) {
    if (!card.reminderEnabled) return '';
    if (card.reminderOffsets.isEmpty) return 'Reminder on due';
    final sorted = [...card.reminderOffsets]..sort();
    return 'Remind: ${sorted.map((d) => '${d}d').join(', ')}';
  }

  Future<void> _testNotification(CreditCard card) async {
    final window = _statementWindow(card);
    await NotificationService.instance.showInstantNotification(
      'Card reminder test',
      '${card.bankName} due on ${DateFormat.yMMMd().format(window.due)}',
    );
  }

  Future<void> _testPush(CreditCard card) async {
    final window = _statementWindow(card);
    try {
      await NotificationService.instance.sendTestPush(
        title: 'Card reminder test',
        body: '${card.bankName} due on ${DateFormat.yMMMd().format(window.due)}',
        cardId: card.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test push sent')));
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Send test push failed');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test push failed')));
    }
  }

  Future<void> _recordPayment(CreditCard card, String displayCurrency) async {
    final accountsState = _accountsCubit.state;
    final accounts = accountsState.items;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    var selectedAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    var currency = accounts.isNotEmpty ? accounts.first.currency : displayCurrency;
    var date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<CardPaymentDraft>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          return Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Record payment', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount paid'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currency,
                          items: AppConfig.supportedCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (v) => setLocal(() => currency = v ?? displayCurrency),
                          decoration: const InputDecoration(labelText: 'Currency'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: date,
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setLocal(() => date = picked);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: 'Date'),
                            child: Text(DateFormat.yMMMd().format(date)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (accounts.isEmpty)
                    TextFormField(
                      controller: accountCtrl,
                      decoration: const InputDecoration(labelText: 'Paid from account'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter an account';
                        }
                        return null;
                      },
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: selectedAccountId,
                      items: accounts
                          .map((a) => DropdownMenuItem<String>(value: a.id, child: Text('${a.bankName} • ${a.currency}')))
                          .toList(),
                      onChanged: (v) => setLocal(() {
                        selectedAccountId = v;
                        final acct = accounts.firstWhere((a) => a.id == v, orElse: () => accounts.first);
                        currency = acct.currency;
                      }),
                      decoration: const InputDecoration(labelText: 'Paid from account'),
                    ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          final amount = double.parse(amountCtrl.text.trim());
                          final accountId = accounts.isEmpty ? accountCtrl.text.trim() : selectedAccountId;
                          Navigator.pop(
                            ctx,
                            CardPaymentDraft(
                              amount: amount,
                              currency: currency,
                              date: date,
                              accountId: accountId,
                              note: noteCtrl.text.trim(),
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (result == null) return;

    final accountName = _accountNameFor(result.accountId);
    final paymentTitle = 'Card payment - ${card.bankName}';
    final accountExpense = Expense.create(
      title: paymentTitle,
      amount: result.amount,
      currency: result.currency,
      category: 'Card Payment',
      date: result.date,
      note: result.note?.isEmpty == true ? null : result.note,
      paymentSourceType: 'account',
      paymentSourceId: result.accountId,
      transactionType: 'transfer',
    );
    final cardCredit = Expense.create(
      title: paymentTitle,
      amount: -result.amount,
      currency: result.currency,
      category: 'Card Payment',
      date: result.date,
      note: accountName != null ? 'Paid from $accountName' : (result.note?.isEmpty == true ? null : result.note),
      paymentSourceType: 'card',
      paymentSourceId: card.id,
      transactionType: 'transfer',
    );

    final baseCurrency = context.read<SettingsCubit>().state.baseCurrency;
    await _expenseService.addExpense(accountExpense, baseCurrency: baseCurrency);
    await _expenseService.addExpense(cardCredit, baseCurrency: baseCurrency);
    await _loadExpenses();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded')));
  }

  String? _accountNameFor(String? accountId) {
    if (accountId == null) return null;
    final accounts = _accountsCubit.state.items;
    final match = accounts.where((a) => a.id == accountId).toList();
    if (match.isEmpty) return accountId;
    return match.first.bankName;
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(24)),
            child: Icon(Icons.credit_card, size: 48, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 12),
          const Text('No cards yet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 6),
          const Text('Tap the + button to add your first card'),
        ],
      ),
    );
  }

  Widget _buildListEmpty() {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text('No additional cards yet', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))],
      ),
    );
  }

  Widget _buildMiniCard(CreditCard card) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [card.cardColor, card.cardColor.withOpacity(0.85)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: card.cardColor.withOpacity(0.2), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (card.bankIconUrl != null)
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(card.bankIconUrl!),
                backgroundColor: Colors.white.withOpacity(0.15),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.bankName,
                  style: TextStyle(color: card.textColor, fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(_maskForList(card), style: TextStyle(color: card.textColor.withOpacity(0.9), fontSize: 14)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (card.cardNetwork != null) _networkBadge(card.cardNetwork!, size: 18),
              const SizedBox(height: 8),
              Icon(Icons.arrow_forward_ios, size: 16, color: card.textColor.withOpacity(0.7)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _networkBadge(String network, {double size = 24}) {
    final asset = _networkAssets[network.toLowerCase()];
    if (asset == null) {
      return Icon(Icons.credit_card, size: size, color: Colors.white);
    }
    final scale = network.toLowerCase() == 'visa' ? 1.5 : 1.5;
    final logoSize = size * scale;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: SizedBox(
        width: logoSize,
        height: logoSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 8),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.5), BlendMode.srcIn),
                    child: SvgPicture.asset(asset, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            SvgPicture.asset(asset, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }
}

