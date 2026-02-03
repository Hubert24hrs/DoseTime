import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permission handling service
class PermissionService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  PermissionService(this._notificationsPlugin);

  /// Check if notification permissions are granted
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    }
    return true;
  }

  /// Request notification permissions
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true;
  }

  /// Check if exact alarms are available (Android 12+)
  Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  /// Request exact alarm permission (Android 12+)
  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return true;
    
    if (Platform.isAndroid) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestExactAlarmsPermission();
      return await canScheduleExactAlarms();
    }
    return true;
  }

  /// Request all required permissions for the app
  Future<PermissionStatus> requestAllPermissions(BuildContext context) async {
    final notificationGranted = await requestNotificationPermission();
    final exactAlarmGranted = await requestExactAlarmPermission();

    if (notificationGranted && exactAlarmGranted) {
      return PermissionStatus.allGranted;
    } else if (!notificationGranted && !exactAlarmGranted) {
      return PermissionStatus.allDenied;
    } else {
      return PermissionStatus.partial;
    }
  }

  /// Show permission rationale dialog
  Future<bool> showPermissionRationale(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permissions Required'),
            content: const Text(
              'DoseAlert needs notification permissions to remind you about your medications. '
              'Exact alarm permission ensures reminders are delivered on time, even in battery-saving mode.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

enum PermissionStatus {
  allGranted,
  partial,
  allDenied,
}

// Provider
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService(FlutterLocalNotificationsPlugin());
});
