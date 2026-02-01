import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  final SharedPreferences prefs;

  SettingsService(this.prefs);

  static const _keyDisclaimer = 'disclaimer_accepted';
  static const _keyPro = 'is_pro';
  static const _keyOnboarding = 'onboarding_complete';

  bool get disclaimerAccepted => prefs.getBool(_keyDisclaimer) ?? false;
  Future<void> setDisclaimerAccepted(bool value) async {
    await prefs.setBool(_keyDisclaimer, value);
  }

  bool get isPro => prefs.getBool(_keyPro) ?? false;
  Future<void> setPro(bool value) async {
    await prefs.setBool(_keyPro, value);
  }

  bool get onboardingComplete => prefs.getBool(_keyOnboarding) ?? false;
  Future<void> setOnboardingComplete(bool value) async {
    await prefs.setBool(_keyOnboarding, value);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Initialized in main
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});
