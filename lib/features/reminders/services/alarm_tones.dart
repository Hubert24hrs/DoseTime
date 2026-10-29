import 'package:flutter/material.dart';

/// A selectable dose alarm sound. [id] is the Android raw resource name
/// (android/app/src/main/res/raw/<id>.wav).
class AlarmTone {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const AlarmTone({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const String defaultAlarmToneId = 'dose_beep';

const List<AlarmTone> alarmTones = [
  AlarmTone(
    id: 'dose_beep',
    name: 'Classic Beep',
    description: 'The triple beep you know — hard to miss.',
    icon: Icons.notifications_active,
    color: Color(0xFF1C7ED6),
  ),
  AlarmTone(
    id: 'sound_shaker',
    name: 'Pill Shaker',
    description: 'A bottle of pills getting a good shake.',
    icon: Icons.medication,
    color: Color(0xFF26A69A),
  ),
  AlarmTone(
    id: 'sound_digital',
    name: 'Digital Alarm',
    description: 'Fast double beeps, like a bedside clock.',
    icon: Icons.alarm,
    color: Color(0xFFE5484D),
  ),
  AlarmTone(
    id: 'sound_chime',
    name: 'Gentle Chime',
    description: 'Three soft rising notes. Calm but clear.',
    icon: Icons.music_note,
    color: Color(0xFF8E4EC6),
  ),
  AlarmTone(
    id: 'sound_rising',
    name: 'Rising Tone',
    description: 'Upward sweeps that build your attention.',
    icon: Icons.trending_up,
    color: Color(0xFFF5A524),
  ),
  AlarmTone(
    id: 'sound_bell',
    name: 'Soft Bell',
    description: 'One warm bell strike that rings out.',
    icon: Icons.notifications_none,
    color: Color(0xFF3E63DD),
  ),
  AlarmTone(
    id: 'sound_pulse',
    name: 'Heartbeat',
    description: 'A low double thump — easy on the ears at night.',
    icon: Icons.favorite,
    color: Color(0xFFD6409F),
  ),
  AlarmTone(
    id: 'sound_birds',
    name: 'Morning Birds',
    description: 'Bright chirps for a cheerful reminder.',
    icon: Icons.flutter_dash,
    color: Color(0xFF30A46C),
  ),
];

AlarmTone alarmToneById(String? id) =>
    alarmTones.firstWhere((t) => t.id == id, orElse: () => alarmTones.first);
