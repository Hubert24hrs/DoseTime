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
    
    // Cancel all potential notifications for this ID (max 10 repeats)
    final notificationService = NotificationService();
    for (int i = 0; i < 10; i++) {
        // Base IDs are (medId * 1000) + (timeIndex * 10)
        // We cancel the first 10 potential time slots
        await notificationService.cancelNotification((id * 1000) + (i * 10));
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

    // Unified logic for all medication frequencies
    for (final med in medications) {
      if (med.frequency == 'Daily') {
        for (final timeStr in med.times) {
          final parts = timeStr.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);
          final time = TimeOfDay(hour: hour, minute: minute);

          final log = logs.lastWhere(
            (l) => l.medicationId == med.id && 
                   l.scheduledTime.hour == hour && 
                   l.scheduledTime.minute == minute,
            orElse: () => DoseLog(medicationId: -1, scheduledTime: DateTime(0), status: 'placeholder'),
          );
          
          items.add(DoseScheduleItem(
            medication: med, 
            scheduledTime: time, 
            log: (log.medicationId != -1 && log.status != 'placeholder') ? log : null
          ));
        }
      } else if (med.frequency == 'As Needed') {
        final medLogs = logs.where((l) => l.medicationId == med.id).toList();
        
        if (medLogs.isEmpty) {
          items.add(DoseScheduleItem(
            medication: med,
            scheduledTime: const TimeOfDay(hour: 0, minute: 0), // Use 0:00 for PRN
            log: null,
          ));
        } else {
          for (final log in medLogs) {
            items.add(DoseScheduleItem(
              medication: med,
              scheduledTime: TimeOfDay.fromDateTime(log.takenTime ?? log.scheduledTime),
              log: log,
            ));
          }
          // Add one prompt to take it again
          items.add(DoseScheduleItem(
            medication: med,
            scheduledTime: const TimeOfDay(hour: 0, minute: 0),
            log: null,
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

    if (status == 'delete') {
      if (item.log != null && item.log!.id != null) {
        await repository.deleteLog(item.log!.id!);
      }
      ref.invalidate(todaysScheduleProvider);
      return;
    }

    if (item.log == null) {
      // Create new log
      await repository.logDose(DoseLog(
        medicationId: item.medication.id!,
        medicationName: item.medication.name,
        medicationColor: item.medication.color,
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
      
      // If updating, we might want to also ensure name/color are there if they weren't before
      // (for legacy logs during migration)
      // But repo.updateLogStatus only takes status and time. 
      // Let's add a more generic updateLog to repo later if needed.
    }
    
    // Cancel repeating notifications for this dose
    final notificationService = NotificationService();
    // Reconstruct the base ID: (medId * 1000) + (timeIndex * 10)
    // We need to find the index of the time in the medication's list with proper padding
    final timeStr = '${item.scheduledTime.hour.toString().padLeft(2, '0')}:${item.scheduledTime.minute.toString().padLeft(2, '0')}';
    final timeIndex = item.medication.times.indexOf(timeStr);
    
    if (timeIndex != -1) {
        final baseId = (item.medication.id! * 1000) + (timeIndex * 10);
        await notificationService.cancelNotification(baseId);
    }
    
    ref.invalidate(todaysScheduleProvider);
    ref.invalidate(historyLogsProvider);

    // Inventory Management: Decrement stock if applicable and status is 'taken'
    if (status == 'taken' && item.medication.stockQuantity != null) {
      final currentStock = item.medication.stockQuantity!;
      if (currentStock > 0) {
        final updatedMed = item.medication.copyWith(
          stockQuantity: currentStock - 1,
        );
        await repository.updateMedication(updatedMed);
        ref.invalidate(medicationListProvider);
      }
    }
  };
});
