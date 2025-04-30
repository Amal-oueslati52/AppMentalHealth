import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cabinet.dart';

class CabinetService {
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.11:1337/api'
      : 'http://localhost:1337/api';

  Future<List<Cabinet>> fetchCabinets() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/cabinets")).timeout(
          const Duration(seconds: 20)); // Augmentez la durée du timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('Parsed JSON: $jsonResponse');

        if (jsonResponse.containsKey('data')) {
          final List<dynamic> cabinetsData = jsonResponse['data'];
          return cabinetsData.map((cabinet) {
            final adress = cabinet['adress'];
            double latitude = 0.0;
            double longitude = 0.0;
            if (adress != null) {
              latitude = adress['latitude']?.toDouble() ?? 0.0;
              longitude = adress['longitude']?.toDouble() ?? 0.0;
            }
            return Cabinet(
              // id: cabinet['id'] ?? '',
              id: int.parse(cabinet['id'].toString()),
              documentId: cabinet['documentId'] ?? '',
              title: cabinet['title'] ?? '',
              latitude: latitude,
              longitude: longitude,
              description: cabinet['description'] ?? '',
            );
          }).toList();
        } else {
          throw Exception('No data found in response');
        }
      } else {
        throw Exception('Failed to load cabinets: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('Error fetching cabinets: $e');
      print('Stacktrace: $stacktrace');
      return [];
    }
  }
}
