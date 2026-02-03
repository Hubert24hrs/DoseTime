import 'package:dose_time/core/widgets/three_d_button.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DisclaimerScreen extends ConsumerWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Important')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
            const SizedBox(height: 24),
            const Text(
              'Medical Disclaimer',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'DoseTime is a tool to help you remember your medication schedule. It does NOT provide medical advice, diagnosis, or treatment.\n\nAlways consult with your healthcare provider for any questions regarding your medical condition or medications.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            ThreeDButton(
              onPressed: () async {
                await ref.read(settingsServiceProvider).setDisclaimerAccepted(true);
                if (context.mounted) {
                  context.go('/home');
                }
              },
              child: const Text('I Understand & Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
