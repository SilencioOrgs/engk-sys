import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Launch / splash screen — the first screen users see.
///
/// Recreates LaunchScreen.tsx: gradient background, logo, app name,
/// tagline, version badge, and two action buttons.
class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;

    final gradientColors = darkMode
        ? [ESenyasColors.primaryBlueDark.withValues(alpha: 0.2), ESenyasColors.backgroundDark]
        : [ESenyasColors.surfaceBlueLight, Colors.white];

    final titleColor =
        darkMode ? ESenyasColors.lightBlueText : ESenyasColors.primaryBlue;
    final taglineColor =
        darkMode ? const Color(0xFF9CA3AF) : ESenyasColors.gray500;
    final footerColor =
        darkMode ? const Color(0xFF4B5563) : const Color(0xFF9CA3AF);
    final logoBg =
        darkMode ? ESenyasColors.primaryBlueDark : ESenyasColors.primaryBlue;
    final badgeBg = darkMode
        ? ESenyasColors.primaryBlueDark.withValues(alpha: 0.2)
        : ESenyasColors.surfaceBlueLight;
    final badgeText =
        darkMode ? ESenyasColors.lightBlueText : ESenyasColors.primaryBlue;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: logoBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.back_hand,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  'e-Senyas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Filipino Sign Language Translator',
                  style: TextStyle(fontSize: 14, color: taglineColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Version badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'v1.0 Beta · Academic Prototype',
                    style: TextStyle(fontSize: 11, color: badgeText),
                  ),
                ),
                const SizedBox(height: 40),

                // Start Translation button
                SizedBox(
                  width: double.infinity,
                  height: ESenyasDimens.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/menu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkMode
                          ? ESenyasColors.primaryBlueDark
                          : ESenyasColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ESenyasDimens.borderRadiusMd),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Start Translation'),
                  ),
                ),
                const SizedBox(height: 12),

                // Tungkol sa App button
                SizedBox(
                  width: double.infinity,
                  height: ESenyasDimens.buttonHeight,
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/app-info'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: darkMode
                          ? ESenyasColors.lightBlueText
                          : ESenyasColors.primaryBlue,
                      backgroundColor: darkMode
                          ? ESenyasColors.cardDark
                          : Colors.white,
                      side: BorderSide(
                        color: darkMode
                            ? ESenyasColors.primaryBlueDark
                            : ESenyasColors.primaryBlue,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(ESenyasDimens.borderRadiusMd),
                      ),
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Tungkol sa App'),
                  ),
                ),

                const Spacer(),

                // Footer
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Developed for academic research purposes',
                    style: TextStyle(fontSize: 11, color: footerColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
