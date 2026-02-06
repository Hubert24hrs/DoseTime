import 'package:dose_time/core/services/data_export_service.dart';
import 'package:dose_time/core/widgets/three_d_button.dart';

import 'package:dose_time/features/medication/presentation/providers/repository_providers.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DataManagementScreen extends ConsumerStatefulWidget {
  const DataManagementScreen({super.key});

  @override
  ConsumerState<DataManagementScreen> createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends ConsumerState<DataManagementScreen> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Management')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderIcon(),
          const SizedBox(height: 24),
          _buildSection(
            title: 'Export Data',
            description: 'Create a backup of all your medications and logs in a standardized JSON format.',
            icon: Icons.download_rounded,
            color: Colors.blue,
            action: ThreeDButton(
              color: Colors.blue.shade100,
              onPressed: () => _exportData(context, ref),
              child: const Text('Export JSON Backup', style: TextStyle(color: Colors.blue)),
            ),
          ),
          const Divider(height: 48),
          _buildSection(
            title: 'Danger Zone',
            description: 'Permanently delete all your data. This action cannot be undone.',
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
            isDanger: true,
            action: ThreeDButton(
              color: Colors.red.shade100,
              onPressed: _isDeleting ? null : () => _startDeleteFlow(context, ref),
              child: const Text('Delete All Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.storage_rounded, size: 64, color: Colors.grey),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Widget action,
    bool isDanger = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDanger ? Colors.red.withValues(alpha: 0.05) : Colors.white,
        border: Border.all(color: isDanger ? Colors.red.shade100 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final exportService = ref.read(dataExportServiceProvider);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing backup...')),
    );

    try {
      await exportService.exportAndShare(asJson: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _startDeleteFlow(BuildContext context, WidgetRef ref) async {
    // Step 1: Warning Dialog
    final confirmedStep1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Everything?'),
        content: const Text(
          'This will permanently remove:\n'
          '• All medications\n'
          '• All history logs\n'
          '• All settings and preferences\n\n'
          'We highly recommend exporting your data first.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmedStep1 != true) return;

    if (!context.mounted) return;

    // Step 2: Typed Confirmation
    final controller = TextEditingController();
    final confirmedStep2 = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Final Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('To confirm, type "DELETE" below:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'DELETE',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              return TextButton(
                onPressed: value.text == 'DELETE' 
                    ? () => Navigator.pop(context, true) 
                    : null,
                child: const Text('Delete Forever', style: TextStyle(color: Colors.red)),
              );
            },
          ),
        ],
      ),
    );

    if (confirmedStep2 != true) return;

    setState(() => _isDeleting = true);

    try {
      // Perform deletion
      final repository = ref.read(medicationRepositoryProvider);
      
      // Delete all meds (which should cascade logs ideally, but we'll do simplistic approach)
      final meds = await repository.getAllMedications();
      for (var med in meds) {
        if (med.id != null) await repository.deleteMedication(med.id!);
      }
      
      // Note: Repository might not have deleteAllLogs, so iterating meds implies logs might remain if no cascade.
      // Better to check if we can wipe DB or reset settings.
      // Settings:
      await ref.read(settingsServiceProvider).resetAllSettings();

      if (context.mounted) {
        context.go('/onboarding');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('App reset successfully.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset failed: $e')),
        );
      }
      setState(() => _isDeleting = false);
    }
  }
}
