import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/core/widgets/pill_avatar.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/reminders/services/alarm_sound.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Full-screen "time to take your meds" alarm. Beeps until the user chooses
/// Take, Skip or Snooze for the doses due at [time] (HH:mm, or 'test').
class AlarmScreen extends ConsumerStatefulWidget {
  final String time;

  const AlarmScreen({super.key, required this.time});

  @override
  ConsumerState<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends ConsumerState<AlarmScreen> {
  final Set<int> _deselected = {};
  bool _busy = false;

  bool get _isTest => widget.time == 'test';

  @override
  void initState() {
    super.initState();
    AlarmSound.start(sound: ref.read(settingsServiceProvider).alarmSound);
  }

  @override
  void dispose() {
    AlarmSound.stop();
    super.dispose();
  }

  void _close() {
    AlarmSound.stop();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  List<DoseScheduleItem> _dueItems(List<DoseScheduleItem> items) {
    return items
        .where((i) => !i.isAsNeeded && !i.isDone && i.timeKey == widget.time)
        .toList();
  }

  Future<void> _apply(List<DoseScheduleItem> due, String action) async {
    if (_busy) return;
    setState(() => _busy = true);
    await AlarmSound.stop();
    HapticFeedback.mediumImpact();

    final selected = due.where((i) => !_deselected.contains(i.medication.id)).toList();
    final settings = ref.read(settingsServiceProvider);
    final messenger = ScaffoldMessenger.maybeOf(context);

    try {
      if (action == 'snooze') {
        final minutes = settings.defaultSnoozeDuration;
        for (final item in selected) {
          // The snooze alarm replaces the rest of today's follow-ups.
          await ReminderScheduler.markHandled(item.medication, item.timeKey);
          await NotificationService().scheduleSnoozeNotification(
            id: item.medication.id! * 1440 + item.scheduledTime.hour * 60 + item.scheduledTime.minute,
            title: 'Time for ${item.medication.name}',
            body: 'Take ${item.medication.dosage}',
            minutes: minutes,
            payload: doseAlarmPayload(item.medication.id!, item.timeKey),
          );
        }
        messenger?.showSnackBar(SnackBar(content: Text('Snoozed for $minutes minutes')));
      } else {
        for (final item in selected) {
          await ref.read(logDoseProvider)(item, action);
        }
        if (selected.isNotEmpty) {
          messenger?.showSnackBar(SnackBar(
            content: Text(action == 'taken'
                ? 'Great job! ${selected.length} dose(s) marked as taken'
                : '${selected.length} dose(s) skipped'),
          ));
        }
      }
    } finally {
      if (mounted) _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(todaysScheduleProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF2A3038),
        body: SafeArea(
          child: scheduleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (e, _) => _buildBody(context, const []),
            data: (items) => _buildBody(context, _dueItems(items)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<DoseScheduleItem> due) {
    final timeLabel = _isTest
        ? DateFormat.Hm().format(DateTime.now())
        : widget.time;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const Icon(Icons.medication_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('DoseAlert',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                tooltip: 'Silence',
                onPressed: AlarmSound.stop,
                icon: const Icon(Icons.volume_off_outlined, color: Colors.white70),
              ),
            ],
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const _PulsingBell(),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _isTest
                      ? 'This is a test. Your dose reminders will beep like this.'
                      : 'Hello, it\'s time to take your $timeLabel meds.',
                  style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.grey.shade100, Colors.white],
                    ),
                  ),
                  child: Text(
                    timeLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w600, color: Color(0xFF1B2733)),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35),
                  child: due.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _isTest ? 'Sample Medication · Take 1 pill(s)' : 'All doses for this time are done.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: due.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                          itemBuilder: (context, i) => _dueTile(due[i]),
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundAction(
                        icon: Icons.close,
                        label: 'SKIP',
                        filled: false,
                        onTap: _busy ? null : () => due.isEmpty ? _close() : _apply(due, 'skipped'),
                      ),
                      _RoundAction(
                        icon: Icons.check,
                        label: 'TAKE',
                        filled: true,
                        onTap: _busy ? null : () => due.isEmpty ? _close() : _apply(due, 'taken'),
                      ),
                      _RoundAction(
                        icon: Icons.alarm,
                        label: 'SNOOZE',
                        filled: false,
                        onTap: _busy ? null : () => due.isEmpty ? _close() : _apply(due, 'snooze'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _dueTile(DoseScheduleItem item) {
    final med = item.medication;
    final selected = !_deselected.contains(med.id);
    return ListTile(
      onTap: () => setState(() {
        selected ? _deselected.add(med.id!) : _deselected.remove(med.id);
      }),
      leading: PillAvatar(medication: med, size: 44),
      title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        'Take ${med.dosage}\nScheduled for ${item.timeKey}, today, ${DateFormat('d MMM').format(item.date)}',
      ),
      isThreeLine: true,
      trailing: Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        color: selected ? AppTheme.primaryColor : Colors.grey,
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback? onTap;

  const _RoundAction({
    required this.icon,
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = filled ? 64.0 : 52.0;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppTheme.primaryColor : brandBlue.shade50,
                  boxShadow: filled
                      ? [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                      : null,
                ),
                child: Icon(icon, color: filled ? Colors.white : AppTheme.primaryColor, size: filled ? 32 : 24),
              ),
              const SizedBox(height: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingBell extends StatefulWidget {
  const _PulsingBell();

  @override
  State<_PulsingBell> createState() => _PulsingBellState();
}

class _PulsingBellState extends State<_PulsingBell> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryColor,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
              blurRadius: 6 + 16 * _c.value,
              spreadRadius: 6 * _c.value,
            ),
          ],
        ),
        child: Transform.rotate(
          angle: (_c.value - 0.5) * 0.5,
          child: const Icon(Icons.notifications_active, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
