import 'package:dose_time/core/services/streak_service.dart';
import 'package:dose_time/core/services/ad_service.dart';
import 'package:dose_time/core/services/purchase_service.dart';
import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/core/widgets/pill_avatar.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/presentation/widgets/dose_wheel.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/reminders/services/reminder_scheduler.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  DosePeriod? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() async {
    final isPro = await ref.read(isProUserProvider.future);
    if (!isPro) {
      ref.read(adServiceProvider).loadInterstitialAd();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() async {
    // Check pro status first
    final isPro = await ref.read(isProUserProvider.future);
    if (isPro) return;

    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          debugPrint('HomeScreen: Banner Ad failed to load - $err');
        },
      ),
    )..load();
  }

  void _shiftDay(int days) {
    HapticFeedback.selectionClick();
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state = DateTime(current.year, current.month, current.day + days);
    setState(() => _selectedPeriod = null);
  }

  @override
  Widget build(BuildContext context) {
    final date = ref.watch(selectedDateProvider);
    final scheduleAsync = ref.watch(scheduleForDateProvider(date));
    final asNeededAsync = ref.watch(asNeededMedicationsProvider);
    final isProAsync = ref.watch(isProUserProvider);
    final isToday = DateUtils.isSameDay(date, DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          _Header(onAdd: () => context.push('/medications/add')),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(scheduleForDateProvider(date)),
              child: scheduleAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (items) {
                  final visible = _selectedPeriod == null
                      ? items
                      : items.where((i) => i.period == _selectedPeriod).toList();
                  final asNeeded = asNeededAsync.valueOrNull ?? const <Medication>[];
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Container(
                        color: Theme.of(context).colorScheme.surface,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Column(
                          children: [
                            Center(
                              child: DoseWheel(
                                items: items,
                                currentPeriod: isToday ? DosePeriod.of(TimeOfDay.now()) : null,
                                selectedPeriod: _selectedPeriod,
                                onPeriodTap: (p) {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedPeriod = _selectedPeriod == p ? null : p);
                                },
                              ),
                            ),
                            _DayNavigator(
                              date: date,
                              onPrev: () => _shiftDay(-1),
                              onNext: () => _shiftDay(1),
                              onToday: isToday
                                  ? null
                                  : () {
                                      final now = DateTime.now();
                                      ref.read(selectedDateProvider.notifier).state =
                                          DateTime(now.year, now.month, now.day);
                                    },
                            ),
                          ],
                        ),
                      ),
                      if (_selectedPeriod != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: InputChip(
                              avatar: Icon(_selectedPeriod!.icon, size: 18),
                              label: Text('Showing ${_selectedPeriod!.label}'),
                              onDeleted: () => setState(() => _selectedPeriod = null),
                            ),
                          ),
                        ),
                      if (items.isEmpty && asNeeded.isEmpty)
                        _EmptyState(onAdd: () => context.push('/medications/add'))
                      else ...[
                        for (final period in DosePeriod.values)
                          if (visible.any((i) => i.period == period))
                            _PeriodSection(
                              period: period,
                              items: visible.where((i) => i.period == period).toList(),
                            ),
                        if (visible.isEmpty && items.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'No doses in the ${_selectedPeriod?.label.toLowerCase()}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        if (asNeeded.isNotEmpty && isToday && _selectedPeriod == null)
                          _AsNeededSection(medications: asNeeded),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          // Ad Banner
          isProAsync.when(
            data: (isPro) {
              if (!isPro && _isBannerAdLoaded && _bannerAd != null) {
                return Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onAdd;

  const _Header({required this.onAdd});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark ? AppTheme.surfaceDark : AppTheme.headerColor,
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 8, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(),
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                Text(DateFormat('EEEE, d MMMM').format(DateTime.now()),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
              ],
            ),
          ),
          _StreakBadge(),
          IconButton(
            tooltip: 'Add medication',
            onPressed: onAdd,
            icon: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _DayNavigator extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  const _DayNavigator({required this.date, required this.onPrev, required this.onNext, this.onToday});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    final label = switch (diff) {
      0 => 'Today',
      -1 => 'Yesterday',
      1 => 'Tomorrow',
      _ => DateFormat('EEEE').format(date),
    };
    return Row(
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left, color: AppTheme.primaryColor)),
        Expanded(
          child: GestureDetector(
            onTap: onToday,
            child: Column(
              children: [
                Text(
                  '$label, ${DateFormat('MMM d').format(date)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (onToday != null)
                  const Text('Tap to go back to today',
                      style: TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
              ],
            ),
          ),
        ),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right, color: AppTheme.primaryColor)),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: brandBlue.shade50, shape: BoxShape.circle),
            child: const Icon(Icons.medication_outlined, size: 36, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('No meds scheduled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            'Add your medications and DoseAlert will beep when it\'s time to take them.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add a medication'),
          ),
        ],
      ),
    );
  }
}

class _PeriodSection extends StatelessWidget {
  final DosePeriod period;
  final List<DoseScheduleItem> items;

  const _PeriodSection({required this.period, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(period.icon, size: 18, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(period.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 76),
                  _DoseRow(item: items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseRow extends ConsumerWidget {
  final DoseScheduleItem item;

  const _DoseRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final med = item.medication;
    final lowStock = med.stockQuantity != null &&
        med.refillThreshold != null &&
        med.stockQuantity! <= med.refillThreshold!;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => _DoseActionSheet(item: item, parentContext: context),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Opacity(opacity: item.isDone ? 0.5 : 1, child: PillAvatar(medication: med)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: item.isDone ? Colors.grey : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.scheduledTime.format(context)} · ${med.dosage}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (lowStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${med.stockQuantity!.toInt()} left · refill soon',
                        style: const TextStyle(color: AppTheme.warningColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            _StatusTag(item: item),
          ],
        ),
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final DoseScheduleItem item;

  const _StatusTag({required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.isTaken) {
      final t = item.log?.takenTime;
      return _tag(Icons.check_circle, t != null ? 'Taken ${DateFormat.Hm().format(t)}' : 'Taken',
          AppTheme.successColor);
    }
    if (item.isSkipped) return _tag(Icons.remove_circle_outline, 'Skipped', Colors.grey);
    if (item.isMissed) return _tag(Icons.error_outline, 'Missed', AppTheme.warningColor);
    return const Icon(Icons.chevron_right, color: Colors.grey);
  }

  Widget _tag(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AsNeededSection extends ConsumerWidget {
  final List<Medication> medications;

  const _AsNeededSection({required this.medications});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.back_hand_outlined, size: 18, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('As needed',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                for (final med in medications)
                  ListTile(
                    leading: PillAvatar(medication: med, size: 40),
                    title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(med.dosage),
                    trailing: TextButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await ref.read(logAsNeededProvider)(med);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logged a dose of ${med.name}')),
                          );
                        }
                      },
                      child: const Text('Take now'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with the dose card: Skip / Take / Snooze, like the alarm screen.
class _DoseActionSheet extends ConsumerStatefulWidget {
  final DoseScheduleItem item;
  final BuildContext parentContext;

  const _DoseActionSheet({required this.item, required this.parentContext});

  @override
  ConsumerState<_DoseActionSheet> createState() => _DoseActionSheetState();
}

class _DoseActionSheetState extends ConsumerState<_DoseActionSheet> {
  bool _isLoading = false;

  DoseScheduleItem get item => widget.item;

  Future<void> _run(Future<void> Function() action, String message) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await action();
      if (!mounted) return;
      Navigator.pop(context);
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Something went wrong: $e')));
    }
  }

  Future<void> _take() async {
    await HapticFeedback.lightImpact();
    final isPro = await ref.read(isProUserProvider.future);
    await _run(() => ref.read(logDoseProvider)(item, 'taken'), '${item.medication.name} marked as taken');
    ref.read(adServiceProvider).showInterstitialAd(isPro);
  }

  Future<void> _snooze() async {
    final minutes = ref.read(settingsServiceProvider).defaultSnoozeDuration;
    await _run(() async {
      await ReminderScheduler.markHandled(item.medication, item.timeKey);
      await NotificationService().scheduleSnoozeNotification(
        id: item.medication.id! * 1440 + item.scheduledTime.hour * 60 + item.scheduledTime.minute,
        title: 'Time for ${item.medication.name}',
        body: 'Take ${item.medication.dosage}',
        minutes: minutes,
        payload: doseAlarmPayload(item.medication.id!, item.timeKey),
      );
      await HapticFeedback.mediumImpact();
    }, 'We\'ll beep again in $minutes minutes');
  }

  @override
  Widget build(BuildContext context) {
    final med = item.medication;
    final now = DateTime.now();
    final isFuture = item.date.isAfter(DateTime(now.year, now.month, now.day));
    final isToday = DateUtils.isSameDay(item.date, now);
    final hasLog = item.log?.id != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              item.scheduledTime.format(context),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                PillAvatar(medication: med, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(med.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      Text('Take ${med.dosage}', style: TextStyle(color: Colors.grey.shade700)),
                      Text(
                        'Scheduled for ${item.timeKey}, ${DateFormat('EEE d MMM').format(item.date)}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      if (med.instructions != null && med.instructions!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(med.instructions!,
                              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
            else if (isFuture)
              Text('You can log this dose on the day.', style: TextStyle(color: Colors.grey.shade600))
            else if (item.isDone)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _run(
                        () => ref.read(logDoseProvider)(item, 'delete'),
                        'Reset ${med.name} to pending',
                      ),
                      icon: const Icon(Icons.undo),
                      label: Text(item.isTaken ? 'Un-take' : 'Undo skip'),
                    ),
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SheetAction(
                    icon: Icons.close,
                    label: 'SKIP',
                    onTap: () => _run(() => ref.read(logDoseProvider)(item, 'skipped'), 'Skipped ${med.name}'),
                  ),
                  _SheetAction(icon: Icons.check, label: 'TAKE', primary: true, onTap: _take),
                  if (isToday) _SheetAction(icon: Icons.alarm, label: 'SNOOZE', onTap: _snooze),
                ],
              ),
            if (hasLog && !item.isDone) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _run(() => ref.read(logDoseProvider)(item, 'delete'), 'Deleted log'),
                child: const Text('Delete entry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, required this.onTap, this.primary = false});

  @override
  Widget build(BuildContext context) {
    final size = primary ? 64.0 : 52.0;
    return InkWell(
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
                color: primary ? AppTheme.primaryColor : brandBlue.shade50,
              ),
              child: Icon(icon, color: primary ? Colors.white : AppTheme.primaryColor, size: primary ? 32 : 24),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Streak badge displayed in the app bar
class _StreakBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final streakService = StreakService();
    final streak = streakService.currentStreak;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showStreakDialog(context, streakService);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak >= 7 
                ? [Colors.orange.shade400, Colors.red.shade400]
                : [Colors.white.withValues(alpha: 0.22), Colors.white.withValues(alpha: 0.22)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (streak >= 7 ? Colors.orange : Colors.transparent).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              streak >= 7 ? '🔥' : '📅',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 4),
            Text(
              '$streak',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStreakDialog(BuildContext context, StreakService streakService) {
    final streak = streakService.currentStreak;
    final longest = streakService.longestStreak;
    final message = streakService.getMotivationalMessage();
    final achievements = streakService.achievements;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(streak >= 7 ? '🔥' : '📅', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            const Expanded(child: Text('Your Streak')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _StatCard(
                  icon: Icons.local_fire_department,
                  label: 'Current',
                  value: '$streak days',
                  color: Colors.orange,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  icon: Icons.emoji_events,
                  label: 'Best',
                  value: '$longest days',
                  color: Colors.amber,
                ),
              ],
            ),
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Achievements',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: achievements.map((id) {
                  final emoji = _getAchievementEmoji(id);
                  return Chip(
                    label: Text(emoji),
                    backgroundColor: Colors.amber.shade100,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep it up!'),
          ),
        ],
      ),
    );
  }

  String _getAchievementEmoji(String id) {
    switch (id) {
      case 'streak_3': return '🌱';
      case 'streak_7': return '🔥';
      case 'streak_14': return '⭐';
      case 'streak_30': return '🏆';
      case 'streak_60': return '👑';
      case 'streak_100': return '💯';
      case 'streak_365': return '🎉';
      default: return '✨';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
