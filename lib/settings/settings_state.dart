import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/theme/theme_contrast.dart';

class SettingsState {
  final ThemeMode themeMode;
  final AppContrast contrast;
  final bool cardRemindersEnabled;
  final bool appLockEnabled;
  final bool testModeEnabled;
  final String baseCurrency;
  final ReceiptOcrProvider receiptOcrProvider;
  final String? error;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.contrast = AppContrast.normal,
    this.cardRemindersEnabled = true,
    this.appLockEnabled = false,
    this.testModeEnabled = false,
    this.baseCurrency = AppConfig.baseCurrency,
    this.receiptOcrProvider = AppConfig.defaultReceiptOcrProvider,
    this.error,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppContrast? contrast,
    bool? cardRemindersEnabled,
    bool? appLockEnabled,
    bool? testModeEnabled,
    String? baseCurrency,
    ReceiptOcrProvider? receiptOcrProvider,
    String? error,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      contrast: contrast ?? this.contrast,
      cardRemindersEnabled: cardRemindersEnabled ?? this.cardRemindersEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      receiptOcrProvider: receiptOcrProvider ?? this.receiptOcrProvider,
      error: error,
    );
  }
}
