import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dose_time/firebase_options.dart';

/// Service for Firebase Analytics and Crashlytics integration
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  FirebaseAnalytics? _analytics;
  FirebaseAnalyticsObserver? _observer;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  FirebaseAnalyticsObserver? get observer => _observer;

  /// Initialize Firebase and analytics
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);

      // Configure Crashlytics
      if (!kDebugMode) {
        FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
        
        // Catch async errors
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      // Disable analytics in debug mode
      await _analytics?.setAnalyticsCollectionEnabled(!kDebugMode);

      _isInitialized = true;
      debugPrint('AnalyticsService: Initialized successfully');
    } catch (e) {
      debugPrint('AnalyticsService: Failed to initialize - $e');
    }
  }

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_isInitialized || _analytics == null) return;
    
    await _analytics!.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  /// Log medication added
  Future<void> logMedicationAdded({
    required String frequency,
    required int reminderCount,
  }) async {
    await logEvent(
      name: 'medication_added',
      parameters: {
        'frequency': frequency,
        'reminder_count': reminderCount,
      },
    );
  }

  /// Log medication taken
  Future<void> logMedicationTaken({
    required bool onTime,
  }) async {
    await logEvent(
      name: 'medication_taken',
      parameters: {
        'on_time': onTime,
      },
    );
  }

  /// Log medication skipped
  Future<void> logMedicationSkipped() async {
    await logEvent(name: 'medication_skipped');
  }

  /// Log medication deleted
  Future<void> logMedicationDeleted() async {
    await logEvent(name: 'medication_deleted');
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    await _analytics!.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Log adherence rate
  Future<void> logAdherenceRate({
    required double rate,
    required int period,
  }) async {
    await logEvent(
      name: 'adherence_rate',
      parameters: {
        'rate': rate,
        'period_days': period,
      },
    );
  }

  /// Set user properties
  Future<void> setUserProperties({
    required bool isPro,
    required int medicationCount,
  }) async {
    if (!_isInitialized || _analytics == null) return;

    await _analytics!.setUserProperty(
      name: 'is_pro',
      value: isPro.toString(),
    );
    await _analytics!.setUserProperty(
      name: 'medication_count',
      value: medicationCount.toString(),
    );
  }

  /// Log error to Crashlytics
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('Stack: $stackTrace');
      return;
    }

    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Add custom log message to Crashlytics
  Future<void> log(String message) async {
    if (!_isInitialized) return;
    
    if (kDebugMode) {
      debugPrint('Crashlytics log: $message');
      return;
    }

    await FirebaseCrashlytics.instance.log(message);
  }
}

// Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
