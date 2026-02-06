import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';

void main() {
  group('SettingsService', () {
    late SettingsService settingsService;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsService = SettingsService(prefs);
    });

    group('Disclaimer', () {
      test('should return false by default', () {
        expect(settingsService.disclaimerAccepted, false);
      });

      test('should return true after accepting', () async {
        await settingsService.setDisclaimerAccepted(true);
        expect(settingsService.disclaimerAccepted, true);
      });

      test('should return false after resetting', () async {
        await settingsService.setDisclaimerAccepted(true);
        await settingsService.setDisclaimerAccepted(false);
        expect(settingsService.disclaimerAccepted, false);
      });
    });

    group('Pro Status', () {
      test('should return false by default', () {
        expect(settingsService.isPro, false);
      });

      test('should return true after upgrading', () async {
        await settingsService.setIsPro(true);
        expect(settingsService.isPro, true);
      });
    });

    group('Onboarding', () {
      test('should return false by default', () {
        expect(settingsService.onboardingComplete, false);
      });

      test('should return true after completing', () async {
        await settingsService.setOnboardingComplete(true);
        expect(settingsService.onboardingComplete, true);
      });
    });
  });
}
