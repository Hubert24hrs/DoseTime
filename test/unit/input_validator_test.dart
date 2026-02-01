import 'package:flutter_test/flutter_test.dart';
import 'package:dose_time/core/utils/input_validator.dart';

void main() {
  group('InputValidator - Medication Name', () {
    test('should return invalid for empty name', () {
      final result = InputValidator.validateMedicationName('');
      expect(result.isValid, false);
      expect(result.errorMessage, 'Please enter a medication name');
    });

    test('should return invalid for null name', () {
      final result = InputValidator.validateMedicationName(null);
      expect(result.isValid, false);
    });

    test('should return valid for normal name', () {
      final result = InputValidator.validateMedicationName('Aspirin');
      expect(result.isValid, true);
      expect(result.sanitizedValue, 'Aspirin');
    });

    test('should trim whitespace', () {
      final result = InputValidator.validateMedicationName('  Aspirin  ');
      expect(result.isValid, true);
      expect(result.sanitizedValue, 'Aspirin');
    });

    test('should reject SQL injection patterns', () {
      final result = InputValidator.validateMedicationName("'; DROP TABLE medications;--");
      expect(result.isValid, false);
    });

    test('should reject long names', () {
      final longName = 'A' * 101;
      final result = InputValidator.validateMedicationName(longName);
      expect(result.isValid, false);
    });
  });

  group('InputValidator - Dosage', () {
    test('should return invalid for empty dosage', () {
      final result = InputValidator.validateDosage('');
      expect(result.isValid, false);
    });

    test('should return valid for normal dosage', () {
      final result = InputValidator.validateDosage('50mg');
      expect(result.isValid, true);
    });

    test('should accept complex dosage formats', () {
      final result = InputValidator.validateDosage('1 pill, twice daily');
      expect(result.isValid, true);
    });
  });

  group('InputValidator - Times', () {
    test('should return invalid for empty times list', () {
      final result = InputValidator.validateTimes([]);
      expect(result.isValid, false);
    });

    test('should return valid for proper time format', () {
      final result = InputValidator.validateTimes(['08:00', '20:00']);
      expect(result.isValid, true);
    });

    test('should reject invalid time format', () {
      final result = InputValidator.validateTimes(['25:00']);
      expect(result.isValid, false);
    });

    test('should reject too many times', () {
      final times = List.generate(25, (i) => '${i.toString().padLeft(2, '0')}:00');
      final result = InputValidator.validateTimes(times);
      expect(result.isValid, false);
    });
  });
}
