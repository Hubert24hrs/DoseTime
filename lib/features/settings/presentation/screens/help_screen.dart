import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & FAQ'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            title: 'Getting Started',
            children: [
              _buildFAQItem(
                question: 'How do I add a medication?',
                answer: 'Tap the + button on the home screen. Enter the medication name, dosage, and set your reminder times. Tap Save to add it to your list.',
              ),
              _buildFAQItem(
                question: 'How do I edit or delete a medication?',
                answer: 'Long-press on any medication card, or tap on it to view details. From there you can edit or delete the medication.',
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Notifications',
            children: [
              _buildFAQItem(
                question: 'Why am I not receiving reminders?',
                answer: 'Make sure notifications are enabled in your device settings. Go to Settings > Apps > DoseTime > Notifications and enable them. Also check that battery optimization is disabled for the app.',
              ),
              _buildFAQItem(
                question: 'How do I change reminder times?',
                answer: 'Tap on the medication you want to change, then tap Edit. Adjust the reminder times and save your changes.',
              ),
              _buildFAQItem(
                question: 'Do reminders work when my phone is off?',
                answer: 'No, reminders require your phone to be on. However, DoseTime will reschedule all reminders when your phone restarts.',
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Data & Privacy',
            children: [
              _buildFAQItem(
                question: 'Is my data backed up?',
                answer: 'All your data is stored locally on your device only. We do not have access to your medication information. Consider using the Export feature to back up your data.',
              ),
              _buildFAQItem(
                question: 'How do I export my data?',
                answer: 'Go to Settings > Export Data. You can export as JSON or CSV format and share it to any app.',
              ),
              _buildFAQItem(
                question: 'How do I delete all my data?',
                answer: 'Go to Settings > Delete All Data. This will permanently remove all medications and logs. You can also uninstall the app to delete all data.',
              ),
            ],
          ),
          const Divider(height: 32),
          _buildSection(
            title: 'Pro Features',
            children: [
              _buildFAQItem(
                question: 'What do I get with DoseTime Pro?',
                answer: 'Pro includes unlimited medications (free is limited to 3), adherence insights with charts, PDF report export, and priority support.',
              ),
              _buildFAQItem(
                question: 'How do I restore my purchase?',
                answer: 'Go to Settings > Restore Purchase. Make sure you\'re signed into the same Google account used for the original purchase.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 48, color: Colors.teal),
                  const SizedBox(height: 12),
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact us and we\'ll get back to you as soon as possible.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _launchEmail(),
                    icon: const Icon(Icons.email),
                    label: const Text('Email Support'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ),
      ],
    );
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@hubert.dev?subject=DoseTime%20Help');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
