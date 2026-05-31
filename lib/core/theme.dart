import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0D0D0D);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceVariant = Color(0xFF16213E);
  static const Color primary = Color(0xFF0F3460);
  static const Color accent = Color(0xFFE94560);
  static const Color onBackground = Color(0xFFE0E0E0);
  static const Color onSurface = Color(0xFFB0B0B0);
  static const Color epgNow = Color(0xFF1B5E20);
  static const Color epgPast = Color(0xFF212121);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          background: background,
          surface: surface,
          primary: accent,
          onPrimary: Colors.white,
          onBackground: onBackground,
          onSurface: onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: onBackground,
          elevation: 0,
        ),
        navigationRailTheme: const NavigationRailThemeData(
          backgroundColor: surfaceVariant,
          selectedIconTheme: IconThemeData(color: accent),
          unselectedIconTheme: IconThemeData(color: onSurface),
          selectedLabelTextStyle: TextStyle(color: accent),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: onSurface),
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        useMaterial3: true,
      );
}
