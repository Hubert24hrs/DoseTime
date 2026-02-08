import 'package:dose_time/core/services/streak_service.dart';
import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(todaysScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Doses'),
        centerTitle: false,
        actions: [
          _StreakBadge(),
        ],
      ),
      body: scheduleAsync.when(
        data: (items) {
          if (items.isEmpty) {
             return Center(
              child: Text('No doses scheduled for today!', 
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _DoseCard(item: item);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _DoseCard extends ConsumerWidget {
  final DoseScheduleItem item;

  const _DoseCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDone = item.isTaken || item.isSkipped;
    final color = Color(item.medication.color);

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          side: isDone ? BorderSide.none : BorderSide(color: color.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: isDone ? 0 : 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 16, color: color),
                        const SizedBox(width: 4),
                        Text(
                          (item.medication.frequency == 'As Needed' && item.log == null)
                              ? 'Whenever needed'
                              : item.scheduledTime.format(context),
                          style: TextStyle(
                            color: color, 
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (item.isTaken)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.circular(16)), child: const Text('Taken', style: TextStyle(fontSize: 12)))
                  else if (item.isSkipped)
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(16)), child: const Text('Skipped', style: TextStyle(fontSize: 12)))
                  else if (item.medication.stockQuantity != null && item.medication.refillThreshold != null && item.medication.stockQuantity! <= item.medication.refillThreshold!)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text('Low Stock: ${item.medication.stockQuantity!.toInt()}', style: const TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                       HapticFeedback.selectionClick();
                       _showMedicationInfo(context, item.medication);
                    },
                    child: Semantics(
                      label: 'View details for ${item.medication.name}',
                      button: true,
                      child: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2),
                        radius: 24,
                        child: Icon(
                          item.medication.icon != null 
                            ? IconData(item.medication.icon!, fontFamily: 'MaterialIcons') 
                            : Icons.medication,
                          color: color,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.medication.name,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          item.medication.dosage,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isDone) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ThreeDButton(
                        color: Colors.grey[400]!,
                        onPressed: () => _showSkipOptions(context, ref),
                        child: const Text('Skip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ThreeDButton(
                        color: color,
                        onPressed: () async {
                           await HapticFeedback.lightImpact();
                           ref.read(logDoseProvider)(item, 'taken');
                        },
                        child: const Text('Take', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSkipOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => _SkipOptionsSheet(item: item, parentContext: context),
    );
  }

  void _showMedicationInfo(BuildContext context, Medication medication) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              medication.icon != null 
                ? IconData(medication.icon!, fontFamily: 'MaterialIcons') 
                : Icons.medication,
              color: Color(medication.color),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(medication.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dosage: ${medication.dosage}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Frequency: ${medication.frequency}'),
            const SizedBox(height: 8),
            Text('Scheduled Times: ${medication.times.join(", ")}'),
            if (medication.stockQuantity != null) ...[
              const SizedBox(height: 8),
              Text('Current Stock: ${medication.stockQuantity!.toInt()}', 
                style: TextStyle(
                  color: (medication.refillThreshold != null && medication.stockQuantity! <= medication.refillThreshold!) 
                    ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for skip/snooze/delete options with proper async handling
class _SkipOptionsSheet extends ConsumerStatefulWidget {
  final DoseScheduleItem item;
  final BuildContext parentContext;

  const _SkipOptionsSheet({required this.item, required this.parentContext});

  @override
  ConsumerState<_SkipOptionsSheet> createState() => _SkipOptionsSheetState();
}

class _SkipOptionsSheetState extends ConsumerState<_SkipOptionsSheet> {
  bool _isLoading = false;

  Future<void> _handleAction(String action, String successMessage) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(logDoseProvider)(widget.item, action);
      
      if (!mounted) return;
      Navigator.pop(context);
      
      if (widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: action == 'delete' ? Colors.red : Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to $action dose: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingLog = widget.item.log != null && widget.item.log!.id != null;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manage Dosage',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to do with this dose of ${widget.item.medication.name}?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          
          // Take Later button
          ThreeDButton(
            color: Colors.orange.shade400,
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                final ns = NotificationService();
                await ns.scheduleSnoozeNotification(
                  id: widget.item.medication.id!,
                  title: widget.item.medication.name,
                  body: widget.item.medication.name,
                );
                await HapticFeedback.mediumImpact();
                if (!mounted) return;
                Navigator.pop(context);
                if (widget.parentContext.mounted) {
                  ScaffoldMessenger.of(widget.parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Reminding you again in 10 minutes!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                setState(() => _isLoading = false);
              }
            },
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Take Later (10 mins)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          
          // Skip for Today button
          ThreeDButton(
            color: Colors.grey.shade500,
            onPressed: _isLoading ? null : () async {
              await HapticFeedback.selectionClick();
              await _handleAction('skipped', 'Skipped ${widget.item.medication.name} for today');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.skip_next, color: Colors.white),
                SizedBox(width: 8),
                Text('Skip for Today', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          
          // Delete Entry button - only shown when there's an existing log
          if (hasExistingLog) ...[
            const SizedBox(height: 12),
            ThreeDButton(
              color: Colors.red.shade400,
              onPressed: _isLoading ? null : () async {
                await HapticFeedback.heavyImpact();
                await _handleAction('delete', 'Deleted log for ${widget.item.medication.name}');
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Delete Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: streak >= 7 
                ? [Colors.orange.shade400, Colors.red.shade400]
                : [Colors.teal.shade400, Colors.teal.shade600],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (streak >= 7 ? Colors.orange : Colors.teal).withValues(alpha: 0.3),
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
