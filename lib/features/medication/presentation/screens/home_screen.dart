import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
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
                    onTap: () => _showMedicationInfo(context, item.medication),
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
      builder: (context) => Padding(
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
              'What do you want to do with this dose of ${item.medication.name}?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ThreeDButton(
              color: Colors.orange.shade400,
              onPressed: () async {
                Navigator.pop(context);
                final ns = NotificationService();
                await ns.scheduleSnoozeNotification(
                  id: item.medication.id!,
                  title: item.medication.name,
                  body: item.medication.name,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminding you again in 10 minutes!'))
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Take Later (10 mins)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ThreeDButton(
              color: Colors.grey.shade500,
              onPressed: () {
                Navigator.pop(context);
                ref.read(logDoseProvider)(item, 'skipped');
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
            const SizedBox(height: 12),
            ThreeDButton(
              color: Colors.red.shade400,
              onPressed: () {
                Navigator.pop(context);
                ref.read(logDoseProvider)(item, 'delete');
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
        ),
      ),
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
