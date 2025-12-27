import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'error_reporter_crashlytics_stub.dart'
    if (dart.library.io) 'error_reporter_crashlytics.dart';

class ErrorReporter {
  ErrorReporter._();

  static final CrashlyticsReporter _crashlytics = CrashlyticsReporter();
  static bool _sentryInitialized = false;

  static Future<void> initialize() async {
    await _crashlytics.initialize();
    _sentryInitialized = Sentry.isEnabled;
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      if (previousHandler != null) {
        previousHandler(details);
      }
      recordFlutterError(details, sendToSentry: !_sentryInitialized);
    };
    final previousPlatformHandler = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(
        error,
        stack,
        fatal: true,
        reason: 'Uncaught platform error',
        sendToSentry: !_sentryInitialized,
      );
      return previousPlatformHandler?.call(error, stack) ?? true;
    };
  }

  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    bool sendToSentry = true,
  }) async {
    final context = <String, String>{
      if (details.library != null) 'library': details.library!,
      if (details.context != null)
        'context': details.context.toString(),
    };
    _log('FlutterError', details.exception, details.stack, context);
    await _crashlytics.recordFlutterError(details);
    if (sendToSentry) {
      await _captureSentry(
        details.exception,
        details.stack ?? StackTrace.current,
        context,
        'flutter',
      );
    }
  }

  static Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
    Map<String, String>? context,
    bool sendToSentry = true,
  }) async {
    _log(reason ?? 'Error', error, stack, context);
    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
      context: context,
    );
    if (sendToSentry) {
      await _captureSentry(
        error,
        stack,
        context,
        reason ?? 'error',
      );
    }
  }

  static Future<void> log(String message) async {
    debugPrint('[log] $message');
    await _crashlytics.log(message);
    await Sentry.addBreadcrumb(Breadcrumb(message: message));
  }

  static void _log(
    String label,
    Object error,
    StackTrace? stack,
    Map<String, String>? context,
  ) {
    debugPrint('[error] $label: $error');
    if (context != null && context.isNotEmpty) {
      debugPrint('[error] context: $context');
    }
    if (stack != null) {
      debugPrint('[error] stack: $stack');
    }
  }

  static Future<void> _captureSentry(
    Object error,
    StackTrace stack,
    Map<String, String>? context,
    String reason,
  ) async {
    await Sentry.captureException(
      error,
      stackTrace: stack,
      withScope: (scope) {
        scope.setTag('reason', reason);
        if (context != null) {
          scope.setContexts('context', context);
        }
      },
    );
  }
}
