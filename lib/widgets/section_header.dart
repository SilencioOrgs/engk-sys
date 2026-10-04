import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

/// Uppercase section header label used across many screens.
///
/// Matches the React prototype's blue uppercase text with letter spacing.
class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionHeader({super.key, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    final darkMode = context.watch<AppProvider>().darkMode;
    final color =
        darkMode ? ESenyasColors.lightBlueText : ESenyasColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.66,
              color: color,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
