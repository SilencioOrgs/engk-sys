import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';

/// Privacy Policy screen.
///
/// Recreates PrivacyPolicyScreen.tsx with header card,
/// privacy statement, key points, and contact information.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dm = context.watch<AppProvider>().darkMode;
    final bodyBg =
        dm ? ESenyasColors.backgroundDark : ESenyasColors.surfaceBlueLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'Privacy Policy'),
            Expanded(
              child: Container(
                color: bodyBg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      _Card(
                        darkMode: dm,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: ESenyasColors.accentGreen,
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd),
                              ),
                              child: const Icon(Icons.shield,
                                  size: 24, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Privacy Matters',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: dm ? Colors.white : ESenyasColors.gray900,
                                    ),
                                  ),
                                  Text(
                                    'Last updated: March 2024',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: dm
                                          ? ESenyasColors.gray400
                                          : ESenyasColors.gray500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Statement
                      _Card(
                        darkMode: dm,
                        child: Text(
                          'e-Senyas processes gesture data locally and does not store or transmit personal data. This system is developed for academic research purposes.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.8,
                            color: dm
                                ? const Color(0xFFD1D5DB)
                                : ESenyasColors.gray700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Key points
                      _Card(
                        darkMode: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Key Privacy Points',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...[
                              'All processing is done locally on your device',
                              'No personal data is stored or transmitted',
                              'Gesture data is processed in real-time only',
                              'No third-party data sharing',
                              'Academic research purposes only',
                            ].map((point) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: ESenyasColors.accentGreen,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: dm
                                                ? const Color(0xFFD1D5DB)
                                                : ESenyasColors.gray700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact
                      _Card(
                        darkMode: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Questions?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'If you have any questions about our privacy practices, please contact:',
                              style: TextStyle(
                                fontSize: 13,
                                color: dm
                                    ? ESenyasColors.gray400
                                    : ESenyasColors.gray500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: dm
                                    ? ESenyasColors.primaryBlueDark
                                        .withValues(alpha: 0.2)
                                    : ESenyasColors.surfaceBlueLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '📧 esenyas@research.edu.ph',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dm
                                      ? ESenyasColors.lightBlueText
                                      : ESenyasColors.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const ESenyasBottomNavBar(currentIndex: 3),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final bool darkMode;
  final Widget child;

  const _Card({required this.darkMode, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkMode ? ESenyasColors.cardDark : Colors.white,
        borderRadius:
            BorderRadius.circular(ESenyasDimens.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      child: child,
    );
  }
}
