import 'dart:convert';
import 'dart:io';

import 'package:dose_time/core/database/database_helper.dart';
import 'package:dose_time/features/medication/domain/models/dose_log.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting user data (GDPR compliance)
class DataExportService {
  final DatabaseHelper _dbHelper;

  DataExportService(this._dbHelper);

  /// Export all user data as JSON
  Future<String> exportToJson() async {
    final db = await _dbHelper.database;
    
    // Get all medications
    final medicationsData = await db.query('medications');
    final medications = medicationsData.map((m) => Medication.fromMap(m)).toList();
    
    // Get all dose logs
    final logsData = await db.query('dose_logs');
    final logs = logsData.map((l) => DoseLog.fromMap(l)).toList();
    
    final exportData = {
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': '1.0.0',
      'medications': medications.map((m) => {
        'id': m.id,
        'name': m.name,
        'dosage': m.dosage,
        'frequency': m.frequency,
        'times': m.times,
        'color': m.color,
        'icon': m.icon,
      }).toList(),
      'doseLogs': logs.map((l) => {
        'id': l.id,
        'medicationId': l.medicationId,
        'scheduledTime': l.scheduledTime.toIso8601String(),
        'takenTime': l.takenTime?.toIso8601String(),
        'status': l.status,
      }).toList(),
    };
    
    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Export as CSV
  Future<String> exportToCsv() async {
    final db = await _dbHelper.database;
    
    final medications = await db.query('medications');
    final logs = await db.query('dose_logs');
    
    final medMap = {for (var m in medications) m['id']: m['name']};
    
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Date,Time,Medication,Dosage,Status,Taken At');
    
    // Data rows
    for (final log in logs) {
      final scheduledTime = DateTime.parse(log['scheduled_time'] as String);
      final takenTime = log['taken_time'] != null 
          ? DateTime.parse(log['taken_time'] as String) 
          : null;
      
      buffer.writeln([
        DateFormat('yyyy-MM-dd').format(scheduledTime),
        DateFormat('HH:mm').format(scheduledTime),
        medMap[log['medication_id']] ?? 'Unknown',
        '', // Dosage would need to be looked up
        log['status'],
        takenTime != null ? DateFormat('HH:mm').format(takenTime) : '',
      ].join(','));
    }
    
    return buffer.toString();
  }

  /// Save export to file and share
  Future<void> exportAndShare({bool asJson = true}) async {
    try {
      final content = asJson ? await exportToJson() : await exportToCsv();
      final fileName = 'dosetime_export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.${asJson ? 'json' : 'csv'}';
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'DoseTime Data Export',
        text: 'Your DoseTime medication data export',
      );
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// Delete all user data
  Future<void> deleteAllData() async {
    final db = await _dbHelper.database;
    
    await db.delete('dose_logs');
    await db.delete('medications');
    
    debugPrint('All user data deleted');
  }

  /// Get storage usage stats
  Future<Map<String, int>> getStorageStats() async {
    final db = await _dbHelper.database;
    
    final medicationCount = (await db.rawQuery('SELECT COUNT(*) as count FROM medications')).first['count'] as int;
    final logCount = (await db.rawQuery('SELECT COUNT(*) as count FROM dose_logs')).first['count'] as int;
    
    return {
      'medications': medicationCount,
      'logs': logCount,
    };
  }
}

// Provider
final dataExportServiceProvider = Provider<DataExportService>((ref) {
  return DataExportService(DatabaseHelper.instance);
});
