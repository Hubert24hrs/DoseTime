import 'package:flutter_test/flutter_test.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';

void main() {
  group('Medication Model', () {
    test('should create medication with required fields', () {
      final medication = Medication(
        name: 'Aspirin',
        dosage: '100mg',
        frequency: 'Daily',
        times: ['08:00', '20:00'],
        color: 0xFF4CAF50,
      );

      expect(medication.name, 'Aspirin');
      expect(medication.dosage, '100mg');
      expect(medication.frequency, 'Daily');
      expect(medication.times.length, 2);
      expect(medication.color, 0xFF4CAF50);
      expect(medication.id, isNull);
      expect(medication.icon, isNull);
    });

    test('should convert to map correctly', () {
      final medication = Medication(
        id: 1,
        name: 'Aspirin',
        dosage: '100mg',
        frequency: 'Daily',
        times: ['08:00'],
        color: 0xFF4CAF50,
        icon: 0xe3f3, // medication icon code
      );

      final map = medication.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Aspirin');
      expect(map['dosage'], '100mg');
      expect(map['frequency'], 'Daily');
      expect(map['times'], '["08:00"]');
      expect(map['color'], 0xFF4CAF50);
      expect(map['icon'], 0xe3f3);
    });

    test('should create from map correctly', () {
      final map = {
        'id': 1,
        'name': 'Aspirin',
        'dosage': '100mg',
        'frequency': 'Daily',
        'times': '["08:00","20:00"]',
        'color': 0xFF4CAF50,
        'icon': null,
      };

      final medication = Medication.fromMap(map);

      expect(medication.id, 1);
      expect(medication.name, 'Aspirin');
      expect(medication.times, ['08:00', '20:00']);
    });

    test('should copy with modifications', () {
      final original = Medication(
        id: 1,
        name: 'Aspirin',
        dosage: '100mg',
        frequency: 'Daily',
        times: ['08:00'],
        color: 0xFF4CAF50,
      );

      final modified = original.copyWith(
        name: 'Ibuprofen',
        dosage: '200mg',
      );

      expect(modified.id, 1);
      expect(modified.name, 'Ibuprofen');
      expect(modified.dosage, '200mg');
      expect(modified.frequency, 'Daily'); // unchanged
    });
  });
}
