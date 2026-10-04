import 'dart:math';
import '../models/detected_sign.dart';
import '../utils/constants.dart';
import 'ai_service.dart';

/// Mock implementation of [AIService] for frontend‐only development.
///
/// Returns random FSL words with simulated confidence values.
/// This is clearly a mock — it must NEVER be presented as real AI recognition.
class MockAIService implements AIService {
  final _random = Random();

  @override
  Future<void> initialize() async {
    // No model to load in mock mode.
  }

  @override
  Future<DetectedSign?> recognizeGesture() async {
    final word = kMockSignWords[_random.nextInt(kMockSignWords.length)];
    final confidence = 85 + _random.nextInt(14); // 85–98 %
    return DetectedSign(sign: word, confidence: confidence);
  }

  @override
  Future<void> dispose() async {
    // Nothing to release.
  }
}
