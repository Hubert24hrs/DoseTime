import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand blue used across the app (header bars, buttons, the dose wheel).
const MaterialColor brandBlue = MaterialColor(0xFF1C7ED6, <int, Color>{
  50: Color(0xFFE7F2FC),
  100: Color(0xFFC4DFF8),
  200: Color(0xFF9DCAF3),
  300: Color(0xFF74B4EE),
  400: Color(0xFF52A3EA),
  500: Color(0xFF1C7ED6),
  600: Color(0xFF1872C4),
  700: Color(0xFF1262AA),
  800: Color(0xFF0D5291),
  900: Color(0xFF073A6B),
});

class AppTheme {
  static const Color primaryColor = Color(0xFF1C7ED6);
  static const Color primaryDark = Color(0xFF0D5291); // CTA buttons
  static const Color headerColor = Color(0xFF1C8BE0); // Top header band
  static const Color secondaryColor = Color(0xFFFF6F61); // Coral accent
  static const Color successColor = Color(0xFF2EB872);
  static const Color warningColor = Color(0xFFF5A524);
  static const Color scaffoldLight = Color(0xFFF2F6FA);
  static const Color scaffoldDark = Color(0xFF0F1720);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF18222E);

  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? surfaceDark : surfaceLight;
    final onSurface = isDark ? Colors.white : const Color(0xFF1B2733);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: isDark ? scaffoldDark : scaffoldLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: brightness,
        primary: isDark ? brandBlue.shade300 : primaryColor,
        secondary: secondaryColor,
        surface: surface,
      ),
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : _textTheme,
      ).apply(bodyColor: onSurface, displayColor: onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? surfaceDark : headerColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF223040) : const Color(0xFFF5F8FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: brandBlue.withValues(alpha: isDark ? 0.3 : 0.12),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primaryColor : Colors.grey,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? primaryColor : Colors.grey);
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primaryColor : null,
        ),
      ),
    );
  }
}
