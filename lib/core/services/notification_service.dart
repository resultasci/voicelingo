import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'settings_service.dart';

class NotificationService {
  NotificationService(this._settings);

  final SettingsService _settings;

  /// Stable id for the recurring "you have N words due today" reminder.
  static const int _dailyReminderId = 1001;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsDarwin =
        const DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {
        // İleride uygulamanın navigasyonuna bağlanabilir
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  /// Belirtilen SM-2 kelimesinin 'next_review' tarihi geldiğinde atılacak bir hatırlatıcı planlar
  Future<void> scheduleReviewReminder(
      int id, String title, String body, DateTime scheduledTime) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'voicelingo_review_channel',
          'Review Reminders',
          channelDescription: 'Reminders for your SM-2 vocabulary reviews',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  /// Daily aggregate "you have N words due" reminder. Cancels and reschedules
  /// itself idempotently — safe to call after every word load.
  Future<void> scheduleDailyReviewReminder(int dueCount) async {
    if (!_settings.notificationsEnabled) return;

    await flutterLocalNotificationsPlugin.cancel(_dailyReminderId);
    if (dueCount <= 0) return;

    final hour = _settings.reviewHour;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      _dailyReminderId,
      'Tekrar Zamanı',
      '$dueCount kelimen bugün tekrar bekliyor 🧠',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'voicelingo_daily_channel',
          'Daily Review Reminder',
          channelDescription: 'Daily nudge to review your due vocabulary',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await flutterLocalNotificationsPlugin.cancel(_dailyReminderId);
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelAll() => cancelAllNotifications();
}

/// Gerçek instance bootstrap'taki ProviderScope override'ından gelir —
/// `runApp`'ten önce `init()` tamamlanmış olur.
final notificationServiceProvider = Provider<NotificationService>(
  (_) => throw UnimplementedError(
      'notificationServiceProvider bootstrap içinde override edilir'),
);
