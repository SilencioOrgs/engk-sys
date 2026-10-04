import '../models/detected_sign.dart';

/// Abstract interface for gesture recognition.
///
/// During frontend development [MockAIService] is used.
/// When the real CNN-LSTM TensorFlow Lite model is ready,
/// implement [AIService] without changing any UI code.
abstract class AIService {
  /// Perform a single recognition cycle.
  ///
  /// Returns a [DetectedSign] with the recognised gesture label
  /// and a confidence score (0-100), or `null` if nothing was detected.
  Future<DetectedSign?> recognizeGesture();

  /// Initialise / load the underlying model.
  Future<void> initialize();

  /// Release model resources.
  Future<void> dispose();
}
