import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import '../models/detected_sign.dart';
import '../models/frame_landmarks.dart';
import 'ai_service.dart';

/// Result of running the golden self-test against assets/test/golden.json.
class GoldenResult {
  final bool passed;
  final double seqDiff;
  final double probDiff;
  final String topLabel;
  final String expectedTop;
  final bool topMatches;
  final String? error;

  const GoldenResult({
    required this.passed,
    required this.seqDiff,
    required this.probDiff,
    required this.topLabel,
    required this.expectedTop,
    required this.topMatches,
    this.error,
  });
}

/// Production implementation of [AIService] using the real CNN-LSTM TFLite
/// model trained on Filipino Sign Language data.
///
/// Model contract (from esenyas_model_metadata.json):
///   Input  : [1, 45, 126]  float32  — batch=1, 45 frames, 126 features/frame
///   Output : [1, 105]      float32  — softmax over 105 Filipino FSL classes
///   126 features = 2 hands x 21 landmarks x 3 coords (x,y,z), wrist-relative
///
/// Preprocessing matches the verified Colab pipeline exactly.
class TFLiteAIService implements AIService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  HandLandmarkerPlugin? _handPlugin;

  // ── Model constants (must match training config exactly) ──
  static const int numFrames = 45;
  static const double activePadding = 0.08;
  static const int minActiveFrames = 8;
  /// Debug switch. Must stay false (Colab FLIP=False). Only flip it for an A/B test.
  static const bool mirrorInputX = false;
  static const double confidenceThreshold = 0.60;

  // ── Debug metrics ──
  List<MapEntry<String, double>> _lastTop3 = const [];
  int _lastActiveFrames = 0;

  List<MapEntry<String, double>> get lastTop3 => _lastTop3;
  int get lastActiveFrames => _lastActiveFrames;
  List<String> get labels => _labels;

  /// Provides access to the MediaPipe hand landmark stream.
  /// The screen subscribes to [handPlugin.landmarkStream] and feeds
  /// each [CameraImage] via [handPlugin.processFrame].
  HandLandmarkerPlugin get handPlugin => _handPlugin!;

  // ──────────────────────────────────────────────────────────
  // Pure static preprocessing functions (unit testable)
  // ──────────────────────────────────────────────────────────

  static List<double> frameFeatures(FrameLandmarks frame, {bool mirrorX = false}) {
    final out = List<double>.filled(126, 0.0);
    if (!frame.handDetected || frame.hands.isEmpty) return out;
    final hands = [
      for (final h in frame.hands)
        [for (final p in h) [mirrorX ? 1.0 - p[0] : p[0], p[1], p[2]]]
    ];
    hands.sort((a, b) => a[0][0].compareTo(b[0][0])); // wrist x ascending
    for (var slot = 0; slot < 2 && slot < hands.length; slot++) {
      final h = hands[slot];
      final w = h[0];
      for (var lm = 0; lm < 21; lm++) {
        final o = slot * 63 + lm * 3;
        out[o]     = h[lm][0] - w[0];
        out[o + 1] = h[lm][1] - w[1];
        out[o + 2] = h[lm][2] - w[2];
      }
    }
    return out;
  }

  /// Returns 45 x 126, or null when there are too few frames with hands.
  static List<List<double>>? buildSequence(List<FrameLandmarks> buffer,
      {bool mirrorX = false}) {
    final active = [
      for (var i = 0; i < buffer.length; i++)
        if (buffer[i].handDetected && buffer[i].hands.isNotEmpty) i
    ];
    if (active.length < minActiveFrames) return null;
    final feats = [for (final f in buffer) frameFeatures(f, mirrorX: mirrorX)];
    final span = active.last - active.first + 1;
    final pad = (activePadding * span).round();
    final a = (active.first - pad).clamp(0, feats.length - 1);
    final b = (active.last + pad).clamp(0, feats.length - 1);
    final step = (b - a) / (numFrames - 1);
    return List.generate(numFrames, (i) {
      final idx = i == numFrames - 1 ? b : (a + i * step).floor();
      return feats[idx];
    });
  }

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
    _labels = raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    // Set up MediaPipe Hand Landmarker (2 hands, GPU preferred).
    _handPlugin = HandLandmarkerPlugin.create(
      numHands: 2,
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
  // Core recognition & model execution
  // ──────────────────────────────────────────────────────────

  /// Runs the TFLite interpreter with input [seq] and returns the softmax output.
  List<double> runModel(List<List<double>> seq) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Interpreter is not initialized');
    }
    final output = [List<double>.filled(_labels.length, 0.0)];
    interpreter.run([seq], output);
    return output[0];
  }

  /// Runs the full preprocessing pipeline on [buffer] and returns the
  /// predicted [DetectedSign], or null if:
  ///   - Buffer has fewer than [minActiveFrames] active frames, or
  ///   - Top softmax probability < [confidenceThreshold] (60%).
  Future<DetectedSign?> recognizeFromBuffer(List<FrameLandmarks> buffer) async {
    if (_interpreter == null || buffer.isEmpty) return null;

    final activeCount = buffer
        .where((f) => f.handDetected && f.hands.isNotEmpty)
        .length;
    _lastActiveFrames = activeCount;

    final seq = buildSequence(buffer, mirrorX: mirrorInputX);
    if (seq == null) {
      _lastTop3 = const [];
      return null;
    }

    final scores = runModel(seq);

    // Top 3 entries (ignores threshold)
    final indexed = List.generate(
      scores.length,
      (i) => MapEntry(_labels[i], scores[i]),
    )..sort((a, b) => b.value.compareTo(a.value));
    _lastTop3 = indexed.take(3).toList();

    if (indexed.isEmpty) return null;

    final top = indexed.first;
    if (top.value < confidenceThreshold) return null;

    return DetectedSign(
      sign: top.key,
      confidence: (top.value * 100).round(),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Golden self-test
  // ──────────────────────────────────────────────────────────

  /// Runs the golden self-test against assets/test/golden.json:
  ///   a) loads the asset; converts frames to `List<FrameLandmarks>`;
  ///   b) seqDiff = max abs difference between buildSequence(frames) and golden.sequence;
  ///   c) runs the model on golden.sequence; probDiff = max abs difference vs golden.probs;
  ///      topMatches = label equals golden.top;
  ///   d) PASS only if `seqDiff < 1e-4` AND `probDiff < 1e-3` AND topMatches.
  Future<GoldenResult> runGoldenSelfTest() async {
    if (_interpreter == null) {
      return const GoldenResult(
        passed: false,
        seqDiff: 1.0,
        probDiff: 1.0,
        topLabel: 'NONE',
        expectedTop: 'UNKNOWN',
        topMatches: false,
        error: 'Interpreter not initialized',
      );
    }

    final jsonStr = await rootBundle.loadString('assets/test/golden.json');
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final rawFrames = data['frames'] as List<dynamic>;

    final frames = rawFrames.map<FrameLandmarks>((frameJson) {
      final handsList = frameJson as List<dynamic>;
      if (handsList.isEmpty) {
        return const FrameLandmarks.noHand();
      }
      final hands = handsList.map<List<List<double>>>((handJson) {
        final lms = handJson as List<dynamic>;
        return lms.map<List<double>>((ptJson) {
          final pt = ptJson as List<dynamic>;
          return [
            (pt[0] as num).toDouble(),
            (pt[1] as num).toDouble(),
            (pt[2] as num).toDouble(),
          ];
        }).toList();
      }).toList();
      return FrameLandmarks(handDetected: true, hands: hands);
    }).toList();

    final builtSeq = buildSequence(frames, mirrorX: mirrorInputX);
    if (builtSeq == null) {
      return GoldenResult(
        passed: false,
        seqDiff: 1.0,
        probDiff: 1.0,
        topLabel: 'NONE',
        expectedTop: data['top'] as String,
        topMatches: false,
        error: 'buildSequence returned null',
      );
    }

    final goldenSeq = (data['sequence'] as List<dynamic>)
        .map((row) => (row as List<dynamic>).map((v) => (v as num).toDouble()).toList())
        .toList();

    double seqDiff = 0.0;
    for (int i = 0; i < numFrames; i++) {
      for (int j = 0; j < 126; j++) {
        final diff = (builtSeq[i][j] - goldenSeq[i][j]).abs();
        if (diff > seqDiff) seqDiff = diff;
      }
    }

    final goldenProbs = (data['probs'] as List<dynamic>)
        .map((v) => (v as num).toDouble())
        .toList();
    final expectedTop = data['top'] as String;

    final modelProbs = runModel(goldenSeq);

    double probDiff = 0.0;
    int maxIdx = 0;
    for (int i = 0; i < modelProbs.length; i++) {
      final diff = (modelProbs[i] - goldenProbs[i]).abs();
      if (diff > probDiff) probDiff = diff;
      if (modelProbs[i] > modelProbs[maxIdx]) {
        maxIdx = i;
      }
    }

    final topLabel = maxIdx < _labels.length ? _labels[maxIdx] : 'UNKNOWN';
    final topMatches = topLabel == expectedTop;

    final passed = seqDiff < 1e-4 && probDiff < 1e-3 && topMatches;

    return GoldenResult(
      passed: passed,
      seqDiff: seqDiff,
      probDiff: probDiff,
      topLabel: topLabel,
      expectedTop: expectedTop,
      topMatches: topMatches,
    );
  }
}
