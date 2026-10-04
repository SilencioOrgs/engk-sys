import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:hand_landmarker/hand_landmarker.dart';

/// Coordinate transforms for live-camera MediaPipe landmarks.
/// Uploaded VIDEO-mode clips must not use this transform.
class LiveLandmarkTransform {
  static (double, double) rotateXY(
    double x,
    double y,
    int rotationDegrees,
  ) {
    final rotation = ((rotationDegrees % 360) + 360) % 360;

    switch (rotation) {
      case 90:
        // Clockwise 90 degrees.
        return (1.0 - y, x);
      case 180:
        return (1.0 - x, 1.0 - y);
      case 270:
        // Clockwise 270 == counter-clockwise 90 degrees.
        return (y, 1.0 - x);
      default:
        return (x, y);
    }
  }

  /// Raw sensor-space landmarks -> the space the model was trained in:
  /// upright, NOT mirrored, landscape-equivalent normalization.
  /// NOTE: outputs are only meaningful as wrist-relative offsets and for wrist-x
  /// ordering. They are not valid absolute image positions.
  /// [rawFrameSize] = size of the CameraImage as delivered
  /// (Size(image.width, image.height)).
  static List<List<List<double>>> toTrainingSpaceRaw(
    List<List<List<double>>> hands, {
    required int sensorOrientation,
    required Size rawFrameSize,
  }) {
    final rot = ((sensorOrientation % 360) + 360) % 360;
    final swapped = rot == 90 || rot == 270;
    final upW = swapped ? rawFrameSize.height : rawFrameSize.width;
    final upH = swapped ? rawFrameSize.width : rawFrameSize.height;
    final xScale = upW / math.max(upW, upH);
    final yScale = upH / math.min(upW, upH);
    final out = <List<List<double>>>[];
    for (final hand in hands) {
      final pts = <List<double>>[];
      for (final p in hand) {
        final (ux, uy) = rotateXY(p[0], p[1], rot);
        pts.add([ux * xScale, uy * yScale, p[2]]);
      }
      out.add(pts);
    }
    return out;
  }

  static List<List<List<double>>> toTrainingSpace(
    List<Hand> hands, {
    required int sensorOrientation,
    required Size rawFrameSize,
  }) => toTrainingSpaceRaw(
    [
      for (final h in hands)
        [
          for (final l in h.landmarks) [l.x, l.y, l.z],
        ],
    ],
    sensorOrientation: sensorOrientation,
    rawFrameSize: rawFrameSize,
  );

  static List<List<List<double>>> toUprightRawHands(
    List<Hand> hands,
    int rotationDegrees,
  ) {
    return hands.map((hand) {
      return hand.landmarks.map((landmark) {
        final (x, y) = rotateXY(
          landmark.x,
          landmark.y,
          rotationDegrees,
        );
        return <double>[x, y, landmark.z];
      }).toList();
    }).toList();
  }
}
