import 'package:flutter/material.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _themeModeKey = 'settings.themeMode';
  static const _contrastKey = 'settings.contrast';
  static const _cardRemindersKey = 'settings.cardRemindersEnabled';
  static const _appLockKey = 'settings.appLockEnabled';
  static const _testModeKey = 'settings.testModeEnabled';
  static const _baseCurrencyKey = 'settings.baseCurrency';
  static const _receiptOcrProviderKey = 'settings.receiptOcrProvider';

  Future<SettingsState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeModeKey);
    final contrastName = prefs.getString(_contrastKey);
    final reminders = prefs.getBool(_cardRemindersKey);
    final appLock = prefs.getBool(_appLockKey);
    final testMode = prefs.getBool(_testModeKey);
    final baseCurrency = prefs.getString(_baseCurrencyKey);
    final receiptOcrProvider = prefs.getString(_receiptOcrProviderKey);

    return SettingsState(
      themeMode: _parseThemeMode(themeName),
      contrast: _parseContrast(contrastName),
      cardRemindersEnabled: reminders ?? true,
      appLockEnabled: appLock ?? false,
      testModeEnabled: testMode ?? false,
      baseCurrency: baseCurrency ?? AppConfig.baseCurrency,
      receiptOcrProvider: _parseReceiptOcrProvider(receiptOcrProvider),
    );
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  Future<void> saveContrast(AppContrast contrast) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contrastKey, contrast.name);
  }

  Future<void> saveCardRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cardRemindersKey, enabled);
  }

  Future<void> saveAppLockEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_appLockKey, enabled);
  }

  Future<void> saveTestModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_testModeKey, enabled);
  }

  Future<void> saveBaseCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseCurrencyKey, currency);
  }

  Future<void> saveReceiptOcrProvider(ReceiptOcrProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_receiptOcrProviderKey, provider.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    if (value == null) return ThemeMode.system;
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  AppContrast _parseContrast(String? value) {
    if (value == null) return AppContrast.normal;
    return AppContrast.values.firstWhere(
      (contrast) => contrast.name == value,
      orElse: () => AppContrast.normal,
    );
  }

  ReceiptOcrProvider _parseReceiptOcrProvider(String? value) {
    if (value == null) return AppConfig.defaultReceiptOcrProvider;
    return ReceiptOcrProvider.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => AppConfig.defaultReceiptOcrProvider,
    );
  }
}
