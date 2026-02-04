import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';
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
                   ThreeDButton(
                     width: 200,
                     onPressed: () => context.go('/medications/add'),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.add, color: Colors.white),
                         SizedBox(width: 8),
                         Text('Add Medication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                       ],
                     ),
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
                   leading: GestureDetector(
                    onTap: () => _showMedicationInfo(context, med),
                    child: CircleAvatar(
                      backgroundColor: Color(med.color).withValues(alpha: 0.2),
                      child: Icon(
                        med.icon != null ? IconData(med.icon!, fontFamily: 'MaterialIcons') : Icons.medication,
                        color: Color(med.color),
                      ),
                    ),
                  ),
                  title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${med.dosage} • ${med.frequency}'),
                      if (med.stockQuantity != null)
                        Text(
                          'Stock: ${med.stockQuantity!.toInt()} units',
                          style: TextStyle(
                            fontSize: 12,
                            color: (med.refillThreshold != null && med.stockQuantity! <= med.refillThreshold!)
                                ? Colors.red : Colors.grey[600],
                            fontWeight: (med.refillThreshold != null && med.stockQuantity! <= med.refillThreshold!)
                                ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
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
        ? ThreeDButton(
            width: 60,
            height: 60,
            isFloating: true,
            onPressed: () => context.go('/medications/add'),
            child: const Icon(Icons.add, color: Colors.white, size: 30),
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
              Text('Stock: ${medication.stockQuantity!.toInt()} units', 
                style: TextStyle(
                  color: (medication.refillThreshold != null && medication.stockQuantity! <= medication.refillThreshold!) 
                    ? Colors.red : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (medication.refillThreshold != null)
                Text('Refill alert at: ${medication.refillThreshold!.toInt()} units', style: const TextStyle(fontSize: 12)),
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
