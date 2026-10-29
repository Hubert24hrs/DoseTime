import 'package:dose_time/features/reminders/services/alarm_sound.dart';
import 'package:dose_time/features/reminders/services/alarm_tones.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Runs on a real Android device/emulator. Fires a dose alarm notification and
/// then the in-app alarm sound; .github/scripts/verify_beep.sh watches Android's
/// notification and audio state from the outside to confirm both beep.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dose alarm beeps', (tester) async {
    await tester.runAsync(() async {
      final ns = NotificationService();
      try {
        // initialize() may wait on permission dialogs; the script grants
        // permissions over adb, so don't block on them.
        await ns.initialize().timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('BEEPTEST: initialize did not finish ($e), creating channel directly');
      }
      await ns.setAlarmTone(defaultAlarmToneId);

      await ns.scheduleTestAlarm(delay: const Duration(seconds: 10));
      debugPrint('BEEPTEST: notification alarm scheduled for +10s');
      await Future<void>.delayed(const Duration(seconds: 40));

      debugPrint('BEEPTEST: starting in-app alarm sound');
      await AlarmSound.start(sound: defaultAlarmToneId);
      await Future<void>.delayed(const Duration(seconds: 30));
      await AlarmSound.stop();
      debugPrint('BEEPTEST: done');
    });
  });
}
