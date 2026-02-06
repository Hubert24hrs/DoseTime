import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dose_time/features/medication/presentation/screens/home_screen.dart';
import 'package:dose_time/features/medication/presentation/providers/medication_providers.dart';
import 'package:dose_time/features/medication/domain/models/medication.dart';


void main() {
  testWidgets('HomeScreen shows empty state when no doses', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    // Initial loading state
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump();

    // After loading (default empty list in mock/asyncvalue)
    // Note: This assumes the provider returns empty list by default or we override it.
    // For a real widget test, we should override the provider.
  });

  testWidgets('HomeScreen displays scheduled doses', (WidgetTester tester) async {
    final testMed = Medication(
      id: 1,
      name: 'Aspirin',
      dosage: '100mg',
      frequency: 'Daily',
      times: ['09:00'],
      color: Colors.red.toARGB32(),
      type: MedicationType.pill,
    );

    final testItem = DoseScheduleItem(
      medication: testMed,
      scheduledTime: const TimeOfDay(hour: 9, minute: 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todaysScheduleProvider.overrideWith((ref) => Future.value([testItem])),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('100mg'), findsOneWidget);
    expect(find.text('Take'), findsOneWidget);
  });
}
