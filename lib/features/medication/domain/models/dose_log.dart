class DoseLog {
  final int? id;
  final int medicationId;
  final DateTime scheduledTime;
  final DateTime? takenTime;
  final String status; // 'pending', 'taken', 'skipped', 'missed'

  DoseLog({
    this.id,
    required this.medicationId,
    required this.scheduledTime,
    this.takenTime,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medication_id': medicationId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'taken_time': takenTime?.toIso8601String(),
      'status': status,
    };
  }

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'],
      medicationId: map['medication_id'],
      scheduledTime: DateTime.parse(map['scheduled_time']),
      takenTime: map['taken_time'] != null ? DateTime.parse(map['taken_time']) : null,
      status: map['status'],
    );
  }

  DoseLog copyWith({
    int? id,
    int? medicationId,
    DateTime? scheduledTime,
    DateTime? takenTime,
    String? status,
  }) {
    return DoseLog(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      takenTime: takenTime ?? this.takenTime,
      status: status ?? this.status,
    );
  }
}
