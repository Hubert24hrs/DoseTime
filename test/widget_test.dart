import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:dose_time/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App starts and shows Disclaimer', (WidgetTester tester) async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const DoseTimeApp(),
      ),
    );

    // Pump to allow router to redirect
    await tester.pumpAndSettle();

    // Verify Disclaimer Screen is shown
    expect(find.text('Medical Disclaimer'), findsOneWidget);
  });
}
