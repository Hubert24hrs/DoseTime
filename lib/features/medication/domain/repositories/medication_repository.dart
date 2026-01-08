import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';

abstract class MedicationRepository {
  // Medications
  Future<Medication> createMedication(Medication medication);
  Future<Medication?> getMedication(int id);
  Future<List<Medication>> getAllMedications();
  Future<int> updateMedication(Medication medication);
  Future<int> deleteMedication(int id);

  // Logs
  Future<DoseLog> logDose(DoseLog log);
  Future<List<DoseLog>> getLogsForDate(DateTime date);
  Future<List<DoseLog>> getAllLogs();
  Future<int> updateLogStatus(int logId, String status, DateTime? takenTime);
}
