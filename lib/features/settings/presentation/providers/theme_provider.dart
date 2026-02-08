import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/settings_service.dart';

/// NotifierProvider for theme mode that persists changes to SharedPreferences
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final settings = ref.watch(settingsServiceProvider);
    return settings.themeMode;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setThemeMode(mode);
    state = mode;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
