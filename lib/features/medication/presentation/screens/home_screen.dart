import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
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
                          item.scheduledTime.format(context),
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
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
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
                      child: OutlinedButton(
                        onPressed: () {
                           ref.read(logDoseProvider)(item, 'skipped');
                        },
                        child: const Text('Skip'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color, 
                          foregroundColor: Colors.white
                        ),
                        onPressed: () {
                           ref.read(logDoseProvider)(item, 'taken');
                        },
                        child: const Text('Take'),
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
}
