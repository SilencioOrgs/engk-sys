import 'package:hand_landmarker/hand_landmarker.dart';

/// Coordinate transforms for live-camera MediaPipe landmarks.
///
/// The app UI stays portrait, but the trained model was validated with
/// landscape 16:9 video. On the test phone, recognition works when the device
/// is physically rotated landscape-left (top edge toward the user's left).
/// Therefore live portrait landmarks are rotated 90° clockwise for MODEL INPUT
/// only, reproducing that successful landscape-left coordinate space.
///
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

  static List<List<List<double>>> toTrainingLandscapeRawHands(
    List<Hand> hands,
  ) {
    return hands.map((hand) {
      return hand.landmarks.map((landmark) {
        // Portrait device -> equivalent of physically rotating the phone
        // landscape-left: image/model coordinates rotate clockwise 90°.
        final (x, y) = rotateXY(landmark.x, landmark.y, 90);
        return <double>[x, y, landmark.z];
      }).toList();
    }).toList();
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
