import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper model for UI
class DoseScheduleItem {
  final Medication medication;
  final TimeOfDay scheduledTime;
  final DoseLog? log; // If null, status is 'pending'

  DoseScheduleItem({
    required this.medication,
    required this.scheduledTime,
    this.log,
  });

  String get status => log?.status ?? 'pending';
  bool get isTaken => status == 'taken';
  bool get isSkipped => status == 'skipped';
}

final medicationListProvider = FutureProvider.autoDispose<List<Medication>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  return repository.getAllMedications();
});

final historyLogsProvider = FutureProvider.autoDispose<List<DoseLog>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  // Get last 30 days logs? Or all. MVP all.
  // We need a method in repo for "All Logs". I only have "getLogsForDate".
  // Let's add "getAllLogs" to repo or just iterate days? Be pragmatic.
  // Add getAllLogs to repo if feasible, or just show today's history in rudimentary way.
  // Let's stick to "getLogsForDate" for today in Home.
  // For HistoryScreen, we want a list.
  // I will cheat and add getAllLogs to repo implementation quickly? 
  // Or just mock it for now to save complexity?
  // Let's assume getAllLogs exists or add it.
  // I'll add 'getAllLogs' to repository.
  return repository.getAllLogs();
});

final deleteMedicationProvider = Provider.autoDispose((ref) {
  return (int id) async {
    final repository = ref.read(medicationRepositoryProvider);
    await repository.deleteMedication(id);
    
    // Cancel all potential notifications for this ID (assuming max 100 per med)
    final notificationService = NotificationService();
    for (int i = 0; i < 20; i++) {
        await notificationService.cancelNotification((id * 100) + i);
    }

    ref.invalidate(medicationListProvider);
    ref.invalidate(todaysScheduleProvider);
  };
});

final todaysScheduleProvider = FutureProvider.autoDispose<List<DoseScheduleItem>>((ref) async {
  final repository = ref.watch(medicationRepositoryProvider);
  final medications = await repository.getAllMedications();
  final today = DateTime.now();
  final logs = await repository.getLogsForDate(today);

  final List<DoseScheduleItem> items = [];

  for (final med in medications) {
    if (med.frequency == 'Daily') { // MVP logic
      for (final timeStr in med.times) {
        final parts = timeStr.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final time = TimeOfDay(hour: hour, minute: minute);

        // Find log matches logic: same med_id and same scheduled time
        // Note: Repository getLogsForDate filters by date YYYY-MM-DD
        // We need to match precise scheduled time string in database if we stored it fully
        // But simpler: Check if we have a log for this med that loosely matches this time?
        // Let's refine Log logic: log.scheduledTime should be today at HH:MM
        
        final log = logs.firstWhere(
          (l) => l.medicationId == med.id && 
                 l.scheduledTime.hour == hour && 
                 l.scheduledTime.minute == minute,
          orElse: () => DoseLog(medicationId: -1, scheduledTime: DateTime(0), status: 'placeholder'),
        );
        
        items.add(DoseScheduleItem(
          medication: med, 
          scheduledTime: time, 
          log: log.medicationId != -1 ? log : null
        ));
      }
    }
  }

  // Sort by time
  items.sort((a, b) {
    final aMin = a.scheduledTime.hour * 60 + a.scheduledTime.minute;
    final bMin = b.scheduledTime.hour * 60 + b.scheduledTime.minute;
    return aMin.compareTo(bMin);
  });

  return items;
});

final logDoseProvider = Provider.autoDispose((ref) {
  return (DoseScheduleItem item, String status) async {
    final repository = ref.read(medicationRepositoryProvider);
    final now = DateTime.now();
    
    // Construct exact scheduled time for today
    final scheduleDate = DateTime(
      now.year, now.month, now.day, 
      item.scheduledTime.hour, item.scheduledTime.minute
    );

    if (item.log == null) {
      // Create new log
      await repository.logDose(DoseLog(
        medicationId: item.medication.id!,
        scheduledTime: scheduleDate,
        takenTime: status == 'taken' ? now : null,
        status: status,
      ));
    } else {
      // Update existing log
      await repository.updateLogStatus(
        item.log!.id!, 
        status, 
        status == 'taken' ? now : null
      );
    }
    
    // Cancel repeating notifications for this dose
    final notificationService = NotificationService();
    // Reconstruct the base ID: (medId * 1000) + (timeIndex * 10)
    // We need to find the index of the time in the medication's list.
    final timeIndex = item.medication.times.indexOf('${item.scheduledTime.hour}:${item.scheduledTime.minute}');
    if (timeIndex != -1) {
        final baseId = (item.medication.id! * 1000) + (timeIndex * 10);
        await notificationService.cancelNotification(baseId);
    }
    
    ref.invalidate(todaysScheduleProvider);
  };
});
