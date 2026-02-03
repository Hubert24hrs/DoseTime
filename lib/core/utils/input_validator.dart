/// Input validation and sanitization utilities for security
class InputValidator {
  static const int maxMedicationNameLength = 100;
  static const int maxDosageLength = 50;
  static const int maxTimesPerDay = 24;

  /// Validate medication name
  static ValidationResult validateMedicationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('Please enter a medication name');
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length > maxMedicationNameLength) {
      return ValidationResult.invalid(
        'Name must be less than $maxMedicationNameLength characters'
      );
    }
    
    // Sanitize: remove any potentially dangerous characters
    if (_containsSqlInjectionPatterns(trimmed)) {
      return ValidationResult.invalid('Invalid characters in medication name');
    }
    
    return ValidationResult.valid(trimmed);
  }

  /// Validate dosage input
  static ValidationResult validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.invalid('Please enter dosage');
    }
    
    final trimmed = value.trim();
    
    if (trimmed.length > maxDosageLength) {
      return ValidationResult.invalid(
        'Dosage must be less than $maxDosageLength characters'
      );
    }
    
    if (_containsSqlInjectionPatterns(trimmed)) {
      return ValidationResult.invalid('Invalid characters in dosage');
    }
    
    return ValidationResult.valid(trimmed);
  }

  /// Validate reminder times
  static ValidationResult validateTimes(List<String>? times) {
    if (times == null || times.isEmpty) {
      return ValidationResult.invalid('Please add at least one reminder time');
    }
    
    if (times.length > maxTimesPerDay) {
      return ValidationResult.invalid(
        'Maximum $maxTimesPerDay reminders per day'
      );
    }
    
    // Validate time format (HH:MM)
    final timePattern = RegExp(r'^([0-1]?[0-9]|2[0-3]):([0-5][0-9])$');
    for (final time in times) {
      if (!timePattern.hasMatch(time)) {
        return ValidationResult.invalid('Invalid time format: $time');
      }
    }
    
    return ValidationResult.valid(times.join(','));
  }

  /// Check for common SQL injection patterns
  static bool _containsSqlInjectionPatterns(String input) {
    final patterns = [
      RegExp("['\\\"];", caseSensitive: false),
      RegExp(r"--", caseSensitive: false),
      RegExp(r"/\*", caseSensitive: false),
      RegExp(r"\*/", caseSensitive: false),
      RegExp(r"\bDROP\b", caseSensitive: false),
      RegExp(r"\bDELETE\b", caseSensitive: false),
      RegExp(r"\bINSERT\b", caseSensitive: false),
      RegExp(r"\bUPDATE\b", caseSensitive: false),
      RegExp(r"\bSELECT\b", caseSensitive: false),
      RegExp(r"\bUNION\b", caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }
    return false;
  }

  /// Sanitize string for safe storage (escape special chars)
  static String sanitize(String input) {
    return input
        .replaceAll("'", "''") // Escape single quotes for SQL
        .replaceAll('"', '\\"') // Escape double quotes
        .trim();
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedValue;

  ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.sanitizedValue,
  });

  factory ValidationResult.valid(String sanitizedValue) {
    return ValidationResult._(
      isValid: true,
      sanitizedValue: sanitizedValue,
    );
  }

  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
