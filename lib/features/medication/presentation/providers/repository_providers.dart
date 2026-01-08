import 'package:dose_time/core/database/database_helper.dart';
import 'package:dose_time/features/medication/data/repositories/medication_repository_impl.dart';
import 'package:dose_time/features/medication/domain/repositories/medication_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(DatabaseHelper.instance);
});
