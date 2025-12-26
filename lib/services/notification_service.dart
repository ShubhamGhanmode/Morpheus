import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:morpheus/utils/statement_dates.dart';

import '../creditcard_management_page.dart';

/// Centralized notification pipeline that wires Firebase Cloud Messaging,
/// local notifications, and scheduling for in-app reminders.
class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _localReady = false;
  bool _timezoneReady = false;
  bool _messagingReady = false;
  bool _cardRemindersEnabled = true;

  final _cardNotificationIds = <int>{};
  Future<void> _scheduleQueue = Future.value();
  static const _cardReminderIdsKey = 'notifications.cardReminderIds';

  /// Call once during app startup.
  Future<void> initialize() async {
    await _ensureLocal();
    await _configureTimeZone();
    await _configureMessaging();
  }

  Future<void> _ensureLocal() async {
    if (_localReady) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: iOS),
    );
    await _loadStoredCardReminderIds();
    _localReady = true;
  }

  Future<void> _configureTimeZone() async {
    if (_timezoneReady) return;
    tz.initializeTimeZones();
    var resolved = 'UTC';
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      resolved = info.identifier;
      tz.setLocalLocation(tz.getLocation(resolved));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    await _persistTimezone(resolved);
    _timezoneReady = true;
  }

  Future<void> _persistTimezone(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(
            {
              'timezone': id,
              'timezoneUpdatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (_) {}
  }

  Future<void> _configureMessaging() async {
    if (_messagingReady) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      provisional: false,
      carPlay: false,
      criticalAlert: false,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _persistToken(token);
    }
    messaging.onTokenRefresh.listen(_persistToken);

    FirebaseMessaging.onMessage.listen(handleRemoteMessage);
    _messagingReady = true;
  }

  Future<void> handleRemoteMessage(RemoteMessage message) async {
    await _ensureLocal();
    await _configureTimeZone();

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Morpheus';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'You have a new update';
    await showInstantNotification(title, body);
  }

  Future<void> showInstantNotification(String title, String body) async {
    await _ensureLocal();
    final details = _defaultDetails();
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }

  Future<void> sendTestPush({
    required String title,
    required String body,
    String? cardId,
  }) async {
    final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('sendTestPush');
    await callable.call(<String, dynamic>{
      'title': title,
      'body': body,
      if (cardId != null) 'cardId': cardId,
    });
  }

  /// Schedule reminders for all cards. Cancels previous card reminders
  /// to keep notifications in sync with current settings.
  Future<void> scheduleCardReminders(List<CreditCard> cards) async {
    final next = _scheduleQueue.then((_) async {
      await _ensureLocal();
      await _configureTimeZone();
      if (!_cardRemindersEnabled) {
        await _clearCardReminders();
        return;
      }
      await _clearCardReminders();
      final scheduleMode = await _resolveScheduleMode();

      for (final card in cards) {
        if (!card.reminderEnabled || card.reminderOffsets.isEmpty) continue;
        final due = _nextDue(card);
        final offsets = {...card.reminderOffsets.where((d) => d > 0)};
        if (offsets.isEmpty) continue;
        for (final offset in offsets) {
          var scheduleAt = due.subtract(Duration(days: offset));
          if (scheduleAt.isBefore(DateTime.now())) {
            final nextDue =
                _nextDue(card, anchor: due.add(const Duration(days: 1)));
            scheduleAt = nextDue.subtract(Duration(days: offset));
          }
          if (scheduleAt.isBefore(DateTime.now())) continue;
          final id = _stableId('card-${card.id}-$offset');
          _cardNotificationIds.add(id);
          await _scheduleCardReminder(
            id: id,
            card: card,
            due: due,
            scheduledAt: scheduleAt,
            scheduleMode: scheduleMode,
          );
        }
      }
      await _persistCardReminderIds();
    });
    _scheduleQueue = next.catchError((_) {});
    return next;
  }

  Future<void> setCardRemindersEnabled(bool enabled) async {
    _cardRemindersEnabled = enabled;
    if (!enabled) {
      await _ensureLocal();
      await _clearCardReminders();
    }
  }

  Future<void> _scheduleCardReminder({
    required int id,
    required CreditCard card,
    required DateTime due,
    required DateTime scheduledAt,
    required AndroidScheduleMode scheduleMode,
  }) async {
    try {
      await _local.zonedSchedule(
        id,
        'Card payment due soon',
        '${card.bankName} due on ${_fmtDate(due)}',
        tz.TZDateTime.from(scheduledAt, tz.local),
        _defaultDetails(),
        androidScheduleMode: scheduleMode,
        payload: 'card:${card.id}',
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted' &&
          scheduleMode != AndroidScheduleMode.inexactAllowWhileIdle) {
        await _local.zonedSchedule(
          id,
          'Card payment due soon',
          '${card.bankName} due on ${_fmtDate(due)}',
          tz.TZDateTime.from(scheduledAt, tz.local),
          _defaultDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'card:${card.id}',
          matchDateTimeComponents: DateTimeComponents.dateAndTime,
        );
        return;
      }
      rethrow;
    }
  }

  Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    final android = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    try {
      final canExact = await android.canScheduleExactNotifications();
      if (canExact == true) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (_) {
      // Fall back to inexact scheduling if permission check fails.
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'morpheus_reminders',
        'Reminders',
        channelDescription: 'Card payment reminders and alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _clearCardReminders() async {
    final toCancel = List<int>.from(_cardNotificationIds);
    _cardNotificationIds.clear();
    for (final id in toCancel) {
      await _local.cancel(id);
    }
    await _persistCardReminderIds();
  }

  Future<void> _loadStoredCardReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_cardReminderIdsKey) ?? const [];
    final parsed = stored
        .map((e) => int.tryParse(e))
        .whereType<int>()
        .toList();
    _cardNotificationIds
      ..clear()
      ..addAll(parsed);
  }

  Future<void> _persistCardReminderIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cardNotificationIds.map((e) => e.toString()).toList();
    await prefs.setStringList(_cardReminderIdsKey, list);
  }

  Future<void> _persistToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final platforms = Platform.operatingSystem;
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('deviceTokens');
    await col.doc(token).set({
      'token': token,
      'platform': platforms,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCurrentToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('deviceTokens')
          .doc(token)
          .delete();
    } catch (_) {}
  }

  DateTime _nextDue(CreditCard card, {DateTime? anchor}) {
    return nextDueDate(
      now: anchor ?? DateTime.now(),
      billingDay: card.billingDay,
      graceDays: card.graceDays,
    );
  }

  int _stableId(String seed) => seed.hashCode & 0x7fffffff;

  String _fmtDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
