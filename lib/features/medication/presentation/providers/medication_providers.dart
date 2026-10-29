import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/domain/repositories/medication_repository.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Part of the day a dose falls in; drives the home screen wheel quadrants.
enum DosePeriod {
  morning('Morning', Icons.wb_twilight),
  afternoon('Afternoon', Icons.wb_sunny_outlined),
  evening('Evening', Icons.wb_cloudy_outlined),
  night('Night', Icons.nightlight_outlined);

  const DosePeriod(this.label, this.icon);
  final String label;
  final IconData icon;

  static DosePeriod of(TimeOfDay t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return DosePeriod.morning;
    if (h >= 12 && h < 17) return DosePeriod.afternoon;
    if (h >= 17 && h < 21) return DosePeriod.evening;
    return DosePeriod.night;
  }
}

// Helper model for UI
class DoseScheduleItem {
  final Medication medication;
  final TimeOfDay scheduledTime;
  final DateTime date;
  final DoseLog? log; // If null, status is 'pending'

  DoseScheduleItem({
    required this.medication,
    required this.scheduledTime,
    DateTime? date,
    this.log,
  }) : date = date ?? DateTime.now();

  String get status => log?.status ?? 'pending';
  bool get isTaken => status == 'taken';
  bool get isSkipped => status == 'skipped';
  bool get isDone => isTaken || isSkipped;
  bool get isAsNeeded => medication.frequency == 'As Needed';
  DosePeriod get period => DosePeriod.of(scheduledTime);

  String get timeKey =>
      '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

  DateTime get scheduledDateTime => DateTime(
      date.year, date.month, date.day, scheduledTime.hour, scheduledTime.minute);

  /// Pending dose whose time has passed by more than an hour.
  bool get isMissed =>
      !isDone && !isAsNeeded && DateTime.now().difference(scheduledDateTime).inMinutes > 60;
}

final medicationListProvider = FutureProvider.autoDispose<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getAllMedications();
});

final historyLogsProvider = FutureProvider.autoDispose<List<DoseLog>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getAllLogs();
});

final deleteMedicationProvider = Provider.autoDispose((ref) {
  return (int id) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.deleteMedication(id);
    await ReminderScheduler.cancelForMedication(id);

    ref.invalidate(medicationListProvider);
    ref.invalidate(todaysScheduleProvider);
    ref.invalidate(scheduleForDateProvider);
  };
});

/// Day shown on the home screen (defaults to today).
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

Future<List<DoseScheduleItem>> buildScheduleForDate(
  MedicationRepository repository,
  DateTime date,
) async {
  final medications = await repository.getAllMedications();
  final logs = await repository.getLogsForDate(date);
  final day = DateTime(date.year, date.month, date.day);
  final items = <DoseScheduleItem>[];

  for (final med in medications) {
    if (med.isArchived) continue;
    if (med.startDate != null && day.isBefore(DateTime(med.startDate!.year, med.startDate!.month, med.startDate!.day))) {
      continue;
    }
    if (med.endDate != null && day.isAfter(med.endDate!)) continue;

    if (med.frequency == 'Daily') {
      for (final timeStr in med.times) {
        final time = ReminderScheduler.parseTime(timeStr);
        DoseLog? log;
        for (final l in logs) {
          if (l.medicationId == med.id &&
              l.scheduledTime.hour == time.hour &&
              l.scheduledTime.minute == time.minute) {
            log = l;
          }
        }
        items.add(DoseScheduleItem(medication: med, scheduledTime: time, date: day, log: log));
      }
    } else if (med.frequency == 'As Needed') {
      for (final log in logs.where((l) => l.medicationId == med.id)) {
        items.add(DoseScheduleItem(
          medication: med,
          scheduledTime: TimeOfDay.fromDateTime(log.takenTime ?? log.scheduledTime),
          date: day,
          log: log,
        ));
      }
    }
  }

  items.sort((a, b) {
    final aMin = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
    final bMin = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
    return aMin.compareTo(bMin);
  });
  return items;
}

final scheduleForDateProvider =
    FutureProvider.autoDispose.family<List<DoseScheduleItem>, DateTime>((ref, date) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return buildScheduleForDate(repository, date);
});

final todaysScheduleProvider = FutureProvider.autoDispose<List<DoseScheduleItem>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return buildScheduleForDate(repository, DateTime.now());
});

/// As-needed medications (shown as "Take now" shortcuts on the home screen).
final asNeededMedicationsProvider = FutureProvider.autoDispose<List<Medication>>((ref) async {
  final meds = await ref.watch(medicationListProvider.future);
  return meds.where((m) => m.frequency == 'As Needed' && !m.isArchived).toList();
});

final logDoseProvider = Provider.autoDispose((ref) {
  return (DoseScheduleItem item, String status) async {
    final repository = ref.read(medicationRepositoryProvider);
    final now = DateTime.now();
    final scheduleDate = item.scheduledDateTime;

    void refresh() {
      ref.invalidate(todaysScheduleProvider);
      ref.invalidate(scheduleForDateProvider);
      ref.invalidate(historyLogsProvider);
    }

    if (status == 'delete') {
      if (item.log != null && item.log!.id != null) {
        await repository.deleteLog(item.log!.id!);
      }
      refresh();
      return;
    }

    if (item.log == null) {
      await repository.logDose(DoseLog(
        medicationId: item.medication.id!,
        medicationName: item.medication.name,
        medicationColor: item.medication.color,
        scheduledTime: scheduleDate,
        takenTime: status == 'taken' ? now : null,
        status: status,
      ));
    } else {
      await repository.updateLogStatus(
        item.log!.id!,
        status,
        status == 'taken' ? now : null,
      );
    }

    // Silence the rest of today's alarms for this dose; tomorrow's stay.
    final isToday = DateUtils.isSameDay(item.date, now);
    if (isToday && !item.isAsNeeded) {
      await ReminderScheduler.markHandled(item.medication, item.timeKey);
    }

    refresh();

    // Inventory Management: Decrement stock if applicable and status is 'taken'
    if (status == 'taken' && item.medication.stockQuantity != null) {
      final currentStock = item.medication.stockQuantity!;
      if (currentStock > 0) {
        await repository.updateMedication(
          item.medication.copyWith(stockQuantity: currentStock - 1),
        );
        ref.invalidate(medicationListProvider);
      }
    }
  };
});

/// Log an as-needed dose taken right now.
final logAsNeededProvider = Provider.autoDispose((ref) {
  return (Medication med) async {
    final now = DateTime.now();
    await ref.read(logDoseProvider)(
      DoseScheduleItem(
        medication: med,
        scheduledTime: TimeOfDay.fromDateTime(now),
        date: now,
      ),
      'taken',
    );
  };
});
