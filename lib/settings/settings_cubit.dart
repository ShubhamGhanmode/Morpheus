import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/cards/card_repository.dart';
import 'package:morpheus/config/app_config.dart';
import 'package:morpheus/services/app_lock_service.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/settings/settings_repository.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/theme_contrast.dart';
import 'package:morpheus/utils/error_mapper.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void setThemeMode(ThemeMode mode) {
    emit(state.copyWith(themeMode: mode, error: null));
    _repository.saveThemeMode(mode).catchError((e, stack) {
      unawaited(
        ErrorReporter.recordError(
          e,
          stack,
          reason: 'Save theme mode failed',
        ),
      );
      emit(state.copyWith(error: errorMessage(e, action: 'Save theme')));
    });
  }

  void setContrast(AppContrast contrast) {
    emit(state.copyWith(contrast: contrast, error: null));
    _repository.saveContrast(contrast).catchError((e, stack) {
      unawaited(
        ErrorReporter.recordError(
          e,
          stack,
          reason: 'Save contrast failed',
        ),
      );
      emit(state.copyWith(error: errorMessage(e, action: 'Save contrast')));
    });
  }

  Future<bool> setAppLockEnabled(bool enabled) async {
    emit(state.copyWith(error: null));
    if (enabled) {
      final supported = await _appLockService.isSupported();
      if (!supported) {
        emit(state.copyWith(error: 'Device authentication is not available.'));
        return false;
      }
      final authenticated = await _appLockService.authenticate(
        reason: 'Enable app lock',
      );
      if (!authenticated) {
        emit(state.copyWith(error: 'Authentication was cancelled.'));
        return false;
      }
    }
    emit(state.copyWith(appLockEnabled: enabled));
    try {
      await _repository.saveAppLockEnabled(enabled);
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Save app lock failed');
      emit(state.copyWith(error: errorMessage(e, action: 'Save app lock')));
    }
    return true;
  }

  void setTestModeEnabled(bool enabled) {
    emit(state.copyWith(testModeEnabled: enabled, error: null));
    _repository.saveTestModeEnabled(enabled).catchError((e, stack) {
      unawaited(
        ErrorReporter.recordError(
          e,
          stack,
          reason: 'Save test mode failed',
        ),
      );
      emit(state.copyWith(error: errorMessage(e, action: 'Save test mode')));
    });
  }

  Future<void> setBaseCurrency(String currency) async {
    emit(state.copyWith(baseCurrency: currency, error: null));
    try {
      await _repository.saveBaseCurrency(currency);
      await _persistUserSettings({'baseCurrency': currency});
    } catch (e, stack) {
      await ErrorReporter.recordError(e, stack, reason: 'Save base currency failed');
      emit(state.copyWith(error: errorMessage(e, action: 'Save base currency')));
    }
  }

  void setReceiptOcrProvider(ReceiptOcrProvider provider) {
    emit(state.copyWith(receiptOcrProvider: provider, error: null));
    _repository.saveReceiptOcrProvider(provider).catchError((e, stack) {
      unawaited(
        ErrorReporter.recordError(
          e,
          stack,
          reason: 'Save receipt OCR provider failed',
        ),
      );
      emit(
        state.copyWith(
          error: errorMessage(e, action: 'Save receipt OCR provider'),
        ),
      );
    });
  }

  Future<void> setCardRemindersEnabled(bool enabled) async {
    emit(state.copyWith(cardRemindersEnabled: enabled, error: null));
    try {
      await _repository.saveCardRemindersEnabled(enabled);
      await _persistUserSettings({'cardRemindersEnabled': enabled});
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Save card reminders setting failed',
      );
      emit(
        state.copyWith(
          error: errorMessage(e, action: 'Save card reminders setting'),
        ),
      );
    }
    try {
      await _notificationService.setCardRemindersEnabled(enabled);
      if (enabled) {
        final cards = await _cardRepository.fetchCards();
        await _notificationService.scheduleCardReminders(cards);
      }
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Toggle card reminders failed',
      );
      emit(
        state.copyWith(
          error: errorMessage(e, action: 'Update card reminders'),
        ),
      );
    }
  }

  Future<void> _persistUserSettings(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Persist user settings failed',
      );
      emit(state.copyWith(error: errorMessage(e, action: 'Save settings')));
    }
  }
}
