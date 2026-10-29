import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/domain/repositories/medication_repository.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:flutter/material.dart';

/// Keeps the scheduled dose alarms in sync with the medication list.
///
/// Each dose time gets a block of ids: (medId * 1000) + (timeIndex * 10) + repeat,
/// where repeat 0 is the alarm itself and 1-6 are the 10-minute follow-ups.
class ReminderScheduler {
  ReminderScheduler._();

  static const int _maxSlots = 20;

  static int baseId(int medicationId, int timeIndex) =>
      (medicationId * 1000) + (timeIndex * 10);

  static String normalizeTime(String time) {
    final parts = time.split(':');
    final h = int.tryParse(parts.first) ?? 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static TimeOfDay parseTime(String time) {
    final parts = normalizeTime(time).split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static Future<void> cancelForMedication(int medicationId) async {
    final ns = NotificationService();
    for (int i = 0; i < _maxSlots; i++) {
      await ns.cancelNotification(baseId(medicationId, i));
    }
  }

  /// Schedules every dose time of [med]. Times listed in [handledToday]
  /// (HH:mm) were already taken/skipped, so their alarms start tomorrow.
  static Future<void> scheduleMedication(
    Medication med, {
    Set<String> handledToday = const {},
  }) async {
    if (med.id == null || med.isArchived || med.frequency != 'Daily') return;
    final ns = NotificationService();
    for (int i = 0; i < med.times.length; i++) {
      final time = normalizeTime(med.times[i]);
      await ns.scheduleDailyNotification(
        id: baseId(med.id!, i),
        title: 'Time for ${med.name}',
        body: 'Take ${med.dosage}',
        time: parseTime(time),
        payload: doseAlarmPayload(med.id!, time),
        startTomorrow: handledToday.contains(time),
      );
    }
  }

  /// Re-creates alarms for one medication (after add/edit).
  static Future<void> rescheduleMedication(
    Medication med,
    MedicationRepository repository,
  ) async {
    if (med.id == null) return;
    await cancelForMedication(med.id!);
    final handled = await _handledToday(repository);
    await scheduleMedication(med, handledToday: handled[med.id] ?? const {});
  }

  /// Silences the rest of today's alarms for one dose and keeps tomorrow's.
  static Future<void> markHandled(Medication med, String time) async {
    if (med.id == null) return;
    final normalized = normalizeTime(time);
    final index = med.times.indexWhere((t) => normalizeTime(t) == normalized);
    if (index == -1) return;
    final ns = NotificationService();
    final id = baseId(med.id!, index);
    await ns.cancelNotification(id);
    if (med.frequency == 'Daily' && !med.isArchived) {
      await ns.scheduleDailyNotification(
        id: id,
        title: 'Time for ${med.name}',
        body: 'Take ${med.dosage}',
        time: parseTime(normalized),
        payload: doseAlarmPayload(med.id!, normalized),
        startTomorrow: true,
      );
    }
  }

  /// Rebuilds all dose alarms. Run on app start so alarms survive upgrades
  /// (e.g. moving to the beeping alarm channel) and stay consistent.
  static Future<void> syncAll(MedicationRepository repository) async {
    final ns = NotificationService();
    final pending = await ns.getPendingNotifications();
    for (final p in pending) {
      // Leave snoozes (900000+) and the test alarm (999) alone.
      if (p.id < 900000 && p.id != 999) {
        await ns.flutterLocalNotificationsPlugin.cancel(p.id);
      }
    }
    final meds = await repository.getAllMedications();
    final handled = await _handledToday(repository);
    for (final med in meds) {
      await scheduleMedication(med, handledToday: handled[med.id] ?? const {});
    }
  }

  static Future<Map<int, Set<String>>> _handledToday(MedicationRepository repository) async {
    final logs = await repository.getLogsForDate(DateTime.now());
    final result = <int, Set<String>>{};
    for (final log in logs) {
      if (log.status != 'taken' && log.status != 'skipped') continue;
      final t = log.scheduledTime;
      result.putIfAbsent(log.medicationId, () => <String>{}).add(
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
          );
    }
    return result;
  }
}
