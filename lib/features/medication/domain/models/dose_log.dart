class DoseLog {
  final int? id;
  final int medicationId;
  final String? medicationName; // Persisted name for history
  final int? medicationColor; // Persisted color for history
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // 'pending', 'taken', 'skipped', 'missed'

  DoseLog({
    this.id,
    required this.medicationId,
    this.medicationName,
    this.medicationColor,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'medication_name': medicationName,
      'medication_color': medicationColor,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status,
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'],
      medicationId: map['medication_id'],
      medicationName: map['medication_name'],
      medicationColor: map['medication_color'],
      scheduledTime: DateTime.parse(map['scheduled_time']),
      takenTime: map['taken_time'] != null ? DateTime.parse(map['taken_time']) : null,
      status: map['status'],
    );
  }

  DoseLog copyWith({
    int? id,
    int? medicationId,
    String? medicationName,
    int? medicationColor,
    DateTime? scheduledTime,
    DateTime? takenTime,
    String? status,
  }) {
    return DoseLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      medicationColor: medicationColor ?? this.medicationColor,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
    );
  }
}
