import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/accounts/accounts_cubit.dart';
import 'package:morpheus/accounts/accounts_repository.dart';
import 'package:morpheus/add_card_dialog.dart';
import 'package:morpheus/cards/card_cubit.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/repositories/expense_repository.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/settings/settings_cubit.dart';

class CreditCard {
  final String id;
  final String bankName;
  final String? bankIconUrl;
  final String? cardNetwork;
  final String cardNumber;
  final String holderName;
  final String expiryDate;
  final String cvv;
  final Color cardColor;
  final Color textColor;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int billingDay;
  final int graceDays;
  final double? usageLimit;
  final bool reminderEnabled;
  final List<int> reminderOffsets;

  CreditCard({
    required this.id,
    required this.bankName,
    this.bankIconUrl,
    this.cardNetwork,
    required this.cardNumber,
    required this.holderName,
    required this.expiryDate,
    required this.cvv,
    required this.cardColor,
    required this.textColor,
    this.createdAt,
    this.updatedAt,
    this.billingDay = 1,
    this.graceDays = 15,
    this.usageLimit,
    this.reminderEnabled = false,
    this.reminderOffsets = const [],
  });

  CreditCard copyWith({
    String? id,
    String? bankName,
    String? bankIconUrl,
    String? cardNetwork,
    String? cardNumber,
    String? holderName,
    String? expiryDate,
    String? cvv,
    Color? cardColor,
    Color? textColor,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? billingDay,
    int? graceDays,
    double? usageLimit,
    bool? reminderEnabled,
    List<int>? reminderOffsets,
  }) {
    return CreditCard(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      bankIconUrl: bankIconUrl ?? this.bankIconUrl,
      cardNetwork: cardNetwork ?? this.cardNetwork,
      cardNumber: cardNumber ?? this.cardNumber,
      holderName: holderName ?? this.holderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      cardColor: cardColor ?? this.cardColor,
      textColor: textColor ?? this.textColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billingDay: billingDay ?? this.billingDay,
      graceDays: graceDays ?? this.graceDays,
      usageLimit: usageLimit ?? this.usageLimit,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
    );
  }

  Map<String, dynamic> toStorageMap() {
    final now = DateTime.now();
    return {
      'id': id,
      'bankName': bankName,
      'bankIconUrl': bankIconUrl,
      'cardNetwork': cardNetwork,
      'cardNumber': cardNumber,
      'holderName': holderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'cardColor': cardColor.value,
      'textColor': textColor.value,
      'createdAt': (createdAt ?? now).millisecondsSinceEpoch,
      'updatedAt': (updatedAt ?? now).millisecondsSinceEpoch,
      'billingDay': billingDay,
      'graceDays': graceDays,
      'usageLimit': usageLimit,
      'reminderEnabled': reminderEnabled,
      'reminderOffsets': reminderOffsets,
    };
  }

  factory CreditCard.fromStorage(Map<String, dynamic> data) {
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is Timestamp) return v.toDate();
      return DateTime.tryParse(v.toString());
    }

    return CreditCard(
      id: (data['id'] ?? '').toString(),
      bankName: (data['bankName'] ?? data['bank_name'] ?? 'Unknown') as String,
      bankIconUrl: data['bankIconUrl'] as String?,
      cardNetwork: (data['cardNetwork'] ?? data['card_network']) as String?,
      cardNumber: (data['cardNumber'] ?? data['card_number'] ?? '**** **** **** 0000') as String,
      holderName: (data['holderName'] ?? data['card_holder_name'] ?? '').toString(),
      expiryDate: (data['expiryDate'] ?? data['expiry_date'] ?? '').toString(),
      cvv: (data['cvv'] ?? '***').toString(),
      cardColor: Color((data['cardColor'] ?? 0xFF334155) as int),
      textColor: Color((data['textColor'] ?? 0xFFFFFFFF) as int),
      createdAt: toDate(data['createdAt'] ?? data['created_at']),
      updatedAt: toDate(data['updatedAt'] ?? data['updated_at']),
      billingDay: (data['billingDay'] ?? data['billing_day'] ?? 1) as int,
      graceDays: (data['graceDays'] ?? data['grace_days'] ?? 15) as int,
      usageLimit: (data['usageLimit'] as num?)?.toDouble(),
      reminderEnabled: (data['reminderEnabled'] ?? data['reminder_enabled'] ?? false) as bool,
      reminderOffsets: (data['reminderOffsets'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
    );
  }
}

class CreditCardManagementPage extends StatefulWidget {
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
  bool _expensesLoading = false;
  List<Expense> _expenses = [];
  bool _revealSensitive = false;
  static const _networkAssets = {'visa': 'assets/visa.svg', 'mastercard': 'assets/mastercard.svg'};

  Future<void> _onAddCard() async {
    // Expecting your dialog to return either a CreditCard or a Map<String, dynamic>
    final result = await showDialog(context: context, barrierDismissible: true, builder: (_) => AddCardDialog());

    if (result == null) return;

    CreditCard? newCard;

    if (result is CreditCard) {
      newCard = result;
    } else if (result is Map) {
      newCard = CreditCard(
        id: (result['id'] ?? DateTime.now().millisecondsSinceEpoch.toString()).toString(),
        bankName: result['bankName'] ?? 'New Bank',
        bankIconUrl: result['bankIconUrl'] as String?,
        cardNetwork: result['cardNetwork'] as String?,
        cardNumber: result['cardNumber'] ?? '**** **** **** 0000',
        holderName: result['holderName'] ?? '',
        expiryDate: result['expiryDate'] ?? '',
        cvv: result['cvv'] ?? '***',
        cardColor: (result['cardColor'] is Color) ? result['cardColor'] : const Color(0xFF334155),
        textColor: (result['textColor'] is Color) ? result['textColor'] : Colors.white,
        createdAt: DateTime.now(),
        billingDay: (result['billingDay'] as int?)?.clamp(1, 28) ?? 1,
        graceDays: (result['graceDays'] as int?)?.clamp(0, 90) ?? 15,
        usageLimit: (result['usageLimit'] as num?)?.toDouble(),
        reminderEnabled: result['reminderEnabled'] as bool? ?? false,
        reminderOffsets: (result['reminderOffsets'] as List?)?.map((e) => (e as num).toInt()).toList() ?? const [],
      );
    }

    if (newCard == null) return;

    await _cardCubit.addCard(newCard!);
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
  }

  @override
  void dispose() {
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

  Future<void> _loadExpenses() async {
    setState(() => _expensesLoading = true);
    try {
      final items = await _expenseRepository.fetchExpenses();
      if (!mounted) return;
      setState(() {
        _expenses = items;
        _expensesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _expensesLoading = false);
    }
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
            final displayCurrency = _expenses.isNotEmpty ? _expenses.first.currency : 'EUR';
            final fmt = NumberFormat.simpleCurrency(name: displayCurrency);
            return Scaffold(
              appBar: AppBar(title: const Text('My Cards')),
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
                            fmt: fmt,
                            displayCurrency: displayCurrency,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCardField("CARD HOLDER", card.holderName, card.textColor),
                    _buildCardField("EXPIRES", card.expiryDate, card.textColor),
                    _buildCardField("CVV", _displayCvv(card), card.textColor),
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
    required bool testMode,
  }) {
    final stats = _cardStats(card, displayCurrency);
    final window = stats.window;
    final periodLabel = '${DateFormat.MMMd().format(window.start)} - ${DateFormat.MMMd().format(window.end)}';
    final dueLabel = DateFormat.MMMd().format(window.due);
    final limit = card.usageLimit;
    final utilization = stats.utilization;
    final nearLimit = utilization != null && utilization >= 0.9;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _metricTile(icon: Icons.receipt_long, label: 'Statement spend', value: fmt.format(stats.netSpend)),
                _metricTile(icon: Icons.payments_outlined, label: 'Payments', value: fmt.format(stats.payments)),
                if (limit != null)
                  _metricTile(
                    icon: Icons.savings_outlined,
                    label: 'Available limit',
                    value: fmt.format(stats.available ?? limit),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _infoChip(Icons.schedule, periodLabel),
                _infoChip(Icons.calendar_today, 'Billing day ${card.billingDay}'),
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
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _recordPayment(card, displayCurrency),
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Record payment'),
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

  Widget _metricTile({required IconData icon, required String label, required String value}) {
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

  Widget _buildCardField(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
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

  _CardSpendStats _cardStats(CreditCard card, String displayCurrency) {
    final window = _statementWindow(card);
    final windowExpenses = _expenses.where((e) {
      final sameCard = e.paymentSourceType.toLowerCase() == 'card' && e.paymentSourceId == card.id;
      if (!sameCard) return false;
      return !e.date.isBefore(window.start) && !e.date.isAfter(window.end);
    }).toList();

    double charges = 0;
    double payments = 0;
    for (final e in windowExpenses) {
      final amount = _amountForDisplay(e, displayCurrency);
      if (amount >= 0) {
        charges += amount;
      } else {
        payments += amount.abs();
      }
    }
    final net = (charges - payments);
    final netSpend = net < 0 ? 0.0 : net;
    final limit = card.usageLimit;
    final available = limit != null ? (limit - netSpend) : null;
    final utilization = (limit != null && limit > 0) ? (netSpend / limit) : null;
    return _CardSpendStats(
      window: window,
      charges: charges,
      payments: payments,
      netSpend: netSpend,
      available: available,
      utilization: utilization,
    );
  }

  _StatementWindow _statementWindow(CreditCard card) {
    final now = DateTime.now();
    final billingDay = card.billingDay.clamp(1, 28);
    final currentBilling = _safeDate(now.year, now.month, billingDay);
    final cycleEnd = now.isBefore(currentBilling) ? _safeDate(now.year, now.month - 1, billingDay) : currentBilling;
    final startMonth = cycleEnd.month - 1 <= 0 ? cycleEnd.month + 11 : cycleEnd.month - 1;
    final startYear = cycleEnd.month - 1 <= 0 ? cycleEnd.year - 1 : cycleEnd.year;
    final cycleStart = _safeDate(startYear, startMonth, billingDay + 1);
    final dueDay = (billingDay + card.graceDays).clamp(1, _daysInMonth(cycleEnd.year, cycleEnd.month));
    final due = _safeDate(cycleEnd.year, cycleEnd.month, dueDay);
    return _StatementWindow(start: cycleStart, end: cycleEnd, due: due);
  }

  double _amountForDisplay(Expense expense, String displayCurrency) {
    return expense.amountForCurrency(displayCurrency);
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
    } catch (_) {
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
    var currency = displayCurrency;
    var date = DateTime.now();
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<_PaymentDraft>(
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
                          items: const [
                            'EUR',
                            'INR',
                            'USD',
                            'GBP',
                          ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
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
                      items: accounts.map((a) => DropdownMenuItem<String>(value: a.id, child: Text(a.bankName))).toList(),
                      onChanged: (v) => setLocal(() => selectedAccountId = v),
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
                            _PaymentDraft(
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
    final accountExpense = Expense(
      title: paymentTitle,
      amount: result.amount,
      currency: result.currency,
      category: 'Card Payment',
      date: result.date,
      note: result.note?.isEmpty == true ? null : result.note,
      paymentSourceType: 'account',
      paymentSourceId: result.accountId,
    );
    final cardCredit = Expense(
      title: paymentTitle,
      amount: -result.amount,
      currency: result.currency,
      category: 'Card Payment',
      date: result.date,
      note: accountName != null ? 'Paid from $accountName' : (result.note?.isEmpty == true ? null : result.note),
      paymentSourceType: 'card',
      paymentSourceId: card.id,
    );

    await _expenseRepository.addExpense(accountExpense);
    await _expenseRepository.addExpense(cardCredit);
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
                  imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 6),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(Colors.white.withOpacity(1), BlendMode.srcIn),
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

class _StatementWindow {
  _StatementWindow({required this.start, required this.end, required this.due});

  final DateTime start;
  final DateTime end;
  final DateTime due;
}

class _CardSpendStats {
  _CardSpendStats({
    required this.window,
    required this.charges,
    required this.payments,
    required this.netSpend,
    required this.available,
    required this.utilization,
  });

  final _StatementWindow window;
  final double charges;
  final double payments;
  final double netSpend;
  final double? available;
  final double? utilization;
}

class _PaymentDraft {
  const _PaymentDraft({required this.amount, required this.currency, required this.date, required this.accountId, this.note});

  final double amount;
  final String currency;
  final DateTime date;
  final String? accountId;
  final String? note;
}

int _daysInMonth(int year, int month) {
  final nextMonth = (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
  return nextMonth.subtract(const Duration(days: 1)).day;
}

DateTime _safeDate(int year, int month, int day) {
  var y = year;
  var m = month;
  while (m <= 0) {
    m += 12;
    y -= 1;
  }
  while (m > 12) {
    m -= 12;
    y += 1;
  }
  final clampedDay = day.clamp(1, _daysInMonth(y, m));
  return DateTime(y, m, clampedDay);
}
