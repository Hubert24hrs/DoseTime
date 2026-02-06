import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not overridden');
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsService(prefs);
});

class SettingsService {
  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Core settings
  bool get disclaimerAccepted => _prefs.getBool('disclaimer_accepted') ?? false;
  Future<void> setDisclaimerAccepted(bool value) => _prefs.setBool('disclaimer_accepted', value);

  bool get isPro => _prefs.getBool('is_pro') ?? false;
  Future<void> setIsPro(bool value) => _prefs.setBool('is_pro', value);

  bool get onboardingComplete => _prefs.getBool('onboarding_complete') ?? false;
  Future<void> setOnboardingComplete(bool value) => _prefs.setBool('onboarding_complete', value);

  // Theme settings
  ThemeMode get themeMode {
    final value = _prefs.getString('theme_mode') ?? 'system';
    switch (value) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }
  Future<void> setThemeMode(ThemeMode mode) => _prefs.setString('theme_mode', mode.name);

  // Notification settings
  int get defaultSnoozeDuration => _prefs.getInt('snooze_duration') ?? 5; // minutes
  Future<void> setDefaultSnoozeDuration(int minutes) => _prefs.setInt('snooze_duration', minutes);

  bool get quietHoursEnabled => _prefs.getBool('quiet_hours_enabled') ?? false;
  Future<void> setQuietHoursEnabled(bool value) => _prefs.setBool('quiet_hours_enabled', value);

  TimeOfDay get quietHoursStart {
    final hour = _prefs.getInt('quiet_hours_start_hour') ?? 22;
    final minute = _prefs.getInt('quiet_hours_start_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  Future<void> setQuietHoursStart(TimeOfDay time) async {
    await _prefs.setInt('quiet_hours_start_hour', time.hour);
    await _prefs.setInt('quiet_hours_start_minute', time.minute);
  }

  TimeOfDay get quietHoursEnd {
    final hour = _prefs.getInt('quiet_hours_end_hour') ?? 7;
    final minute = _prefs.getInt('quiet_hours_end_minute') ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
  Future<void> setQuietHoursEnd(TimeOfDay time) async {
    await _prefs.setInt('quiet_hours_end_hour', time.hour);
    await _prefs.setInt('quiet_hours_end_minute', time.minute);
  }

  /// Check if current time is within quiet hours
  bool isInQuietHours() {
    if (!quietHoursEnabled) return false;
    
    final now = TimeOfDay.now();
    final start = quietHoursStart;
    final end = quietHoursEnd;
    
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      // Same day (e.g., 9:00 - 17:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight (e.g., 22:00 - 7:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  // Reset all settings
  Future<void> resetAllSettings() async {
    await _prefs.clear();
  }
}
