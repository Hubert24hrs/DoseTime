import 'package:flutter/material.dart';

class AppConstants {
  static const List<Color> medicationColors = [
    Colors.teal,
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
}
