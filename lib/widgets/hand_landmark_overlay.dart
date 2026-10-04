import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

/// Draws the exact MediaPipe hand landmarks received by the app on top of the
/// camera preview. This widget is visualization-only: [mirrorX] affects only
/// the overlay so a mirrored front-camera preview can line up with the points.
/// It never changes the landmark values sent to the model.
class HandLandmarkOverlay extends StatelessWidget {
  final List<Hand> hands;
  final Size sourceSize;
  final bool mirrorX;

  const HandLandmarkOverlay({
    super.key,
    required this.hands,
    required this.sourceSize,
    required this.mirrorX,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HandLandmarkPainter(
          hands: hands,
          sourceSize: sourceSize,
          mirrorX: mirrorX,
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
  final Size sourceSize;
  final bool mirrorX;

  _HandLandmarkPainter({
    required this.hands,
    required this.sourceSize,
    required this.mirrorX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty || sourceSize.isEmpty || size.isEmpty) return;

    final scale = math.max(
      size.width / sourceSize.width,
      size.height / sourceSize.height,
    );
    final fittedWidth = sourceSize.width * scale;
    final fittedHeight = sourceSize.height * scale;
    final offsetX = (size.width - fittedWidth) / 2;
    final offsetY = (size.height - fittedHeight) / 2;

    Offset mapPoint(Landmark landmark) {
      final x = mirrorX ? 1.0 - landmark.x : landmark.x;
      return Offset(
        offsetX + x * fittedWidth,
        offsetY + landmark.y * fittedHeight,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

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
        canvas.drawLine(points[from], points[to], linePaint);
      }

      for (var i = 0; i < points.length; i++) {
        canvas.drawCircle(
          points[i],
          i == 0 ? 5 : 3.5,
          i == 0 ? wristPaint : pointPaint,
        );
      }

      final wrist = points[0];
      final label = TextPainter(
        text: TextSpan(
          text: 'H${handIndex + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, wrist + const Offset(7, -14));
    }
  }

  @override
  bool shouldRepaint(covariant _HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.sourceSize != sourceSize ||
        oldDelegate.mirrorX != mirrorX;
  }
}
