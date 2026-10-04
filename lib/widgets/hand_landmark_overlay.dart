import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

/// Draws MediaPipe landmarks in the same sensor-space transform used by the
/// hand_landmarker package example, adapted for a BoxFit.cover camera preview.
///
/// This is display-only. Model-input normalization happens separately.
class HandLandmarkOverlay extends StatelessWidget {
  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  const HandLandmarkOverlay({
    super.key,
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HandLandmarkPainter(
          hands: hands,
          previewSize: previewSize,
          lensDirection: lensDirection,
          sensorOrientation: sensorOrientation,
        ),
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
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  _HandLandmarkPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty || size.isEmpty || previewSize.isEmpty) return;

    // CameraPreview is rendered upright with width=previewSize.height and
    // height=previewSize.width, then center-cropped with BoxFit.cover.
    final displayedSourceWidth = previewSize.height;
    final displayedSourceHeight = previewSize.width;
    final scale = math.max(
      size.width / displayedSourceWidth,
      size.height / displayedSourceHeight,
    );

    final pointBorder = Paint()
      ..color = Colors.black.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = const Color(0xFF3BB273)
      ..style = PaintingStyle.fill;

    final wristPaint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    final lineShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..strokeWidth = 5 / scale
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2 / scale
      ..strokeCap = StrokeCap.round;

    canvas.save();

    // Match the transform used by hand_landmarker/example/lib/main.dart.
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    final logicalWidth = previewSize.width;
    final logicalHeight = previewSize.height;

    Offset pointFor(Landmark landmark) {
      return Offset(
        (landmark.x - 0.5) * logicalWidth,
        (landmark.y - 0.5) * logicalHeight,
      );
    }

    for (var handIndex = 0; handIndex < hands.length; handIndex++) {
      final landmarks = hands[handIndex].landmarks;
      if (landmarks.length < 21) continue;

      final points = landmarks.map(pointFor).toList(growable: false);

      for (final (from, to) in _connections) {
        canvas.drawLine(points[from], points[to], lineShadow);
        canvas.drawLine(points[from], points[to], linePaint);
      }

      for (var i = 0; i < points.length; i++) {
        final outerRadius = (i == 0 ? 6.5 : 5.0) / scale;
        final innerRadius = (i == 0 ? 4.8 : 3.4) / scale;
        canvas.drawCircle(points[i], outerRadius, pointBorder);
        canvas.drawCircle(
          points[i],
          innerRadius,
          i == 0 ? wristPaint : pointPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.lensDirection != lensDirection ||
        oldDelegate.sensorOrientation != sensorOrientation;
  }
}
