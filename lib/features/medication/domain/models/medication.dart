import 'dart:convert';

/// Medication types for categorization
enum MedicationType {
  pill,
  capsule,
  liquid,
  injection,
  inhaler,
  drops,
  cream,
  patch,
  other;

  String get displayName {
    switch (this) {
      case MedicationType.pill:
        return 'Pill';
      case MedicationType.capsule:
        return 'Capsule';
      case MedicationType.liquid:
        return 'Liquid';
      case MedicationType.injection:
        return 'Injection';
      case MedicationType.inhaler:
        return 'Inhaler';
      case MedicationType.drops:
        return 'Drops';
      case MedicationType.cream:
        return 'Cream/Ointment';
      case MedicationType.patch:
        return 'Patch';
      case MedicationType.other:
        return 'Other';
    }
  }

  static MedicationType fromString(String? value) {
    return MedicationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MedicationType.pill,
    );
  }
}

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String frequency; // 'Daily', 'As Needed', 'Specific Days'
  final List<String> times; // ["08:00", "20:00"]
  final int color;
  final int? icon;
  final double? stockQuantity;
  final double? refillThreshold;
  
  // New fields
  final MedicationType type;
  final String? instructions;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? imagePath;
  final bool isArchived;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.times,
    required this.color,
    this.icon,
    this.stockQuantity,
    this.refillThreshold,
    this.type = MedicationType.pill,
    this.instructions,
    this.startDate,
    this.endDate,
    this.imagePath,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'times': jsonEncode(times),
      'color': color,
      'icon': icon,
      'stock_quantity': stockQuantity,
      'refill_threshold': refillThreshold,
      'medication_type': type.name,
      'instructions': instructions,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'image_path': imagePath,
      'is_archived': isArchived ? 1 : 0,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'],
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      times: List<String>.from(jsonDecode(map['times'])),
      color: map['color'],
      icon: map['icon'],
      stockQuantity: map['stock_quantity']?.toDouble(),
      refillThreshold: map['refill_threshold']?.toDouble(),
      type: MedicationType.fromString(map['medication_type']),
      instructions: map['instructions'],
      startDate: map['start_date'] != null ? DateTime.tryParse(map['start_date']) : null,
      endDate: map['end_date'] != null ? DateTime.tryParse(map['end_date']) : null,
      imagePath: map['image_path'],
      isArchived: map['is_archived'] == 1,
    );
  }

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    String? frequency,
    List<String>? times,
    int? color,
    int? icon,
    double? stockQuantity,
    double? refillThreshold,
    MedicationType? type,
    String? instructions,
    DateTime? startDate,
    DateTime? endDate,
    String? imagePath,
    bool? isArchived,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      refillThreshold: refillThreshold ?? this.refillThreshold,
      type: type ?? this.type,
      instructions: instructions ?? this.instructions,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      imagePath: imagePath ?? this.imagePath,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
