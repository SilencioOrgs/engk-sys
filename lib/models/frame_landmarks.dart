/// Holds the raw landmark data captured for a single camera frame.
///
/// This class is intentionally decoupled from the hand_landmarker package so
/// that [TFLiteAIService] has no transitive import of the camera plugin.
/// Conversion from [List<Hand>] to [FrameLandmarks] happens in the screen layer.
class FrameLandmarks {
  /// Whether at least one hand was detected in this frame.
  final bool handDetected;

  /// Up to 2 detected hands.
  ///
  /// Each inner list represents one hand:
  ///   - length == 21  (one entry per MediaPipe landmark)
  ///   - each entry is [x, y, z] as normalized floats (x, y in 0.0-1.0)
  ///
  /// Ordering within this list is the raw plugin order — sorting by
  /// wrist x-position is done in [TFLiteAIService.recognizeFromBuffer].
  /// Empty when [handDetected] is false.
  final List<List<List<double>>> hands;

  const FrameLandmarks({
    required this.handDetected,
    required this.hands,
  });

  /// Convenience constructor for a frame where no hands were detected.
  /// The frame still contributes to the sequence (zero-vector strategy).
  const FrameLandmarks.noHand()
      : handDetected = false,
        hands = const [];
}
