import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MedicationListScreen extends ConsumerWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicationsAsync = ref.watch(medicationListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Medications'),
      ),
      body: medicationsAsync.when(
        data: (medications) {
          if (medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.medication_outlined, size: 64, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text('No medications yet', style: TextStyle(color: Colors.grey[600], fontSize: 18)),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => context.go('/medications/add'),
                     icon: const Icon(Icons.add),
                     label: const Text('Add Medication'),
                   )
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: medications.length,
            itemBuilder: (context, index) {
              final med = medications[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(med.color).withValues(alpha: 0.2),
                    child: Icon(
                      med.icon != null ? IconData(med.icon!, fontFamily: 'MaterialIcons') : Icons.medication,
                      color: Color(med.color),
                    ),
                  ),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${med.dosage} • ${med.frequency}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _confirmDelete(context, ref, med.id!),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: medicationsAsync.hasValue && medicationsAsync.value!.isNotEmpty 
        ? FloatingActionButton(
            onPressed: () => context.go('/medications/add'),
            child: const Icon(Icons.add),
          )
        : null,
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, int id) async {
    await HapticFeedback.mediumImpact();
    
    if (!context.mounted) return;

    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete Medication?'),
        content: const Text('This will delete the medication and its history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
               ref.read(deleteMedicationProvider)(id);
               Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
