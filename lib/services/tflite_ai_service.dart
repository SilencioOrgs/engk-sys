import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import '../models/detected_sign.dart';
import '../models/frame_landmarks.dart';
import 'ai_service.dart';

/// Production implementation of [AIService] using the real CNN-LSTM TFLite
/// model trained on Filipino Sign Language data.
///
/// Model contract (from esenyas_model_metadata.json):
///   Input  : [1, 45, 126]  float32  — batch=1, 45 frames, 126 features/frame
///   Output : [1, 105]      float32  — softmax over 105 Filipino FSL classes
///   126 features = 2 hands x 21 landmarks x 3 coords (x,y,z), wrist-relative
///
/// Use [recognizeFromBuffer] with a [List<FrameLandmarks>] collected over a
/// ~4-second capture window. [recognizeGesture] satisfies the interface but
/// returns null — the screen owns the capture loop.
class TFLiteAIService implements AIService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  HandLandmarkerPlugin? _handPlugin;

  // ── Model constants (must match training config exactly) ──
  static const int _numFrames = 45;
  static const int _landmarksPerHand = 21;
  static const int _coordsPerLandmark = 3;
  static const int _maxHands = 2;
  static const int _featuresPerFrame =
      _maxHands * _landmarksPerHand * _coordsPerLandmark; // 126
  static const double _confidenceThreshold = 0.60;
  static const double _activePadding = 0.08; // 8% padding each side

  /// Provides access to the MediaPipe hand landmark stream.
  /// The screen subscribes to [handPlugin.landmarkStream] and feeds
  /// each [CameraImage] via [handPlugin.processFrame].
  HandLandmarkerPlugin get handPlugin => _handPlugin!;

  // ──────────────────────────────────────────────────────────
  // AIService interface
  // ──────────────────────────────────────────────────────────

  @override
  Future<void> initialize() async {
    // Load TFLite interpreter from bundled asset.
    _interpreter = await Interpreter.fromAsset(
      'assets/models/esenyas_model.tflite',
    );

    // Load Filipino label list (105 lines, index = class ID).
    final raw = await rootBundle.loadString('assets/models/labels.txt');
    _labels = raw.trim().split('\n').map((l) => l.trim()).toList();

    // Set up MediaPipe Hand Landmarker (2 hands, GPU preferred).
    _handPlugin = HandLandmarkerPlugin.create(
      numHands: _maxHands,
      minHandDetectionConfidence: 0.5,
      delegate: HandLandmarkerDelegate.gpu,
    );
  }

  /// Not used by the screen directly — the screen owns the capture loop.
  /// Kept to satisfy [AIService] interface.
  @override
  Future<DetectedSign?> recognizeGesture() async => null;

  @override
  Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _handPlugin?.dispose();
    _handPlugin = null;
  }

  // ──────────────────────────────────────────────────────────
  // Core recognition method
  // ──────────────────────────────────────────────────────────

  /// Runs the full preprocessing pipeline on [buffer] and returns the
  /// predicted [DetectedSign], or null if:
  ///   - No hands were detected in any frame, or
  ///   - Top softmax probability < [_confidenceThreshold] (60%).
  ///
  /// Preprocessing steps (must match Python training exactly):
  ///   1. Active-window trimming with 8% padding.
  ///   2. Uniform resample to 45 frames (linspace nearest-index).
  ///   3. Sort hands by wrist x-position ascending (leftmost = slot 0).
  ///   4. Wrist-relative normalization (subtract landmark[0] from all).
  ///   5. Zero-vector fill for missing hands.
  ///   6. Flatten to [1, 45, 126] float32 input tensor.
  ///   7. TFLite inference → softmax [1, 105].
  Future<DetectedSign?> recognizeFromBuffer(List<FrameLandmarks> buffer) async {
    if (_interpreter == null || buffer.isEmpty) return null;

    // ── Step 1: Active-window trimming ──
    final firstDetected = buffer.indexWhere((f) => f.handDetected);
    if (firstDetected == -1) return null; // No hands in entire capture

    final lastDetected = buffer.lastIndexWhere((f) => f.handDetected);
    final pad = (buffer.length * _activePadding).round();
    final windowStart = (firstDetected - pad).clamp(0, buffer.length - 1);
    final windowEnd = (lastDetected + pad).clamp(0, buffer.length - 1);
    final window = buffer.sublist(windowStart, windowEnd + 1);

    if (window.isEmpty) return null;

    // ── Step 2: Uniform resample to _numFrames (45) frames ──
    // Equivalent to numpy.linspace(0, window_len-1, 45).astype(int)
    final int wLen = window.length;
    final sampledFrames = List.generate(_numFrames, (i) {
      final idx = wLen == 1
          ? 0
          : (i * (wLen - 1) / (_numFrames - 1)).round().clamp(0, wLen - 1);
      return window[idx];
    });

    // ── Steps 3-5: Build [1, 45, 126] input tensor ──
    final inputData = List.generate(_numFrames, (frameIdx) {
      return _processFrame(sampledFrames[frameIdx]);
    });

    // Wrap in batch dimension: shape [1, 45, 126]
    final input = [inputData];

    // ── Step 6: Run TFLite inference ──
    // Output shape: [1, 105]
    final output = [List.filled(_labels.length, 0.0)];
    _interpreter!.run(input, output);

    // ── Step 7: Argmax + threshold ──
    final scores = output[0];
    int maxIdx = 0;
    for (int i = 1; i < scores.length; i++) {
      if (scores[i] > scores[maxIdx]) maxIdx = i;
    }
    final topScore = scores[maxIdx];

    if (topScore < _confidenceThreshold) return null;

    return DetectedSign(
      sign: maxIdx < _labels.length ? _labels[maxIdx] : 'UNKNOWN',
      confidence: (topScore * 100).round(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────

  /// Converts a single [FrameLandmarks] into a flat 126-float feature vector.
  ///
  /// Hand ordering: sorted by wrist x-position ascending (leftmost = slot 0).
  /// Missing hands: filled with 63 zeros (zero-vector strategy).
  /// Normalization: each landmark is subtracted by the wrist landmark (index 0).
  List<double> _processFrame(FrameLandmarks frame) {
    final features = List.filled(_featuresPerFrame, 0.0);
    if (!frame.handDetected || frame.hands.isEmpty) return features;

    // Sort hands by wrist (landmark 0) x-position ascending.
    // Do NOT use handedness label — x-position only, per training contract.
    final sorted = List.of(frame.hands)
      ..sort((a, b) => a[0][0].compareTo(b[0][0])); // a[0][0] = wrist.x

    for (int slot = 0; slot < _maxHands; slot++) {
      if (slot >= sorted.length) break; // remaining slots stay zero
      final hand = sorted[slot]; // hand: List<List<double>>, 21 x [x,y,z]

      final wristX = hand[0][0];
      final wristY = hand[0][1];
      final wristZ = hand[0][2];

      final slotOffset = slot * _landmarksPerHand * _coordsPerLandmark;
      for (int lm = 0; lm < _landmarksPerHand; lm++) {
        final base = slotOffset + lm * _coordsPerLandmark;
        features[base]     = hand[lm][0] - wristX; // x - wrist.x
        features[base + 1] = hand[lm][1] - wristY; // y - wrist.y
        features[base + 2] = hand[lm][2] - wristZ; // z - wrist.z
      }
    }
    return features;
  }
}
