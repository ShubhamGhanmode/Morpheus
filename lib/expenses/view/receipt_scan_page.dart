import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/expense_category.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/expenses/bloc/expense_bloc.dart';
import 'package:morpheus/expenses/constants/category_rule_suggestions.dart';
import 'package:morpheus/expenses/models/expense.dart';
import 'package:morpheus/expenses/models/receipt_line_item.dart';
import 'package:morpheus/expenses/receipt_scan_cubit.dart';
import 'package:morpheus/settings/settings_cubit.dart';

class ReceiptScanPage extends StatelessWidget {
  const ReceiptScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!AppConfig.enableReceiptScanning) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Receipt')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withOpacity(0.3), shape: BoxShape.circle),
                  child: Icon(Icons.receipt_long_outlined, size: 48, color: theme.colorScheme.error.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                Text('Receipt Scanning Disabled', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'This feature is currently disabled in app settings.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final settings = context.watch<SettingsCubit>().state;
    final categories = context.watch<CategoryCubit>().state.items;
    final defaultCategory = categories.isNotEmpty ? categories.first.name : null;

    return BlocProvider(
      create: (_) => ReceiptScanCubit(
        defaultCurrency: settings.baseCurrency,
        ocrProvider: settings.receiptOcrProvider,
        defaultCategory: defaultCategory,
      ),
      child: const _ReceiptScanView(),
    );
  }
}

class _ReceiptScanView extends StatefulWidget {
  const _ReceiptScanView();

  @override
  State<_ReceiptScanView> createState() => _ReceiptScanViewState();
}

class _ReceiptScanViewState extends State<_ReceiptScanView> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _merchantCtrl = TextEditingController();

  @override
  void dispose() {
    _merchantCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final mimeType = _mimeTypeForPath(file.path);
    if (!mounted) return;
    context.read<ReceiptScanCubit>().scanReceipt(bytes: bytes, mimeType: mimeType, imagePath: file.path);
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryState = context.watch<CategoryCubit>().state;
    final categories = categoryState.items;
    final categoryEmojis = {for (final c in categories) c.name: c.resolvedEmoji};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        centerTitle: false,
        actions: [
          BlocBuilder<ReceiptScanCubit, ReceiptScanState>(
            builder: (context, state) {
              if (state.status == ReceiptScanStatus.idle) {
                return const SizedBox.shrink();
              }
              return IconButton(
                tooltip: 'Start over',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<ReceiptScanCubit>().reset(),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<ReceiptScanCubit, ReceiptScanState>(
        listenWhen: (previous, current) => previous.error != current.error && current.error != null,
        listener: (context, state) {
          if (state.error == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error!),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
        builder: (context, state) {
          final merchantText = state.merchant ?? '';
          if (_merchantCtrl.text != merchantText) {
            _merchantCtrl.text = merchantText;
            _merchantCtrl.selection = TextSelection.collapsed(offset: merchantText.length);
          }
          if (categories.isNotEmpty && (state.category == null || !categories.any((c) => c.name == state.category))) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<ReceiptScanCubit>().setCategory(categories.first.name);
            });
          }
          if (state.status == ReceiptScanStatus.ready && categories.isNotEmpty && !state.ruleBasedApplied) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              context.read<ReceiptScanCubit>().applyRuleBasedCategories(categories);
            });
          }

          // Initial state - show capture options
          if (state.status == ReceiptScanStatus.idle) {
            return _InitialCaptureView(
              onCamera: () => _pickImage(ImageSource.camera),
              onGallery: () => _pickImage(ImageSource.gallery),
            );
          }

          // Scanning state
          if (state.status == ReceiptScanStatus.scanning) {
            return _ScanningView(imageBytes: state.imageBytes);
          }

          // Error state
          if (state.status == ReceiptScanStatus.error) {
            return _ErrorView(
              imageBytes: state.imageBytes,
              onRetry: () => context.read<ReceiptScanCubit>().retryScan(),
              onNewImage: () => _pickImage(ImageSource.gallery),
            );
          }

          // Ready state - show items
          return _ReadyView(
            state: state,
            categories: categories,
            categoryEmojis: categoryEmojis,
            merchantController: _merchantCtrl,
            onConfirm: () => _confirmExpenses(context, state, categories),
          );
        },
      ),
    );
  }

  void _confirmExpenses(BuildContext context, ReceiptScanState state, List<ExpenseCategory> categories) {
    final fallbackCategory = state.category ?? (categories.isNotEmpty ? categories.first.name : null);
    if (fallbackCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category first.')));
      return;
    }

    final currency = state.currency ?? AppConfig.baseCurrency;
    final date = state.receiptDate ?? DateTime.now();
    final merchantLabel = state.merchant?.trim();
    final groupTimestamp = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
    final groupNameBase = merchantLabel != null && merchantLabel.isNotEmpty ? merchantLabel : 'Receipt';
    final groupName = '$groupNameBase $groupTimestamp';
    final validItems = <ReceiptLineItem>[];
    for (final item in state.items) {
      if (item.name.trim().isEmpty || item.amount == null) continue;
      validItems.add(item);
    }

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one valid item.')));
      return;
    }

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one valid item.')));
      return;
    }

    final expenses = <Expense>[];
    for (final item in validItems) {
      final category = item.category ?? fallbackCategory;
      if (category.isEmpty) continue;
      expenses.add(
        Expense.create(
          title: item.name.trim(),
          amount: item.amount ?? 0,
          currency: currency,
          category: category,
          date: date,
          note: merchantLabel == null || merchantLabel.isEmpty ? 'Receipt scan' : 'Receipt: $merchantLabel',
        ),
      );
    }

    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select categories for your items.')));
      return;
    }

    context.read<ExpenseBloc>().add(
      AddGroupedExpenses(
        expenses: expenses,
        groupName: groupName,
        merchant: merchantLabel,
        receiptImageUri: state.receiptImageUri,
        receiptDate: state.receiptDate,
      ),
    );
    Navigator.of(context).pop();
  }
}

// ============================================================================
// Initial Capture View - Beautiful hero section with capture options
// ============================================================================

class _InitialCaptureView extends StatelessWidget {
  const _InitialCaptureView({required this.onCamera, required this.onGallery});

  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(flex: 1),
            // Hero illustration
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [theme.colorScheme.primaryContainer, theme.colorScheme.primaryContainer.withOpacity(0.3)],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.receipt_long_rounded, size: 80, color: theme.colorScheme.primary),
                  Positioned(
                    right: 30,
                    bottom: 30,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Icon(Icons.auto_awesome, size: 24, color: theme.colorScheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Title and description
            Text(
              'Scan Your Receipt',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo or select an image of your receipt.\nWe\'ll extract the items automatically.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const Spacer(flex: 2),
            // Capture buttons
            Row(
              children: [
                Expanded(
                  child: _CaptureButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    description: 'Take a photo',
                    onTap: onCamera,
                    isPrimary: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CaptureButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    description: 'Choose image',
                    onTap: onGallery,
                    isPrimary: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 20, color: theme.colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'For best results, ensure good lighting and a flat surface',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isPrimary ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isPrimary ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: isPrimary ? theme.colorScheme.onPrimary : theme.colorScheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isPrimary ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isPrimary ? theme.colorScheme.onPrimaryContainer.withOpacity(0.7) : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Scanning View - Loading state with image preview
// ============================================================================

class _ScanningView extends StatelessWidget {
  const _ScanningView({this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageBytes != null)
              Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes!, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, theme.colorScheme.surface.withOpacity(0.8)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
              child: const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 3)),
            ),
            const SizedBox(height: 24),
            Text('Analyzing Receipt', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Extracting items and prices...',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Error View - Friendly error state with retry options
// ============================================================================

class _ErrorView extends StatelessWidget {
  const _ErrorView({this.imageBytes, required this.onRetry, required this.onNewImage});

  final Uint8List? imageBytes;
  final VoidCallback onRetry;
  final VoidCallback onNewImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageBytes != null)
              Container(
                height: 160,
                width: 160,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(imageBytes!, fit: BoxFit.cover),
                      Container(color: theme.colorScheme.error.withOpacity(0.3)),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: theme.colorScheme.errorContainer, shape: BoxShape.circle),
                          child: Icon(Icons.error_outline_rounded, size: 32, color: theme.colorScheme.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (imageBytes == null)
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withOpacity(0.3), shape: BoxShape.circle),
                child: Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
              ),
            Text('Scan Failed', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t read this receipt.\nTry again with better lighting or a clearer image.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try Again')),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onNewImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('New Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Ready View - Display extracted items with editing capabilities
// ============================================================================

class _ReadyView extends StatelessWidget {
  const _ReadyView({
    required this.state,
    required this.categories,
    required this.categoryEmojis,
    required this.merchantController,
    required this.onConfirm,
  });

  final ReceiptScanState state;
  final List<ExpenseCategory> categories;
  final Map<String, String> categoryEmojis;
  final TextEditingController merchantController;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<ReceiptScanCubit>();
    final currency = state.currency ?? AppConfig.baseCurrency;
    final fmt = NumberFormat.simpleCurrency(name: currency);

    // Calculate totals
    final itemTotal = state.items.fold<double>(0, (sum, item) => sum + (item.amount ?? 0));
    final validItemCount = state.items.where((i) => i.name.trim().isNotEmpty && i.amount != null).length;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              // Receipt Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _ReceiptHeaderCard(
                    state: state,
                    merchantController: merchantController,
                    onMerchantChanged: cubit.setMerchant,
                    onCurrencyChanged: cubit.setCurrency,
                    onDateChanged: cubit.setReceiptDate,
                    fmt: fmt,
                  ),
                ),
              ),

              // Items Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 10),
                      Text('Items', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        '${state.items.length} detected',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),

              // Items List
              if (state.items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.outlineVariant, style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_shopping_cart_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text('No items detected', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(
                            'Add items manually below',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = state.items[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _EnhancedItemCard(
                          item: item,
                          index: index,
                          categories: categories,
                          categoryEmojis: categoryEmojis,
                          selectedCategory: item.category ?? state.category,
                          onCategoryChanged: (value) {
                            if (value == null) return;
                            cubit.setItemCategory(item.id, value);
                          },
                          onNameChanged: (value) => cubit.updateItemName(item.id, value),
                          onAmountChanged: (value) => cubit.updateItemAmount(item.id, value),
                          onRemove: () => cubit.removeItem(item.id),
                        ),
                      );
                    }, childCount: state.items.length),
                  ),
                ),

              // Add Item Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton.icon(
                    onPressed: cubit.addEmptyItem,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Item'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),

        // Bottom Action Bar
        Container(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(fmt.format(itemTotal), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$validItemCount items',
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: validItemCount > 0 ? onConfirm : null,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Add Expenses'),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Receipt Header Card - Merchant, date, and totals summary
// ============================================================================

class _ReceiptHeaderCard extends StatelessWidget {
  const _ReceiptHeaderCard({
    required this.state,
    required this.merchantController,
    required this.onMerchantChanged,
    required this.onCurrencyChanged,
    required this.onDateChanged,
    required this.fmt,
  });

  final ReceiptScanState state;
  final TextEditingController merchantController;
  final ValueChanged<String> onMerchantChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<DateTime> onDateChanged;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = state.receiptDate;
    final hasImage = state.imageBytes != null;
    final dateLabel = date != null ? DateFormat.yMMMd().format(date) : 'Select date';
    final now = DateTime.now();
    final firstDate = DateTime(2000);

    Future<void> pickDate() async {
      var initialDate = date ?? now;
      if (initialDate.isAfter(now)) {
        initialDate = now;
      } else if (initialDate.isBefore(firstDate)) {
        initialDate = firstDate;
      }
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: now,
      );
      if (!context.mounted || picked == null) return;
      onDateChanged(picked);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.secondaryContainer, theme.colorScheme.primaryContainer.withValues(alpha: 0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image preview row
          if (hasImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(state.imageBytes!, width: 72, height: 72, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.tertiaryContainer,
                                theme.colorScheme.tertiaryContainer.withValues(alpha: 0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: theme.colorScheme.onTertiaryContainer),
                              const SizedBox(width: 6),
                              Text(
                                'Scanned Successfully',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onTertiaryContainer,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (date != null)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat.yMMMd().format(date),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
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

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Receipt Details',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Merchant field
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: merchantController,
                    decoration: InputDecoration(
                      labelText: 'Merchant / Store Name',
                      hintText: 'e.g., Walmart, Target',
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.store_rounded, color: theme.colorScheme.primary),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: onMerchantChanged,
                  ),
                ),

                const SizedBox(height: 14),

                // Currency selector
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: state.currency ?? AppConfig.supportedCurrencies.first,
                    items: AppConfig.supportedCurrencies.map((c) => DropdownMenuItem<String>(value: c, child: Text(c))).toList(),
                    onChanged: onCurrencyChanged,
                    decoration: InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Container(
                        margin: const EdgeInsets.only(left: 12, right: 8),
                        child: Icon(Icons.currency_exchange_rounded, color: theme.colorScheme.primary),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Receipt date selector
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Receipt date',
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(left: 12, right: 8),
                            child: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        child: Text(
                          dateLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: date != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                            fontWeight: date != null ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Receipt totals (if available)
                if (state.total != null || state.subtotal != null || state.tax != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [theme.colorScheme.surface, theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_rounded, size: 18, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Receipt Summary',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (state.subtotal != null)
                          _TotalRow(label: 'Subtotal', value: fmt.format(state.subtotal!), theme: theme),
                        if (state.tax != null) ...[
                          if (state.subtotal != null) const SizedBox(height: 10),
                          _TotalRow(label: 'Tax', value: fmt.format(state.tax!), theme: theme),
                        ],
                        if (state.total != null) ...[
                          if (state.subtotal != null || state.tax != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Container(
                                height: 1,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.transparent, theme.colorScheme.outlineVariant, Colors.transparent],
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _TotalRow(
                              label: 'Total (from receipt)',
                              value: fmt.format(state.total!),
                              theme: theme,
                              isBold: true,
                            ),
                          ),
                        ],
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, required this.theme, this.isBold = false});

  final String label;
  final String value;
  final ThemeData theme;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: isBold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}

// ============================================================================
// Enhanced Item Card - Beautiful item editing card
// ============================================================================

class _EnhancedItemCard extends StatelessWidget {
  const _EnhancedItemCard({
    required this.item,
    required this.index,
    required this.categories,
    required this.categoryEmojis,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.onNameChanged,
    required this.onAmountChanged,
    required this.onRemove,
  });

  final ReceiptLineItem item;
  final int index;
  final List<ExpenseCategory> categories;
  final Map<String, String> categoryEmojis;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestions = ruleBasedCategorySuggestions(title: item.name, categories: categories, limit: 3);
    final categoryMap = {for (final c in categories) c.name: c.label};
    final resolvedCategory = categories.any((c) => c.name == selectedCategory)
        ? selectedCategory
        : (categories.isNotEmpty ? categories.first.name : null);
    final emoji = categoryEmojis[resolvedCategory] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with index and remove button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    categoryMap[resolvedCategory] ?? 'Category',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.error.withOpacity(0.8)),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Remove item',
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and amount in row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: TextFormField(
                        key: ValueKey('${item.id}-name'),
                        initialValue: item.name,
                        decoration: InputDecoration(
                          labelText: 'Item name',
                          hintText: 'e.g., Coffee',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: onNameChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        key: ValueKey('${item.id}-amount'),
                        initialValue: item.amountText,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        onChanged: onAmountChanged,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: resolvedCategory,
                  isExpanded: true,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.name,
                          child: Row(children: [Text(c.label)]),
                        ),
                      )
                      .toList(),
                  onChanged: categories.isEmpty ? null : onCategoryChanged,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),

                // Quick category suggestions
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Suggestions', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: suggestions.map((suggestion) {
                      final isSelected = suggestion == selectedCategory;
                      final suggestionEmoji = categoryEmojis[suggestion] ?? '';
                      final label = categoryMap[suggestion] ?? suggestion;
                      return InkWell(
                        onTap: () => onCategoryChanged(suggestion),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected ? Border.all(color: theme.colorScheme.primary) : null,
                          ),
                          child: Text(
                            label,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
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
