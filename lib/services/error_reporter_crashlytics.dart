import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsReporter {
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(true);
  }

  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterFatalError(details);
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
    Map<String, String>? context,
  }) async {
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      information: [
        if (context != null) context,
      ],
    );
  }

  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  Future<void> setUserIdentifier(String id) async {
    await _crashlytics.setUserIdentifier(id);
  }
}
