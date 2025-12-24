import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/services/app_lock_service.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/settings/settings_repository.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    SettingsRepository? repository,
    SettingsState? initialState,
    AppLockService? appLockService,
    NotificationService? notificationService,
    CardRepository? cardRepository,
  })  : _repository = repository ?? SettingsRepository(),
        _appLockService = appLockService ?? AppLockService(),
        _notificationService =
            notificationService ?? NotificationService.instance,
        _cardRepository = cardRepository ?? CardRepository(),
        super(initialState ?? const SettingsState()) {
    _notificationService.setCardRemindersEnabled(state.cardRemindersEnabled);
  }

  final SettingsRepository _repository;
  final AppLockService _appLockService;
  final NotificationService _notificationService;
  final CardRepository _cardRepository;

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode));
    _repository.saveThemeMode(mode);
  }

  void setContrast(AppContrast contrast) {
    emit(state.copyWith(contrast: contrast));
    _repository.saveContrast(contrast);
  }

  Future<bool> setAppLockEnabled(bool enabled) async {
    if (enabled) {
      final supported = await _appLockService.isSupported();
      if (!supported) {
        return false;
      }
      final authenticated = await _appLockService.authenticate(
        reason: 'Enable app lock',
      );
      if (!authenticated) {
        return false;
      }
    }
    emit(state.copyWith(appLockEnabled: enabled));
    await _repository.saveAppLockEnabled(enabled);
    return true;
  }

  void setTestModeEnabled(bool enabled) {
    emit(state.copyWith(testModeEnabled: enabled));
    _repository.saveTestModeEnabled(enabled);
  }

  Future<void> setCardRemindersEnabled(bool enabled) async {
    emit(state.copyWith(cardRemindersEnabled: enabled));
    await _repository.saveCardRemindersEnabled(enabled);
    try {
      await _notificationService.setCardRemindersEnabled(enabled);
      if (enabled) {
        final cards = await _cardRepository.fetchCards();
        await _notificationService.scheduleCardReminders(cards);
      }
    } catch (_) {}
  }
}
