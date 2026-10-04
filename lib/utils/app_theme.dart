import 'package:flutter/material.dart';
import 'constants.dart';

/// Builds the light and dark [ThemeData] used by the application.
/// Colors are derived from the React/Vite prototype's theme.css.
class AppTheme {
  AppTheme._();

  // ── Light Theme ──
  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        primaryColor: ESenyasColors.primaryBlue,
        scaffoldBackgroundColor: ESenyasColors.backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: ESenyasColors.primaryBlue,
          secondary: ESenyasColors.accentGreen,
          surface: ESenyasColors.cardLight,
          error: ESenyasColors.destructiveRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ESenyasColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        fontFamily: null, // Use platform default sans-serif
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.66,
          ),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
        ),
      );

  // ── Dark Theme ──
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        primaryColor: ESenyasColors.primaryBlueDark,
        scaffoldBackgroundColor: ESenyasColors.backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: ESenyasColors.primaryBlueDark,
          secondary: ESenyasColors.accentGreen,
          surface: ESenyasColors.cardDark,
          error: ESenyasColors.destructiveRed,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: ESenyasColors.primaryBlueDark,
          foregroundColor: Colors.white,
          elevation: 2,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        fontFamily: null,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.66,
          ),
          labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.normal),
        ),
      );
}
