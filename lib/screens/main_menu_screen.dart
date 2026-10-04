import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';

/// Main menu / home screen with hero header and feature cards.
///
/// Recreates MainMenuScreen.tsx with custom app bar, welcome banner,
/// rounded cutout transition, and menu item cards.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;
    final headerBg =
        darkMode ? ESenyasColors.primaryBlueDark : ESenyasColors.primaryBlue;
    final bodyBg =
        darkMode ? ESenyasColors.backgroundDark : ESenyasColors.backgroundLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            _AppBar(darkMode: darkMode, headerBg: headerBg),

            // Scrollable body
            Expanded(
              child: Container(
                color: bodyBg,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero header
                      _HeroHeader(darkMode: darkMode, headerBg: headerBg),

                      // Rounded cutout
                      _RoundedCutout(headerBg: headerBg, bodyBg: bodyBg),

                      // Menu items
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'MGA PANGUNAHING TAMPOK',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.66,
                                  color: darkMode
                                      ? ESenyasColors.lightBlueText
                                      : ESenyasColors.primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _MenuCard(
                              title: 'Isalin ang Senyas',
                              description:
                                  'Tuklasin at isalin ang mga senyas ng FSL',
                              icon: Icons.camera_alt,
                              iconColor: ESenyasColors.primaryBlue,
                              darkMode: darkMode,
                              onTap: () => Navigator.of(context)
                                  .pushNamed('/gesture-translation'),
                            ),
                            const SizedBox(height: 8),
                            _MenuCard(
                              title: 'Kasaysayan ng Pagsasalin',
                              description:
                                  'Tingnan ang mga nakaraang pagsasalin',
                              icon: Icons.history,
                              iconColor: ESenyasColors.accentGreen,
                              darkMode: darkMode,
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/history'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            const ESenyasBottomNavBar(currentIndex: 0),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final bool darkMode;
  final Color headerBg;

  const _AppBar({required this.darkMode, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ESenyasDimens.appBarHeight,
      padding: const EdgeInsets.only(left: 16, right: 4),
      decoration: BoxDecoration(
        color: headerBg,
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Logo button
          GestureDetector(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.back_hand, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'e-Senyas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/settings'),
            icon: const Icon(Icons.settings, color: Colors.white, size: 22),
            tooltip: 'Mga Setting',
          ),
        ],
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final bool darkMode;
  final Color headerBg;

  const _HeroHeader({required this.darkMode, required this.headerBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: headerBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maligayang pagdating sa',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const Text(
            'e-Senyas FSL Translator',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: ESenyasColors.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Handa na ang Sistema (Na-load ang Modelo)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundedCutout extends StatelessWidget {
  final Color headerBg;
  final Color bodyBg;

  const _RoundedCutout({required this.headerBg, required this.bodyBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      color: headerBg,
      child: Container(
        decoration: BoxDecoration(
          color: bodyBg,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool darkMode;
  final VoidCallback onTap;

  const _MenuCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: darkMode ? ESenyasColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ESenyasDimens.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: ESenyasDimens.iconContainerSize,
                height: ESenyasDimens.iconContainerSize,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius:
                      BorderRadius.circular(ESenyasDimens.borderRadiusMd),
                ),
                child: Icon(icon, size: 21, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: darkMode ? Colors.white : ESenyasColors.gray900,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: darkMode
                            ? ESenyasColors.gray400
                            : ESenyasColors.gray500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: darkMode ? ESenyasColors.gray600 : ESenyasColors.gray300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
