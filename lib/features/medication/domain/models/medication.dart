import 'dart:convert';

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String frequency; // 'daily', 'specific_days', 'as_needed'
  final List<String> times; // ["08:00", "20:00"]
  final int color;
  final int? icon;
  final double? stockQuantity;
  final double? refillThreshold;

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
    );
  }
}
