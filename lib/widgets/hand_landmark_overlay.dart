import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../utils/live_landmark_transform.dart';

/// Paints the exact MediaPipe landmarks received by the app.
///
/// MediaPipe x/y landmarks are normalized to 0..1. [mirrorX] is display-only
/// and never changes the coordinates sent to the classifier.
class HandLandmarkOverlay extends StatelessWidget {
  final List<Hand> hands;
  final bool mirrorX;
  final int rotationDegrees;

  const HandLandmarkOverlay({
    super.key,
    required this.hands,
    required this.mirrorX,
    required this.rotationDegrees,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HandLandmarkPainter(
          hands: hands,
          mirrorX: mirrorX,
          rotationDegrees: rotationDegrees,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _HandLandmarkPainter extends CustomPainter {
  static const _connections = <(int, int)>[
    (0, 1), (1, 2), (2, 3), (3, 4),
    (0, 5), (5, 6), (6, 7), (7, 8),
    (5, 9), (9, 10), (10, 11), (11, 12),
    (9, 13), (13, 14), (14, 15), (15, 16),
    (13, 17), (17, 18), (18, 19), (19, 20),
    (17, 0),
  ];

  final List<Hand> hands;
  final bool mirrorX;
  final int rotationDegrees;

  _HandLandmarkPainter({
    required this.hands,
    required this.mirrorX,
    required this.rotationDegrees,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty || size.isEmpty) return;

    Offset mapPoint(Landmark landmark) {
      final (uprightX, uprightY) = LiveLandmarkTransform.rotateXY(
        landmark.x,
        landmark.y,
        rotationDegrees,
      );
      final x = (mirrorX ? 1.0 - uprightX : uprightX).clamp(0.0, 1.0);
      final y = uprightY.clamp(0.0, 1.0);
      return Offset(x * size.width, y * size.height);
    }

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = const Color(0xFF3BB273)
      ..style = PaintingStyle.fill;

    final wristPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      final landmarks = hands[handIndex].landmarks;
      if (landmarks.length < 21) continue;

      final points = landmarks.map(mapPoint).toList(growable: false);

      for (final (from, to) in _connections) {
        canvas.drawLine(points[from], points[to], shadowPaint);
        canvas.drawLine(points[from], points[to], linePaint);
      }

      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(points[i], i == 0 ? 6.5 : 5.0, borderPaint);
        canvas.drawCircle(
          points[i],
          i == 0 ? 4.8 : 3.4,
          i == 0 ? wristPaint : pointPaint,
        );
      }

      final wrist = points[0];
      final label = TextPainter(
        text: TextSpan(
          text: 'H${handIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 3, color: Colors.black)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, wrist + const Offset(8, -18));
    }
  }

  @override
  bool shouldRepaint(covariant _HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.mirrorX != mirrorX ||
        oldDelegate.rotationDegrees != rotationDegrees;
  }
}
