import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';

/// App Information screen.
///
/// Recreates AppInfoScreen.tsx with about header, description,
/// model info, features, technology, academic notice, and licenses.
class AppInfoScreen extends StatelessWidget {
  const AppInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dm = context.watch<AppProvider>().darkMode;
    final bodyBg =
        dm ? ESenyasColors.backgroundDark : ESenyasColors.surfaceBlueLight;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'App Information'),
            Expanded(
              child: Container(
                color: bodyBg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Header
                      _Card(
                        dm: dm,
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: dm
                                    ? ESenyasColors.primaryBlueDark
                                    : ESenyasColors.primaryBlue,
                                borderRadius: BorderRadius.circular(
                                    ESenyasDimens.borderRadiusMd),
                              ),
                              child: const Icon(Icons.info_outline,
                                  size: 24, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'About e-Senyas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: dm
                                          ? Colors.white
                                          : ESenyasColors.gray900,
                                    ),
                                  ),
                                  Text(
                                    'v1.0 Beta · Build 2024.001',
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

                      // Description
                      _Card(
                        dm: dm,
                        child: Text(
                          'e-Senyas is an Android-based Filipino Sign Language translation system that uses deep learning and computer vision to recognize gestures and translate them into text.',
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

                      // Model info
                      _Card(
                        dm: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Model Information',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(label: 'Model Used:', value: 'CNN-LSTM', dm: dm),
                            const SizedBox(height: 8),
                            _InfoRow(label: 'Framework:', value: 'TensorFlow Lite', dm: dm),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Features
                      _Card(
                        dm: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Key Features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.back_hand,
                              label: 'Real-time gesture detection',
                              color: ESenyasColors.accentGreen,
                              dm: dm,
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.memory,
                              label: 'Deep learning recognition',
                              color: ESenyasColors.primaryBlue,
                              dm: dm,
                            ),
                            const SizedBox(height: 12),
                            _FeatureItem(
                              icon: Icons.people_outline,
                              label: 'Two-way communication',
                              color: ESenyasColors.accentGreen,
                              dm: dm,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Technology
                      _Card(
                        dm: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Technology Stack',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...[
                              'Computer Vision',
                              'Deep Learning / Neural Networks',
                              'Real-time Processing',
                              'Filipino Sign Language (FSL)',
                              'Android Platform',
                            ].map((tech) => Padding(
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
                                            color: ESenyasColors.primaryBlue,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        tech,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: dm
                                              ? const Color(0xFFD1D5DB)
                                              : ESenyasColors.gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Academic notice
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: dm
                              ? ESenyasColors.primaryBlueDark
                                  .withValues(alpha: 0.2)
                              : ESenyasColors.surfaceBlueLight,
                          borderRadius: BorderRadius.circular(
                              ESenyasDimens.borderRadiusMd),
                          border: Border.all(
                            color: dm
                                ? ESenyasColors.primaryBlueDark
                                    .withValues(alpha: 0.3)
                                : ESenyasColors.primaryBlue
                                    .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Academic Research',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: dm
                                    ? ESenyasColors.lightBlueText
                                    : ESenyasColors.primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This application is developed for academic research purposes to advance Filipino Sign Language technology and promote accessibility.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: dm
                                    ? const Color(0xFFD1D5DB)
                                    : ESenyasColors.gray700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Licenses
                      _Card(
                        dm: dm,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Source Licenses',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: dm ? Colors.white : ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'This application uses various open-source libraries and frameworks. View full license information in the documentation.',
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
  final bool dm;
  final Widget child;

  const _Card({required this.dm, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dm ? ESenyasColors.cardDark : Colors.white,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool dm;

  const _InfoRow({required this.label, required this.value, required this.dm});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: dm ? ESenyasColors.gray400 : ESenyasColors.gray600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: dm ? ESenyasColors.lightBlueText : ESenyasColors.primaryBlue,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dm;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.dm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: dm ? const Color(0xFFD1D5DB) : ESenyasColors.gray700,
          ),
        ),
      ],
    );
  }
}
