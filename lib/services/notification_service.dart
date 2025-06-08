import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    await AwesomeNotifications().initialize(
      null, // null means use default app icon
      [
        NotificationChannel(
          channelKey: 'daily_reminder_channel',
          channelName: 'Daily Reminders',
          channelDescription: 'Daily reminders for blood pressure checks',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: const Color(0xFF4CAF50),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
        NotificationChannel(
          channelKey: 'one_time_reminder_channel',
          channelName: 'One-time Reminders',
          channelDescription: 'One-time reminders for blood pressure checks',
          defaultColor: const Color(0xFF4CAF50),
          ledColor: const Color(0xFF4CAF50),
          importance: NotificationImportance.High,
          channelShowBadge: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
    );
  }

  Future<void> requestPermissions() async {
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the time has already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 0,
        channelKey: 'daily_reminder_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        hour: hour,
        minute: minute,
        second: 0,
        millisecond: 0,
        repeats: true,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> scheduleOneTimeReminder({
    required DateTime scheduledDate,
    required String title,
    required String body,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'one_time_reminder_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar.fromDate(
        date: scheduledDate,
        preciseAlarm: true,
      ),
    );
  }

  Future<void> cancelReminder(int id) async {
    await AwesomeNotifications().cancel(id);
  }

  Future<void> cancelAllReminders() async {
    await AwesomeNotifications().cancelAll();
  }

  Future<void> dispose() async {
    await AwesomeNotifications().cancelAll();
  }
} 