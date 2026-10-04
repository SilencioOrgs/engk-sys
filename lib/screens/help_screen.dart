import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/esenyas_app_bar.dart';

/// Help & Instructions screen with accordion sections.
///
/// Recreates HelpScreen.tsx with feature banner, expandable
/// sections for How to Use / Tips / About, and contact info.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _expanded = 'how-to-use';

  void _toggle(String id) {
    setState(() => _expanded = _expanded == id ? null : id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ESenyasAppBar(title: 'Help & Instructions'),
            Expanded(
              child: Container(
                color: ESenyasColors.surfaceBlueLight,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Features banner
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              ESenyasColors.primaryBlue,
                              ESenyasColors.accentGreen,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                              ESenyasDimens.borderRadiusMd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Key Features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 12,
                              runSpacing: 6,
                              children: [
                                'Real-time gesture detection',
                                'Two-way conversation mode',
                                'Offline capable',
                                'Filipino Sign Language focus',
                              ]
                                  .map((f) => Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.8),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            f,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.9),
                                            ),
                                          ),
                                        ],
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),

                      // Accordion sections
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _AccordionSection(
                              id: 'how-to-use',
                              title: 'How to Use e-Senyas',
                              icon: Icons.back_hand,
                              iconBg: ESenyasColors.primaryBlue,
                              expanded: _expanded == 'how-to-use',
                              onTap: () => _toggle('how-to-use'),
                              child: _HowToUseContent(),
                            ),
                            const SizedBox(height: 8),
                            _AccordionSection(
                              id: 'tips',
                              title: 'Tips for Better Recognition',
                              icon: Icons.lightbulb_outline,
                              iconBg: ESenyasColors.accentGreen,
                              expanded: _expanded == 'tips',
                              onTap: () => _toggle('tips'),
                              child: _TipsContent(),
                            ),
                            const SizedBox(height: 8),
                            _AccordionSection(
                              id: 'about',
                              title: 'About e-Senyas',
                              icon: Icons.info_outline,
                              iconBg: ESenyasColors.primaryBlue,
                              expanded: _expanded == 'about',
                              onTap: () => _toggle('about'),
                              child: _AboutContent(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                              ESenyasDimens.borderRadiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Need more help?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ESenyasColors.gray900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Contact the research team for additional support or to report issues.',
                              style: TextStyle(
                                  fontSize: 13, color: ESenyasColors.gray500),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: ESenyasColors.surfaceBlueLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '📧 esenyas@research.edu.ph',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ESenyasColors.primaryBlue,
                                ),
                              ),
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

class _AccordionSection extends StatelessWidget {
  final String id;
  final String title;
  final IconData icon;
  final Color iconBg;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _AccordionSection({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconBg,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(ESenyasDimens.borderRadiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ESenyasColors.gray900,
                      ),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: ESenyasColors.gray400,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF5F5F5)),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _HowToUseContent extends StatelessWidget {
  static const _steps = [
    'Tap "Gesture Translation" from the main menu',
    'Position your hand clearly in front of the camera',
    'Perform the Filipino Sign Language (FSL) gesture',
    'The system detects and translates the gesture to text',
    'Hearing users can type replies in the text box',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _steps
          .asMap()
          .entries
          .map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: ESenyasColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ESenyasColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _TipsContent extends StatelessWidget {
  static const _tips = [
    'Ensure your hand is fully visible to the camera',
    'Perform gestures clearly and steadily',
    'Avoid complex or cluttered backgrounds',
    'Use adequate lighting conditions',
    'Keep your hand within the camera frame at all times',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tips
          .map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 14,
                        color: ESenyasColors.accentGreen,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          fontSize: 13,
                          color: ESenyasColors.gray700,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _AboutContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'e-Senyas is an Android-based Filipino Sign Language (FSL) translation system that uses computer vision and deep learning to recognize hand gestures and convert them to text in real-time.',
          style: TextStyle(fontSize: 13, color: ESenyasColors.gray700, height: 1.6),
        ),
        const SizedBox(height: 8),
        const Text(
          'It bridges the communication gap between Deaf and Hearing individuals, promoting inclusivity and accessibility in everyday interactions.',
          style: TextStyle(fontSize: 13, color: ESenyasColors.gray700, height: 1.6),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ESenyasColors.surfaceBlueLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Version Info',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: ESenyasColors.primaryBlue,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'v1.0 Beta · Academic Prototype · 2024',
                style: TextStyle(fontSize: 12, color: ESenyasColors.gray600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
