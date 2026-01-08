import 'package:dose_time/core/database/database_helper.dart';
import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/domain/repositories/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final DatabaseHelper _dbHelper;

  MedicationRepositoryImpl(this._dbHelper);

  // --- Medications ---

  @override
  Future<Medication> createMedication(Medication medication) async {
    final db = await _dbHelper.database;
    final id = await db.insert('medications', medication.toMap());
    return medication.copyWith(id: id);
  }

  @override
  Future<Medication?> getMedication(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Medication.fromMap(maps.first);
    } else {
      return null;
    }
  }

  @override
  Future<List<Medication>> getAllMedications() async {
    final db = await _dbHelper.database;
    final maps = await db.query('medications', orderBy: 'id DESC');
    return maps.map((e) => Medication.fromMap(e)).toList();
  }

  @override
  Future<int> updateMedication(Medication medication) async {
    final db = await _dbHelper.database;
    return await db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  @override
  Future<int> deleteMedication(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'medications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Logs ---

  @override
  Future<DoseLog> logDose(DoseLog log) async {
    final db = await _dbHelper.database;
    final id = await db.insert('dose_logs', log.toMap());
    return log.copyWith(id: id);
  }

  @override
  Future<List<DoseLog>> getLogsForDate(DateTime date) async {
    final db = await _dbHelper.database;
    // Query logs where scheduled_time string starts with "YYYY-MM-DD"
    // Ideally use proper ISO format for DB logic, but simplistic string matching works for MVP
    final dateStr = date.toIso8601String().split('T')[0];
    
    final maps = await db.query(
      'dose_logs',
      where: 'scheduled_time LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'scheduled_time ASC',
    );
    return maps.map((e) => DoseLog.fromMap(e)).toList();
  }

  @override
  Future<List<DoseLog>> getAllLogs() async {
    final db = await _dbHelper.database;
    final maps = await db.query('dose_logs', orderBy: 'scheduled_time DESC');
    return maps.map((e) => DoseLog.fromMap(e)).toList();
  }

  @override
  Future<int> updateLogStatus(int logId, String status, DateTime? takenTime) async {
    final db = await _dbHelper.database;
    return await db.update(
      'dose_logs',
      {
        'status': status,
        'taken_time': takenTime?.toIso8601String(), // can be null
      },
      where: 'id = ?',
      whereArgs: [logId],
    );
  }
}
