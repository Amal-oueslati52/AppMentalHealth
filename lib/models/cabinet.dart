class Cabinet {
  final int id;
  final String? documentId;
  final String title;
  final String? description;
  final double latitude;
  final double longitude;
  final String? openTime;
  final String? closeTime;

  Cabinet({
    required this.id,
    this.documentId,
    required this.title,
    this.description,
    required this.latitude,
    required this.longitude,
    this.openTime,
    this.closeTime,
  });

  factory Cabinet.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    final address = attributes['adress'] ?? {};

    return Cabinet(
      id: int.parse(json['id'].toString()),
      documentId: attributes['documentId'] ?? json['documentId'] ?? '',
      title: attributes['title']?.toString() ?? 'Sans titre',
      description: attributes['description']?.toString(),
      latitude: _parseDouble(address['latitude']),
      longitude: _parseDouble(address['longitude']),
      openTime: attributes['openTime']?.toString(),
      closeTime: attributes['closeTime']?.toString(),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}
