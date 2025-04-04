class Cabinet {
  final int id;
  final String documentId;
  final String title;
  final double latitude;
  final double longitude;
  final String? description;

  Cabinet({
    required this.id,
    required this.documentId,
    required this.title,
    required this.latitude,
    required this.longitude,
    this.description,
  });
  factory Cabinet.fromJson(Map<String, dynamic> json) {
    final adress = json['adress'] as Map<String, dynamic>?;
    return Cabinet(
      id: json['id'] ?? 0,
      documentId: json['documentId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      latitude: adress?['latitude']?.toDouble() ?? 0.0,
      longitude: adress?['longitude']?.toDouble() ?? 0.0,
      description: 'ID: ${json['documentId']}',
    );
  }
}
