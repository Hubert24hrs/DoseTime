import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(historyLogsProvider);
    final medsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) {
            return const Center(child: Text('No history yet.'));
          }

          return medsAsync.when(
            data: (meds) {
              // Map meds for name lookup
              final medMap = {for (var m in meds) m.id: m};

              return ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  final med = medMap[log.medicationId];
                  
                  final displayName = log.medicationName ?? med?.name ?? 'Unknown Medication';
                  final displayColor = log.medicationColor != null ? Color(log.medicationColor!) : (med != null ? Color(med.color) : Colors.grey);
                  
                  final dateStr = DateFormat('MMM d, y • HH:mm').format(log.scheduledTime);
                  
                  return ListTile(
                    leading: Icon(
                      log.status == 'taken' ? Icons.check_circle : 
                      log.status == 'skipped' ? Icons.remove_circle : Icons.warning,
                      color: log.status == 'taken' ? Colors.green : 
                             log.status == 'skipped' ? Colors.grey : Colors.red,
                    ),
                    title: Text(
                      displayName,
                      style: TextStyle(color: displayColor, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$dateStr - ${log.status.toUpperCase()}'),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
