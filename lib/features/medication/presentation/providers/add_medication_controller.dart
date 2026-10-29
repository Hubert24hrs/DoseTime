import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart' show MedicationType;
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:dose_time/core/services/purchase_service.dart';
import 'package:dose_time/core/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddMedicationState {
  final bool isLoading;
  final String? error;

  AddMedicationState({this.isLoading = false, this.error});
}

class AddMedicationController extends AutoDisposeNotifier<AddMedicationState> {
  @override
  AddMedicationState build() {
    return AddMedicationState();
  }

  Future<bool> saveMedication({
    required String name,
    required String dosage,
    required String frequency,
    required List<TimeOfDay> times,
    required int color,
    IconData? icon,
    double? stockQuantity,
    double? refillThreshold,
    MedicationType type = MedicationType.pill,
    String? instructions,
  }) async {
    state = AddMedicationState(isLoading: true);
    try {
      final repository = ref.read(medicationRepositoryProvider);
      // Free plan limit; Pro status comes from a verified store purchase.
      final isPro = await PurchaseService().isProUser();
      if (!isPro) {
        final currentMeds = await repository.getAllMedications();
        if (currentMeds.length >= AppConstants.freeMedicationLimit) {
          state = AddMedicationState(
            isLoading: false,
            error: 'The free plan includes up to ${AppConstants.freeMedicationLimit} medications. '
                'Upgrade to Pro for unlimited.',
          );
          return false;
        }
      }
      
      final timesList = times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').toList();

      final medication = Medication(
        name: name,
        dosage: dosage,
        frequency: frequency,
        times: timesList,
        color: color,
        icon: icon?.codePoint,
        stockQuantity: stockQuantity,
        refillThreshold: refillThreshold,
        type: type,
        instructions: instructions,
        startDate: DateTime.now(),
      );

      final savedMed = await repository.createMedication(medication);

      // Schedule beeping dose alarms
      await ReminderScheduler.scheduleMedication(savedMed);

      ref.invalidate(medicationListProvider);
      ref.invalidate(todaysScheduleProvider);
      ref.invalidate(scheduleForDateProvider);

      // Ensure permissions are granted before returning
      await NotificationService().requestPermissions();
      
      state = AddMedicationState(isLoading: false);
      return true;
    } catch (e) {
      state = AddMedicationState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final addMedicationControllerProvider =
    AutoDisposeNotifierProvider<AddMedicationController, AddMedicationState>(
        AddMedicationController.new);
