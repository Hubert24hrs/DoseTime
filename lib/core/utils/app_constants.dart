import 'package:dose_time/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppConstants {
  /// Medications allowed on the free plan; Pro removes the limit.
  static const int freeMedicationLimit = 3;

  static const List<Color> medicationColors = [
    brandBlue,
    Color(0xFFFF6F61), // Coral
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.indigo,
  ];

  static const List<IconData> medicationIcons = [
    Icons.medication,
    Icons.vaccines, // Injection
    Icons.healing, // Bandage/Pill
    Icons.local_pharmacy,
    Icons.water_drop, // Drops
    Icons.monitor_heart,
  ];

  /// Resolves a stored icon code point to one of [medicationIcons]. Icons are
  /// looked up rather than built with IconData(codePoint) so release builds
  /// can tree-shake the icon font.
  static IconData iconFor(int? codePoint, {IconData fallback = Icons.medication}) {
    for (final icon in medicationIcons) {
      if (icon.codePoint == codePoint) return icon;
    }
    return fallback;
  }
}
