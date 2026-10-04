import 'gesture.dart';

/// Represents a category grouping of FSL gestures in the Gesture Guide.
class GestureCategory {
  final String category;
  final String emoji;
  final List<Gesture> gestures;

  const GestureCategory({
    required this.category,
    required this.emoji,
    required this.gestures,
  });
}
