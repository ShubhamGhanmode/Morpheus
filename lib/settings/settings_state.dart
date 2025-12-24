import 'package:flutter/material.dart';
import 'package:morpheus/theme/theme_contrast.dart';

class SettingsState {
  final ThemeMode themeMode;
  final AppContrast contrast;
  final bool cardRemindersEnabled;
  final bool appLockEnabled;
  final bool testModeEnabled;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.contrast = AppContrast.normal,
    this.cardRemindersEnabled = true,
    this.appLockEnabled = false,
    this.testModeEnabled = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    AppContrast? contrast,
    bool? cardRemindersEnabled,
    bool? appLockEnabled,
    bool? testModeEnabled,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      contrast: contrast ?? this.contrast,
      cardRemindersEnabled: cardRemindersEnabled ?? this.cardRemindersEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      testModeEnabled: testModeEnabled ?? this.testModeEnabled,
    );
  }
}
