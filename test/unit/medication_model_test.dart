import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';

void main() {
  group('Medication Model', () {
    test('should create correct TimeOfDay list from valid strings', () {
      final med = Medication(
        name: 'Test Med',
        dosage: '10mg',
        frequency: 'Daily',
        times: ['08:00', '20:00'],
        color: Colors.blue.toARGB32(),
        type: MedicationType.pill,
      );

      final timeOfDays = med.times.map((t) {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }).toList();
      
      expect(timeOfDays.length, 2);
      expect(timeOfDays[0].hour, 8);
      expect(timeOfDays[0].minute, 0);
      expect(timeOfDays[1].hour, 20);
      expect(timeOfDays[1].minute, 0);
    });

    test('should handle copyWith correctly', () {
      final med = Medication(
        name: 'Test Med',
        dosage: '10mg',
        frequency: 'Daily',
        times: ['08:00'],
        color: Colors.blue.toARGB32(),
        type: MedicationType.pill,
        isArchived: false,
      );

      final updated = med.copyWith(
        name: 'Updated Med',
        isArchived: true,
      );

      expect(updated.name, 'Updated Med');
      expect(updated.dosage, '10mg'); // Unchanged
      expect(updated.isArchived, true);
    });

    test('should serialize to Map correctly', () {
      final med = Medication(
        id: 1,
        name: 'Test Med',
        dosage: '10mg',
        frequency: 'Daily',
        times: ['08:00'],
        color: 4294901760, // Red
        type: MedicationType.liquid,
        instructions: 'Take with food',
      );

      final map = med.toMap();
      expect(map['id'], 1);
      expect(map['name'], 'Test Med');
      expect(map['medication_type'], 'liquid');
      expect(map['instructions'], 'Take with food');
    });
  });
}
