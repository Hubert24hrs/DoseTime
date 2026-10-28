import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Channel used for dose alarms. Android channels are immutable once created,
/// so the id is versioned whenever the sound/importance changes.
const String doseAlarmChannelId = 'dose_alarm_v2';
const String doseAlarmChannelName = 'Dose Alarms';

/// Payload helpers: reminders carry "dose|<medId>|<HH:mm>" so a tap can open
/// the alarm screen for the right time slot.
String doseAlarmPayload(int medicationId, String time) => 'dose|$medicationId|$time';

/// Returns the HH:mm dose time encoded in a reminder payload ('test' for the
/// test alarm), or null if the payload is not a dose alarm.
String? doseTimeFromPayload(String? payload) {
  if (payload == null) return null;
  final parts = payload.split('|');
  if (parts.length == 3 && parts[0] == 'dose') return parts[2];
  if (payload == 'test') return 'test';
  return null;
}

/// Enhanced notification service with proper permission handling
/// and exact alarm support for Android 12+
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _launchConsumed = false;

  /// Notification taps and action button presses while the app is running.
  static final StreamController<NotificationResponse> _responses =
      StreamController<NotificationResponse>.broadcast();
  Stream<NotificationResponse> get responses => _responses.stream;

  /// The notification that cold-started the app, if any (consumed once).
  Future<NotificationResponse?> takeLaunchResponse() async {
    if (kIsWeb || _launchConsumed) return null;
    final details = await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    _launchConsumed = true;
    return details.notificationResponse;
  }
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

    // Initialization settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    // Initialization settings for iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      notificationCategories: [
        DarwinNotificationCategory(
          'medication_reminder',
          actions: [
            DarwinNotificationAction.plain('take', 'Take', options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain('snooze', 'Snooze', options: {DarwinNotificationActionOption.foreground}),
            DarwinNotificationAction.plain('skip', 'Skip', options: {DarwinNotificationActionOption.foreground}),
          ],
          options: {DarwinNotificationCategoryOption.allowAnnouncement},
        ),
      ],
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
        final androidPlugin = flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.requestExactAlarmsPermission();
    }

    // Force channel recreation to reset and ensure sound/vibration
    await _createNotificationChannels(forceReset: true);
    
    // Request battery optimization exemption for reliable background notifications
    await requestBatteryOptimizationExemption();

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  /// Request battery optimization exemption for reliable background notifications
  Future<bool> requestBatteryOptimizationExemption() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) {
        debugPrint('NotificationService: Battery optimization already exempt');
        return true;
      }
      
      final result = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('NotificationService: Battery optimization request result: $result');
      return result.isGranted;
    } catch (e) {
      debugPrint('NotificationService: Failed to request battery optimization exemption: $e');
      return false;
    }
  }
  
  /// Check if battery optimization is disabled (app is exempt)
  Future<bool> isBatteryOptimizationExempt() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels({bool forceReset = false}) async {
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (forceReset) {
        // Older builds used a channel without the custom beep; remove it so
        // users only see the current alarm channel.
        await androidPlugin?.deleteNotificationChannel('medication_reminders');
        await androidPlugin?.deleteNotificationChannel('general');
      }

      // Alarm channel: plays the looping dose beep on the alarm stream so it
      // is audible even when media volume is muted.
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          doseAlarmChannelId,
          doseAlarmChannelName,
          description: 'Beeping alarms when it is time to take a dose',
          importance: Importance.max,
          playSound: true,
          sound: const RawResourceAndroidNotificationSound('dose_beep'),
          enableVibration: true,
          showBadge: true,
          enableLights: true,
          vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
          audioAttributesUsage: AudioAttributesUsage.alarm,
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
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification clicked: ${response.actionId}, payload: ${response.payload}');
    _responses.add(response);
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

  /// Notification details for a beeping dose alarm. FLAG_INSISTENT (4) keeps
  /// the beep looping until the user taps or dismisses the alarm.
  NotificationDetails _alarmDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        doseAlarmChannelId,
        doseAlarmChannelName,
        channelDescription: 'Beeping alarms when it is time to take a dose',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('dose_beep'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 800, 400, 800, 400, 800]),
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        autoCancel: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        additionalFlags: Int32List.fromList(<int>[4]),
        styleInformation: BigTextStyleInformation(body),
        actions: const [
          AndroidNotificationAction('skip', 'Skip', showsUserInterface: true, cancelNotification: true),
          AndroidNotificationAction('snooze', 'Snooze', showsUserInterface: true, cancelNotification: true),
          AndroidNotificationAction('take', 'Take', showsUserInterface: true, cancelNotification: true),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'medication_reminder',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final canUseExactAlarms = await canScheduleExactAlarms();
    return canUseExactAlarms
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Schedule a daily recurring dose alarm plus follow-up reminders every
  /// 10 minutes for an hour. When [startTomorrow] is true (the dose was
  /// already taken/skipped today) the first alarm fires tomorrow.
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
    String? payload,
    bool startTomorrow = false,
  }) async {
    final scheduleMode = await _scheduleMode();
    final details = _alarmDetails(body);

    final now = tz.TZDateTime.now(tz.local);
    var base = _nextInstanceOfTime(time);
    if (startTomorrow && base.day == now.day && base.month == now.month) {
      base = base.add(const Duration(days: 1));
    }

    // Schedule the primary alarm and 6 repeats (every 10 minutes for an hour)
    for (int i = 0; i <= 6; i++) {
      final scheduledTime = base.add(Duration(minutes: i * 10));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id + i, // Unique ID for each repeat
        i == 0 ? title : '$title (Reminder)',
        body,
        scheduledTime,
        details,
        androidScheduleMode: scheduleMode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    }

    debugPrint('Scheduled dose alarm $id (+6 repeats) from $base');
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

  /// Schedule a one-time beeping dose alarm
  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDateTime, tz.local),
      _alarmDetails(body),
      androidScheduleMode: await _scheduleMode(),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Schedule a snooze alarm [minutes] from now for the given dose slot.
  Future<void> scheduleSnoozeNotification({
    required int id,
    required String title,
    required String body,
    int minutes = 10,
    String? payload,
  }) async {
    await scheduleOneTimeNotification(
      id: 900000 + (id % 90000), // Separate range so it never collides with daily alarms
      title: '$title (Snoozed)',
      body: body,
      scheduledDateTime: DateTime.now().add(Duration(minutes: minutes)),
      payload: payload ?? 'snooze',
    );
  }

  /// Fire a test alarm after [delay] so the user can lock the phone and hear it.
  Future<void> scheduleTestAlarm({Duration delay = const Duration(seconds: 10)}) async {
    await scheduleOneTimeNotification(
      id: 999,
      title: 'DoseAlert test alarm',
      body: 'This is how your dose reminders will beep.',
      scheduledDateTime: DateTime.now().add(delay),
      payload: 'test',
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
}
