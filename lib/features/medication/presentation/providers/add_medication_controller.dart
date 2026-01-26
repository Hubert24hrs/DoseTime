import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddMedicationState {
  final bool isLoading;
  final String? error;

  AddMedicationState({this.isLoading = false, this.error});
}

class AddMedicationController extends Notifier<AddMedicationState> {
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
  }) async {
    state = AddMedicationState(isLoading: true);
    try {
      final repository = ref.read(medicationRepositoryProvider);
      final settings = ref.read(settingsServiceProvider);
      
      // Limit Check
      if (!settings.isPro) {
        final currentMeds = await repository.getAllMedications();
        if (currentMeds.length >= 2) {
          state = AddMedicationState(isLoading: false, error: 'Limit Reached (2). Upgrade to Pro!');
          return false;
        }
      }
      
      final timesList = times.map((t) => '${t.hour}:${t.minute}').toList();

      final medication = Medication(
        name: name,
        dosage: dosage,
        frequency: frequency,
        times: timesList,
        color: color,
        icon: icon?.codePoint,
      );

      final savedMed = await repository.createMedication(medication);

      // Schedule Notifications
      final notificationService = NotificationService();
      if (savedMed.frequency == 'Daily') {
        for (int i = 0; i < times.length; i++) {
          final time = times[i];
          // Unique ID: medId * 100 + index
          final notificationId = (savedMed.id! * 100) + i;
          await notificationService.scheduleDailyNotification(
            id: notificationId,
            title: 'Time for ${savedMed.name}',
            body: 'Take ${savedMed.dosage}',
            time: time,
          );
        }
      }

      ref.invalidate(medicationListProvider);
      state = AddMedicationState(isLoading: false);
      return true;
    } catch (e) {
      state = AddMedicationState(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final addMedicationControllerProvider =
    NotifierProvider.autoDispose<AddMedicationController, AddMedicationState>(
        AddMedicationController.new);
