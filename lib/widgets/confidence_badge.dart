import 'package:flutter/material.dart';

/// Colored confidence badge pill matching the React prototype.
///
/// Green for ≥ 90 %, yellow for ≥ 75 %, red otherwise.
class ConfidenceBadge extends StatelessWidget {
  final int value;

  const ConfidenceBadge({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (value >= 90) {
      color = const Color(0xFF3BB273);
    } else if (value >= 75) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.33), width: 1),
      ),
      child: Text(
        '$value%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
