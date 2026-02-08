import 'package:dose_time/core/router/app_router.dart';
import 'package:dose_time/core/services/analytics_service.dart';
import 'package:dose_time/core/services/purchase_service.dart';
import 'package:dose_time/core/services/secure_storage_service.dart';
import 'package:dose_time/core/theme/app_theme.dart';
import 'package:dose_time/features/reminders/services/notification_service.dart';
import 'package:dose_time/features/settings/services/settings_service.dart';
import 'package:dose_time/features/settings/presentation/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences first as it's critical for UI state
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Critical: Failed to initialize SharedPreferences: $e');
  }

  // Initialize other services (don't let them block prefs setup)
  try {
    await _initializeServices();
  } catch (e, stack) {
    debugPrint('Failed to initialize background services: $e');
    debugPrint(stack.toString());
  }
  
  runApp(ProviderScope(
    overrides: [
      if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const DoseAlertApp(),
  ));
}

/// Initialize all core services
Future<void> _initializeServices() async {
  // Initialize Firebase Analytics & Crashlytics
  await AnalyticsService().initialize();
  
  // Initialize notifications
  await NotificationService().initialize();
  
  // Initialize secure storage
  await SecureStorageService().initialize();
  
  // Initialize in-app purchases
  await PurchaseService().initialize();
}

class DoseAlertApp extends ConsumerWidget {
  const DoseAlertApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DoseAlert',
      debugShowCheckedModeBanner: false,
      
      // Theme - now reactive to user settings
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Router
      routerConfig: router,
      
      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('es'), // Spanish
      ],
      
      // Analytics observer
      builder: (context, child) {
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    Text(
                      'Oops! Something went wrong.',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      details.exception.toString(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        };
        return child ?? const SizedBox();
      },
    );
  }
}
