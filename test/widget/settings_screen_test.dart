import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dose_time/features/settings/presentation/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';

void main() {
  group('SettingsScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'disclaimer_accepted': true,
        'onboarding_complete': true,
        'is_pro': false,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('should display settings screen title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('should display upgrade to pro option', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show upgrade option for non-pro users
      expect(find.textContaining('Pro'), findsWidgets);
    });

    testWidgets('should display privacy policy link', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Privacy'), findsWidgets);
    });
  });
}
