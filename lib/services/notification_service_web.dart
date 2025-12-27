import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:morpheus/cards/models/credit_card.dart';
import 'package:morpheus/expenses/models/subscription.dart';
import 'package:morpheus/services/error_reporter.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  Future<void> initialize() async {}

  Future<void> handleRemoteMessage(RemoteMessage message) async {}

  Future<void> showInstantNotification(String title, String body) async {
    if (kDebugMode) {
      debugPrint('[notification] $title: $body');
    }
  }

  Future<void> sendTestPush({
    required String title,
    required String body,
    String? cardId,
  }) async {
    await ErrorReporter.log('Test push not supported on web.');
  }

  Future<void> scheduleCardReminders(List<CreditCard> cards) async {}

  Future<void> scheduleSubscriptionReminders(
    List<Subscription> subscriptions,
  ) async {}

  Future<void> setCardRemindersEnabled(bool enabled) async {}

  Future<void> deleteCurrentToken() async {}
}
