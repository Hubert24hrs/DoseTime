import 'dart:async';

import 'package:dose_time/core/router/app_router.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Messenger used for confirmations from outside any Scaffold (e.g. a Take
/// pressed on the notification itself).
final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Opens the beeping alarm screen when a dose is due:
/// * a reminder notification (or its full-screen intent) is tapped,
/// * the app was launched from a reminder,
/// * or the app is open in the foreground when the dose time arrives.
/// Take / Skip / Snooze buttons on the notification are applied directly.
class AlarmCoordinator extends ConsumerStatefulWidget {
  final Widget child;

  const AlarmCoordinator({super.key, required this.child});

  @override
  ConsumerState<AlarmCoordinator> createState() => _AlarmCoordinatorState();
}

class _AlarmCoordinatorState extends ConsumerState<AlarmCoordinator> with WidgetsBindingObserver {
  StreamSubscription<NotificationResponse>? _sub;
  Timer? _ticker;
  final Set<String> _alarmedSlots = {};
  String? _openAlarm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final ns = NotificationService();
    _sub = ns.responses.listen(_handleResponse);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final launch = await ns.takeLaunchResponse();
      if (launch != null) {
        _handleResponse(launch);
      } else {
        _checkDue();
      }
    });
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) => _checkDue());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todaysScheduleProvider);
      ref.invalidate(scheduleForDateProvider);
      _checkDue();
    }
  }

  bool get _isForeground =>
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

  String _slotKey(DateTime d, String time) => '${d.year}-${d.month}-${d.day} $time';

  Future<void> _handleResponse(NotificationResponse response) async {
    final time = doseTimeFromPayload(response.payload);
    if (time == null) return;
    final action = response.actionId;

    if (time != 'test' && (action == 'take' || action == 'skip' || action == 'snooze')) {
      await _applyFromNotification(time, action!);
      return;
    }
    _openAlarmScreen(time);
  }

  void _openAlarmScreen(String time) {
    final settings = ref.read(settingsServiceProvider);
    if (!settings.onboardingComplete || !settings.disclaimerAccepted) return;
    if (_openAlarm == time) return;
    _openAlarm = time;
    _alarmedSlots.add(_slotKey(DateTime.now(), time));
    final router = ref.read(routerProvider);
    router.push('/alarm?time=$time').whenComplete(() => _openAlarm = null);
  }

  Future<void> _applyFromNotification(String time, String action) async {
    final repository = ref.read(medicationRepositoryProvider);
    final items = await buildScheduleForDate(repository, DateTime.now());
    final due = items.where((i) => !i.isAsNeeded && !i.isDone && i.timeKey == time).toList();
    if (due.isEmpty) return;
    _alarmedSlots.add(_slotKey(DateTime.now(), time));

    if (action == 'snooze') {
      final minutes = ref.read(settingsServiceProvider).defaultSnoozeDuration;
      for (final item in due) {
        await ReminderScheduler.markHandled(item.medication, item.timeKey);
        await NotificationService().scheduleSnoozeNotification(
          id: item.medication.id! * 1440 + item.scheduledTime.hour * 60 + item.scheduledTime.minute,
          title: 'Time for ${item.medication.name}',
          body: 'Take ${item.medication.dosage}',
          minutes: minutes,
          payload: doseAlarmPayload(item.medication.id!, item.timeKey),
        );
      }
      _toast('Snoozed for $minutes minutes');
      return;
    }

    final status = action == 'take' ? 'taken' : 'skipped';
    for (final item in due) {
      await ref.read(logDoseProvider)(item, status);
    }
    _toast(status == 'taken' ? 'Marked ${due.length} dose(s) as taken' : 'Skipped ${due.length} dose(s)');
  }

  void _toast(String message) {
    rootMessengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  /// While the app is open, ring the in-app alarm at the dose time.
  Future<void> _checkDue() async {
    if (!mounted || !_isForeground || _openAlarm != null) return;
    final now = DateTime.now();
    final repository = ref.read(medicationRepositoryProvider);
    final items = await buildScheduleForDate(repository, now);
    for (final item in items) {
      if (item.isAsNeeded || item.isDone) continue;
      final diff = now.difference(item.scheduledDateTime);
      if (diff.isNegative || diff.inSeconds > 90) continue;
      final key = _slotKey(now, item.timeKey);
      if (_alarmedSlots.contains(key)) continue;
      _openAlarmScreen(item.timeKey);
      return;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
