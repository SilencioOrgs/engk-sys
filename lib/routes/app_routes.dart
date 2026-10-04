import 'package:flutter/material.dart';
import '../screens/launch_screen.dart';
import '../screens/main_menu_screen.dart';
import '../screens/gesture_translation_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/app_info_screen.dart';
import '../screens/gesture_guide_screen.dart';
import '../screens/testing_mode_screen.dart';
import '../screens/help_screen.dart';

/// Named route definitions matching the React router paths.
class AppRoutes {
  AppRoutes._();

  static const String launch = '/';
  static const String menu = '/menu';
  static const String gestureTranslation = '/gesture-translation';
  static const String history = '/history';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String appInfo = '/app-info';
  static const String gestureGuide = '/gesture-guide';
  static const String testingMode = '/testing-mode';
  static const String help = '/help';

  static Map<String, WidgetBuilder> get routes => {
        launch: (_) => const LaunchScreen(),
        menu: (_) => const MainMenuScreen(),
        gestureTranslation: (_) => const GestureTranslationScreen(),
        history: (_) => const HistoryScreen(),
        settings: (_) => const SettingsScreen(),
        privacyPolicy: (_) => const PrivacyPolicyScreen(),
        appInfo: (_) => const AppInfoScreen(),
        gestureGuide: (_) => const GestureGuideScreen(),
        testingMode: (_) => const TestingModeScreen(),
        help: (_) => const HelpScreen(),
      };
}
