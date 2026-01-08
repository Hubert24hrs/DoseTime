import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.star, color: settings.isPro ? Colors.amber : Colors.grey),
            title: const Text('Pro Status'),
            subtitle: Text(settings.isPro ? 'Active' : 'Free Plan (Max 2 Meds)'),
            trailing: settings.isPro 
              ? null 
              : ElevatedButton(
                  onPressed: () => context.push('/upgrade'),
                  child: const Text('Upgrade'),
                ),
            onTap: !settings.isPro ? () => context.push('/upgrade') : null,
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy Policy'),
            subtitle: Text('Data stored locally'),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About DoseTime'),
            subtitle: Text('Version 1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset Disclaimer'),
            onTap: () async {
               await settings.setDisclaimerAccepted(false);
               if (context.mounted) context.go('/disclaimer');
            },
          )
        ],
      ),
    );
  }
}
