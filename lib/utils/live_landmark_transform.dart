import 'package:hand_landmarker/hand_landmarker.dart';

/// Converts live camera landmarks from the raw camera sensor coordinate space
/// into the same upright portrait coordinate space used by the preview and by
/// the Colab video pipeline.
///
/// Uploaded videos must NOT use this transform because they are already decoded
/// upright before MediaPipe VIDEO-mode inference.
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
