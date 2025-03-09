import '../models/cabinet.dart';

class CabinetService {
  Future<List<Cabinet>> fetchCabinets() async {
    // Simulate API delay
    await Future.delayed(Duration(seconds: 5));

    // Return mock data (will be replaced with actual API call later)
    List<Cabinet> cabinetsList = [
      Cabinet(
        name: 'Cabinet Beb Saadoun',
        longitude: 36.809019,
        latitude: 10.149182,
        description: 'Cabinet médical à Beb Saadoun',
      ),
      Cabinet(
        name: 'Cabinet Ras Tabia',
        latitude: 36.819857,
        longitude: 10.151501,
        description: 'Cabinet de psychologue à Ras Tabia',
      ),
      Cabinet(
        name: 'Cabinet psychologue Los Angeles',
        latitude: 35.0522,
        longitude: -118.900,
        description: 'Cabinet psychologue à Los Angeles',
      ),
    ];

    return cabinetsList;
  }
}
