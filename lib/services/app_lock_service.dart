import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:morpheus/services/error_reporter.dart';

class AppLockService {
  AppLockService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck || supported;
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Check device auth support failed',
      );
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock Morpheus'}) async {
    if (kIsWeb) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e, stack) {
      await ErrorReporter.recordError(
        e,
        stack,
        reason: 'Biometric auth failed',
      );
      return false;
    }
  }

  Future<void> cancel() async {
    if (kIsWeb) return;
    await _auth.stopAuthentication();
  }
}
