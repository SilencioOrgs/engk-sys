/// Represents a single detected sign gesture with its confidence score.
class DetectedSign {
  final String sign;
  final int confidence;

  const DetectedSign({
    required this.sign,
    required this.confidence,
  });
}
