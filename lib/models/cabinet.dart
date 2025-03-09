class Cabinet {
  final String name;
  final double latitude;
  final double longitude;
  final String? description;

  Cabinet({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.description,
  });
}