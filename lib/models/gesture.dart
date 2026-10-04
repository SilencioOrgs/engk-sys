/// Represents a single FSL gesture in the Gesture Guide.
class Gesture {
  final String name;
  final String description;
  final String? tip;
  final String imageUrl;

  const Gesture({
    required this.name,
    required this.description,
    this.tip,
    required this.imageUrl,
  });
}
