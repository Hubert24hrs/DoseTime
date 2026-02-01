import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Enhanced notification service with proper permission handling
/// and exact alarm support for Android 12+
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Check if the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(await _getLocalTimezone()));

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      // High priority channel for medication reminders
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Important reminders to take your medication',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Regular channel for general notifications
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'general',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
        ),
      );
    }
  }

  /// Get local timezone
  Future<String> _getLocalTimezone() async {
    try {
      // Default to UTC if we can't detect
      return 'UTC';
    } catch (e) {
      return 'UTC';
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Navigate to medication details if needed
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      // Request notification permission (Android 13+)
      final notificationGranted = 
          await androidPlugin?.requestNotificationsPermission() ?? false;
      
      // Request exact alarm permission (Android 12+)
      await androidPlugin?.requestExactAlarmsPermission();
      
      return notificationGranted;
    } else if (Platform.isIOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Check if exact alarms can be scheduled
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? true;
    }
    return true;
  }

  /// Schedule a daily recurring notification
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
  }) async {
    // Determine schedule mode based on permissions
    final canUseExactAlarms = await canScheduleExactAlarms();
    final scheduleMode = canUseExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Reminders to take your medication',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          category: AndroidNotificationCategory.reminder,
          visibility: NotificationVisibility.public,
          autoCancel: true,
          actions: [
            const AndroidNotificationAction(
              'take',
              'Take',
              showsUserInterface: true,
            ),
            const AndroidNotificationAction(
              'skip',
              'Skip',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'medication_reminder',
        ),
      ),
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );

    debugPrint('Scheduled notification $id for ${time.format}');
  }

  /// Calculate next instance of given time
  tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedule a one-time notification
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    final canUseExactAlarms = await canScheduleExactAlarms();
    final scheduleMode = canUseExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Get list of pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Show an instant notification (for testing)
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'general',
          'General Notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
