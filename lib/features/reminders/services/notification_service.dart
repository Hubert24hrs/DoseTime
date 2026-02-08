import 'dart:io' show Platform;
import 'package:flutter_timezone/flutter_timezone.dart';

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
  String _detectedTimezone = 'Unknown';
  bool _isUtcFallback = false;

  /// Check if the service has been initialized
  bool get isInitialized => _isInitialized;

  /// Get the detected timezone name
  String get detectedTimezone => _detectedTimezone;

  /// Check if the service fell back to UTC
  bool get isUtcFallback => _isUtcFallback;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    try {
      _detectedTimezone = await _getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(_detectedTimezone));
      _isUtcFallback = false;
    } catch (e) {
      debugPrint('NotificationService: Could not set local timezone, falling back to UTC: $e');
      _detectedTimezone = 'UTC';
      _isUtcFallback = true;
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

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
        AndroidNotificationChannel(
          'medication_reminders',
          'Medication Reminders',
          description: 'Important reminders to take your medication',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
          enableLights: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        ),
      );

      // Regular channel for general notifications
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          'general',
          'General Notifications',
          description: 'General app notifications',
          importance: Importance.defaultImportance,
          playSound: true,
        ),
      );
    }
  }

  /// Get local timezone
  Future<String> _getLocalTimezone() async {
    try {
      // In flutter_timezone 5.x, this returns a String directly or a TimezoneInfo
      final dynamic timezone = await FlutterTimezone.getLocalTimezone();
      if (timezone is String) return timezone;
      // If it's a TimezoneInfo object, we might need a specific property
      // but let's try to convert safely.
      return timezone.toString();
    } catch (e) {
      debugPrint('Failed to get local timezone, falling back to UTC: $e');
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

    // Schedule the primary notification and 6 repeats (every 10 minutes for an hour)
    for (int i = 0; i <= 6; i++) {
        final scheduledTime = _nextInstanceOfTime(time).add(Duration(minutes: i * 10));
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id + i, // Unique ID for each repeat
          i == 0 ? title : '$title (Reminder)',
          body,
          scheduledTime,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'medication_reminders',
              'Medication Reminders',
              channelDescription: 'Important reminders to take your medication',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
              vibrationPattern: Int64List.fromList([0, 500, 200, 500]), // Custom vibration
              category: AndroidNotificationCategory.alarm,
              visibility: NotificationVisibility.public,
              fullScreenIntent: true,
              autoCancel: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              styleInformation: BigTextStyleInformation(body),
              actions: [
                const AndroidNotificationAction(
                  'take',
                  'Take',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
                const AndroidNotificationAction(
                  'skip',
                  'Skip',
                  showsUserInterface: true,
                  cancelNotification: true,
                ),
              ],
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              categoryIdentifier: 'medication_reminder',
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: scheduleMode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
    }

    debugPrint('Scheduled notification $id and 5 repeats for ${time.format}');
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
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a snooze notification (10 minutes)
  Future<void> scheduleSnoozeNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 10));
    await scheduleOneTimeNotification(
      id: id + 9999, // Use a high offset to avoid collision
      title: '$title (Snoozed)',
      body: 'Time to take your $body',
      scheduledDateTime: scheduledTime,
      payload: 'snooze',
    );
  }

  /// Cancel a specific notification and its repeats
  Future<void> cancelNotification(int id) async {
    // Cancel the primary and the 6 repeats (total 7)
    for (int i = 0; i <= 6; i++) {
        await flutterLocalNotificationsPlugin.cancel(id + i);
    }
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
          channelDescription: 'General app notifications',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }
}
