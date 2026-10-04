import 'package:flutter/material.dart';

/// Centralized color palette extracted from the React/Vite prototype's theme.css
/// and component styles. Light and dark mode values are grouped together.
class ESenyasColors {
  ESenyasColors._();

  // ── Primary brand ──
  static const Color primaryBlue = Color(0xFF1A4D8F);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color primaryBlueHover = Color(0xFF153D73);
  static const Color primaryBlueDarkHover = Color(0xFF1976D2);

  // ── Accent / success green ──
  static const Color accentGreen = Color(0xFF3BB273);
  static const Color accentGreenHover = Color(0xFF2F9960);

  // ── Light‐mode surfaces ──
  static const Color backgroundLight = Color(0xFFF4F6F9);
  static const Color cardLight = Colors.white;
  static const Color surfaceBlueLight = Color(0xFFE6F0FA);

  // ── Dark‐mode surfaces ──
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color cardDarkHover = Color(0xFF2A2A2A);

  // ── Text on blue header ──
  static const Color lightBlueText = Color(0xFF90CAF9);

  // ── Destructive ──
  static const Color destructiveRed = Color(0xFFEF4444);

  // ── Neutral grays used throughout the prototype ──
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
}

/// Reusable dimension constants matching the React prototype.
class ESenyasDimens {
  ESenyasDimens._();

  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 60.0;
  static const double buttonHeight = 48.0;
  static const double cameraPreviewHeight = 210.0;
  static const double borderRadiusSm = 8.0;
  static const double borderRadiusMd = 12.0;
  static const double borderRadiusLg = 16.0;
  static const double borderRadiusXl = 24.0;
  static const double iconContainerSize = 42.0;
  static const double iconContainerSizeSm = 36.0;
}

/// Mock sign words used by [MockAIService] during frontend‐only development.
/// These are the exact words from the React prototype's SIGN_WORDS array.
const List<String> kMockSignWords = [
  'Kumusta', 'ka', 'Salamat', 'Magandang', 'umaga', 'tanghali', 'gabi',
  'Oo', 'Hindi', 'Paalam', 'Pwede', 'po', 'Tulong', 'Gutom', 'ako',
  'Mahal', 'kita', 'Ingat', 'Saan', 'pupunta', 'Anong', 'pangalan', 'mo',
  'Masaya', 'Pasensya', 'na', 'Walang', 'anuman', 'Kain', 'tayo', 'Masakit',
];

/// Gesture names used in Testing Mode mock data.
const List<String> kTestGestures = [
  'Kumusta ka?', 'Salamat', 'Magandang umaga', 'Oo',
  'Hindi', 'Pasensya na', 'Tulong', 'Paalam',
];
