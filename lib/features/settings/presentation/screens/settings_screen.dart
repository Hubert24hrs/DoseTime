import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:dose_time/core/services/data_export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsServiceProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Pro Status
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
          
          // Appearance Section
          _buildSectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(settings.themeMode)),
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
              ],
              onChanged: (mode) async {
                if (mode != null) {
                  await settings.setThemeMode(mode);
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(),
          
          // Notification Settings Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.do_not_disturb_on_outlined),
            title: const Text('Quiet Hours'),
            subtitle: Text(settings.quietHoursEnabled 
                ? '${settings.quietHoursStart.format(context)} - ${settings.quietHoursEnd.format(context)}'
                : 'Disabled'),
            value: settings.quietHoursEnabled,
            onChanged: (value) async {
              await settings.setQuietHoursEnabled(value);
              setState(() {});
            },
          ),
          if (settings.quietHoursEnabled) ...[
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('Start Time'),
              trailing: TextButton(
                child: Text(settings.quietHoursStart.format(context)),
                onPressed: () => _pickTime(settings.quietHoursStart, (t) async {
                  await settings.setQuietHoursStart(t);
                  setState(() {});
                }),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              title: const Text('End Time'),
              trailing: TextButton(
                child: Text(settings.quietHoursEnd.format(context)),
                onPressed: () => _pickTime(settings.quietHoursEnd, (t) async {
                  await settings.setQuietHoursEnd(t);
                  setState(() {});
                }),
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.snooze_outlined),
            title: const Text('Default Snooze'),
            subtitle: Text('${settings.defaultSnoozeDuration} minutes'),
            trailing: DropdownButton<int>(
              value: settings.defaultSnoozeDuration,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 min')),
                DropdownMenuItem(value: 10, child: Text('10 min')),
                DropdownMenuItem(value: 15, child: Text('15 min')),
                DropdownMenuItem(value: 30, child: Text('30 min')),
                DropdownMenuItem(value: 60, child: Text('60 min')),
              ],
              onChanged: (val) async {
                if (val != null) {
                  await settings.setDefaultSnoozeDuration(val);
                  setState(() {});
                }
              },
            ),
          ),
          const Divider(),
          
          // About
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('Data stored locally'),
            onTap: () => _showPrivacyPolicy(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About DoseAlert'),
            subtitle: const Text('Version 1.1.0'),
            onTap: () => _showAboutDialog(context),
          ),
          const Divider(),
          const Divider(),
          
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Contacts'),
            subtitle: const Text('Doctors & Pharmacies'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.go('/settings/contacts'),
          ),
          const Divider(),

          _buildSystemInfoSection(context),
          const Divider(),
          _buildDataManagementSection(context, ref),
          const Divider(),
          _buildSupportSection(context),
          const Divider(),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System default';
    }
  }

  Future<void> _pickTime(TimeOfDay initial, Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      await onPicked(picked);
    }
  }

  Widget _buildSystemInfoSection(BuildContext context) {
    final ns = NotificationService();
    final now = DateTime.now();
    final timeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Info',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(context, 'Device Time', timeFormat.format(now)),
          _buildInfoRow(
            context,
            'Timezone',
            ns.detectedTimezone,
            subtitle: ns.isUtcFallback ? 'Fallback active (UTC)' : 'Detected correctly',
            subtitleColor: ns.isUtcFallback ? Colors.orange : Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(color: Colors.grey[700])),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor ?? Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context, WidgetRef ref) {
    final exportService = ref.read(dataExportServiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Management',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            context,
            'Advanced Data Management',
            'Export database, resetting app, etc.',
            Icons.storage_rounded,
            () => context.go('/settings/data'),
          ),
          _buildActionRow(
            context,
            'Danger Zone',
            'Cannot be undone',
            Icons.delete_sweep_outlined,
            () => _confirmDeleteAll(context, exportService),
            color: Colors.red[700],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support & Feedback',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _buildActionRow(
            context,
            'Rate DoseAlert',
            'Help us improve!',
            Icons.star_outline,
            () => _launchStore(context),
          ),
          _buildActionRow(
            context,
            'Share with others',
            'Help others manage health',
            Icons.share_outlined,
            () => Share.share('Manage your medications better with DoseAlert! Download it on Play Store.'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? color,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      onTap: onTap,
    );
  }

  void _confirmDeleteAll(BuildContext context, DataExportService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text('This will permanently delete all your medications and history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await service.deleteAllData();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchStore(BuildContext context) async {
    const url = 'https://play.google.com/store/apps/details?id=com.hubert.dosetime';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open store link')),
        );
      }
    }
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
