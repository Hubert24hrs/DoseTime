import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
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
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Data stored locally'),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About DoseAlert'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => _showAboutDialog(context),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ThreeDButton(
              color: Colors.red.shade400,
              onPressed: () async {
                 await settings.setDisclaimerAccepted(false);
                 if (context.mounted) context.go('/disclaimer');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_forever, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Reset Disclaimer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text(
          'Your privacy is our priority. All your medication data is stored locally on your device and is never uploaded to any external server. We do not track or collect any personal information.',
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About DoseAlert'),
        content: const Text(
          'DoseAlert is your reliable companion for medication management. Designed to help you stay on track with your health, it provides timely reminders and a simple interface to track your doses.',
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
