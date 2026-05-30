import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/class_item.dart';
import '../data/schedule_manager.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _mobileNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool enabled = true;
  static int leadMinutes = 5;

  // In-memory set to prevent duplicate notification triggers on Windows
  static final Set<String> _notifiedKeys = {};

  /// Initialize the notification service for both mobile and Windows.
  static Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      // Set local timezone to Asia/Bangkok since ClassPulse is a Thai school app.
      tz.setLocalLocation(tz.getLocation('Asia/Bangkok'));
    } catch (e) {
      debugPrint('Error setting timezone: $e');
    }

    // 2. Load settings from SharedPreferences
    await loadSettings();

    // 3. Platform Specific Initialization
    if (kIsWeb) return;

    if (Platform.isWindows) {
      try {
        await localNotifier.setup(
          appName: 'ClassPulse',
          shortcutPolicy: ShortcutPolicy.requireCreate,
        );
      } catch (e) {
        debugPrint('Error initializing local_notifier on Windows: $e');
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings initializationSettingsDarwin =
            DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

        await _mobileNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            debugPrint('Notification clicked: ${details.payload}');
          },
        );
      } catch (e) {
        debugPrint('Error initializing flutter_local_notifications: $e');
      }
    }
  }

  /// Request permissions for mobile notifications.
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      final androidPlugin = _mobileNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Request POST_NOTIFICATIONS for Android 13+
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
    } else if (Platform.isIOS) {
      final iosPlugin = _mobileNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    }
    return true;
  }

  /// Load settings from SharedPreferences
  static Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool('notifications_enabled') ?? true;
      leadMinutes = prefs.getInt('notifications_lead_minutes') ?? 5;
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  /// Save settings to SharedPreferences and trigger rescheduling
  static Future<void> saveSettings({
    required bool isEnabled,
    required int leadMins,
    required Map<int, List<ClassItem>> schedule,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', isEnabled);
      await prefs.setInt('notifications_lead_minutes', leadMins);
      
      enabled = isEnabled;
      leadMinutes = leadMins;
      
      // Clear notified keys so newly scheduled times can trigger
      clearNotifiedKeys();

      // Reschedule everything
      await rescheduleAll(schedule);
    } catch (e) {
      debugPrint('Error saving notification settings: $e');
    }
  }

  /// Clear the notified keys list to allow testing alerts again
  static void clearNotifiedKeys() {
    _notifiedKeys.clear();
  }

  /// Reschedule all notifications for the given schedule weekly setup.
  static Future<void> rescheduleAll(Map<int, List<ClassItem>> schedule) async {
    if (kIsWeb) return;

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        // Cancel all existing scheduled notifications
        await _mobileNotificationsPlugin.cancelAll();

        if (!enabled) return;

        // Iterate days: 0 (Monday) to 4 (Friday)
        for (int dayIndex = 0; dayIndex < 5; dayIndex++) {
          final dayClasses = schedule[dayIndex] ?? [];
          final weekday = dayIndex + 1; // 1 = Monday, 5 = Friday in ISO standard

          for (int classIndex = 0; classIndex < dayClasses.length; classIndex++) {
            final item = dayClasses[classIndex];
            if (item.isBreak) continue;

            // Parse time
            final parts = item.startTime.split(':');
            if (parts.length != 2) continue;
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);

            // Unique Notification IDs: (dayIndex * 100) + (classIndex * 2) + offset
            final int idStart = (dayIndex * 100) + (classIndex * 2);
            final int idLead = idStart + 1;

            // Start Notification Time
            final tz.TZDateTime startDateTime = _nextInstanceOfWeekly(weekday, hour, minute);

            // 1. Schedule exact start time reminder
            await _mobileNotificationsPlugin.zonedSchedule(
              idStart,
              'ถึงเวลาเรียนวิชา ${item.subject} แล้ว!',
              'ห้องเรียน/ผู้สอน: ${item.teacher} (${item.startTime} - ${item.endTime} น.)',
              startDateTime,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'class_pulse_start_reminders',
                  'Class Start Reminders',
                  channelDescription: 'Alerts you exactly when a class starts.',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentSound: true,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );

            // 2. Schedule warning lead time reminder
            if (leadMinutes > 0) {
              final startLocal = DateTime(2026, 1, 1, hour, minute);
              final warnLocal = startLocal.subtract(Duration(minutes: leadMinutes));

              final tz.TZDateTime warnDateTime =
                  _nextInstanceOfWeekly(weekday, warnLocal.hour, warnLocal.minute);

              await _mobileNotificationsPlugin.zonedSchedule(
                idLead,
                'อีก $leadMinutes นาที จะถึงวิชา ${item.subject}',
                'เวลาเรียน: ${item.startTime} - ${item.endTime} น.',
                warnDateTime,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'class_pulse_lead_reminders',
                    'Class Advance Reminders',
                    channelDescription: 'Alerts you in advance before a class starts.',
                    importance: Importance.max,
                    priority: Priority.high,
                  ),
                  iOS: DarwinNotificationDetails(
                    presentAlert: true,
                    presentSound: true,
                  ),
                ),
                androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              );
            }
          }
        }
        debugPrint('Mobile notifications rescheduled successfully.');
      } catch (e) {
        debugPrint('Error scheduling mobile notifications: $e');
      }
    }
  }

  /// Calculate the next instance of weekly timezone schedule.
  static tz.TZDateTime _nextInstanceOfWeekly(int weekday, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Get the next day matching the weekday
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If the scheduled date is earlier than now, push to the next week
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Check active schedule for Windows and show notifications.
  /// This is called periodically (e.g. every 15-30s) by the app.
  static void checkWindowsNotifications(Map<int, List<ClassItem>> schedule) {
    if (!enabled || kIsWeb) return;
    if (!Platform.isWindows) return;

    final now = ScheduleManager.getSystemTime();
    final dayIndex = now.weekday - 1; // 0 for Monday, 4 for Friday
    
    if (dayIndex < 0 || dayIndex > 4) {
      // Weekend, skip
      return;
    }

    final todayClasses = schedule[dayIndex] ?? [];
    if (todayClasses.isEmpty) return;

    final dateString = "${now.year}-${now.month}-${now.day}";

    for (int i = 0; i < todayClasses.length; i++) {
      final item = todayClasses[i];
      if (item.isBreak) continue;

      // Parse start time
      final parts = item.startTime.split(':');
      if (parts.length != 2) continue;
      final startHour = int.parse(parts[0]);
      final startMin = int.parse(parts[1]);

      // Class start DateTime on mock or real today
      final startDateTime = DateTime(now.year, now.month, now.day, startHour, startMin);
      
      // Lead warning DateTime today
      final warnDateTime = startDateTime.subtract(Duration(minutes: leadMinutes));

      // Trigger logic:
      // Trigger start reminder if time matches exactly (with a 2 minute buffer to handle periodic timer delay)
      final keyStart = "${dateString}_${item.startTime}_start";
      if (now.isAfter(startDateTime.subtract(const Duration(seconds: 5))) &&
          now.isBefore(startDateTime.add(const Duration(minutes: 2))) &&
          !_notifiedKeys.contains(keyStart)) {
        _notifiedKeys.add(keyStart);
        _showWindowsNotification(
          "ถึงเวลาเรียนวิชา ${item.subject} แล้ว!",
          "ห้องเรียน/ผู้สอน: ${item.teacher} (${item.startTime} - ${item.endTime} น.)",
        );
      }

      // Trigger lead warning reminder
      if (leadMinutes > 0) {
        final keyLead = "${dateString}_${item.startTime}_lead";
        if (now.isAfter(warnDateTime.subtract(const Duration(seconds: 5))) &&
            now.isBefore(warnDateTime.add(const Duration(minutes: 2))) &&
            !_notifiedKeys.contains(keyLead)) {
          _notifiedKeys.add(keyLead);
          _showWindowsNotification(
            "อีก $leadMinutes นาที จะถึงวิชา ${item.subject}",
            "เวลาเรียน: ${item.startTime} - ${item.endTime} น.",
          );
        }
      }
    }
  }

  /// Helper to trigger a native Windows toast notification.
  static void _showWindowsNotification(String title, String body) {
    try {
      final notification = LocalNotification(
        title: title,
        body: body,
      );
      notification.show();
      debugPrint("Windows Toast shown: $title - $body");
    } catch (e) {
      debugPrint("Failed to display Windows Toast: $e");
    }
  }
}
