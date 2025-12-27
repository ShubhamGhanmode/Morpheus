import 'package:flutter/foundation.dart';

class CrashlyticsReporter {
  Future<void> initialize() async {}

  Future<void> recordFlutterError(FlutterErrorDetails details) async {}

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
    Map<String, String>? context,
  }) async {}

  Future<void> log(String message) async {}

  Future<void> setUserIdentifier(String id) async {}
}
