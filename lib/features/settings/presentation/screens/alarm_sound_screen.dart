import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/reminders/services/alarm_sound.dart';
import 'package:dose_time/features/reminders/services/alarm_tones.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Lets the user pick (and preview) the sound dose alarms play.
class AlarmSoundScreen extends ConsumerStatefulWidget {
  const AlarmSoundScreen({super.key});

  @override
  ConsumerState<AlarmSoundScreen> createState() => _AlarmSoundScreenState();
}

class _AlarmSoundScreenState extends ConsumerState<AlarmSoundScreen> {
  late String _selected = ref.read(settingsServiceProvider).alarmSound;
  bool _saving = false;

  @override
  void dispose() {
    AlarmSound.stop();
    super.dispose();
  }

  void _pick(AlarmTone tone) {
    setState(() => _selected = tone.id);
    AlarmSound.preview(tone.id);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await AlarmSound.stop();
    await ref.read(settingsServiceProvider).setAlarmSound(_selected);
    await NotificationService().setAlarmTone(_selected);
    await ReminderScheduler.syncAll(ref.read(medicationRepositoryProvider));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dose alarms will now play "${alarmToneById(_selected).name}"')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Sound'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tile strip across the top, one per tone.
          Container(
            color: isDark ? AppTheme.surfaceDark : AppTheme.headerColor.withValues(alpha: 0.08),
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: alarmTones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final tone = alarmTones[i];
                final selected = tone.id == _selected;
                return GestureDetector(
                  onTap: () => _pick(tone),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 72 : 64,
                    decoration: BoxDecoration(
                      color: tone.color,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 3),
                      boxShadow: selected
                          ? [BoxShadow(color: tone.color.withValues(alpha: 0.5), blurRadius: 10)]
                          : null,
                    ),
                    child: Icon(tone.icon, color: Colors.white, size: selected ? 34 : 28),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Text('ALARM TONES',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                const Spacer(),
                Text('Tap to preview', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: alarmTones.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 16),
              itemBuilder: (context, i) {
                final tone = alarmTones[i];
                final selected = tone.id == _selected;
                return ListTile(
                  onTap: () => _pick(tone),
                  title: Text(
                    tone.name.toUpperCase(),
                    style: TextStyle(color: tone.color, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                  ),
                  subtitle: Text(tone.description),
                  trailing: selected
                      ? const Icon(Icons.check, color: AppTheme.primaryColor)
                      : IconButton(
                          tooltip: 'Preview',
                          icon: Icon(Icons.play_circle_outline, color: Colors.grey.shade500),
                          onPressed: () => AlarmSound.preview(tone.id),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
