import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Plays the looping dose beep while the alarm screen is open.
/// Backed by a MediaPlayer on the Android alarm stream (see MainActivity.kt).
class AlarmSound {
  AlarmSound._();

  static const MethodChannel _channel = MethodChannel('dosetime/alarm');
  static Timer? _vibrateTimer;

  static Future<void> start() async {
    if (kIsWeb || !Platform.isAndroid) {
      _startVibration();
      return;
    }
    try {
      await _channel.invokeMethod('clearShownAlarms');
      await _channel.invokeMethod('startBeep');
    } catch (e) {
      debugPrint('AlarmSound: failed to start beep: $e');
    }
    _startVibration();
  }

  static Future<void> stop() async {
    _vibrateTimer?.cancel();
    _vibrateTimer = null;
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('stopBeep');
    } catch (e) {
      debugPrint('AlarmSound: failed to stop beep: $e');
    }
  }

  static void _startVibration() {
    _vibrateTimer?.cancel();
    HapticFeedback.vibrate();
    _vibrateTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      HapticFeedback.vibrate();
    });
  }
}
