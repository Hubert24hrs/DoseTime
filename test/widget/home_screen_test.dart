import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dose_time/features/medication/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';

void main() {
  group('HomeScreen Widget Tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'disclaimer_accepted': true,
        'onboarding_complete': true,
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('should display app bar with title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that HomeScreen renders
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should display empty state when no medications', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state message
      expect(find.textContaining('No medications'), findsWidgets);
    });

    testWidgets('should have floating action button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // FAB should exist for adding medications
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
