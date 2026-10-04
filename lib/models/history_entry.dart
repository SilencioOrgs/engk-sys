import 'detected_sign.dart';

/// Represents a completed translation session stored in history.
class HistoryEntry {
  final int id;
  final String translatedSentence;
  final List<DetectedSign> detectedSigns;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.translatedSentence,
    required this.detectedSigns,
    required this.timestamp,
  });
}
