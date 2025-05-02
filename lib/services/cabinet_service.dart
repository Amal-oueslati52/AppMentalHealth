import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cabinet.dart';
import 'package:logger/logger.dart';

class CabinetService {
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.11:1337/api'
      : 'http://localhost:1337/api';

  final logger = Logger();

  Future<List<Cabinet>> fetchCabinets() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/cabinets?populate=*"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        logger.d('Parsed JSON: $jsonResponse');

        if (jsonResponse.containsKey('data')) {
          final List<dynamic> cabinetsData = jsonResponse['data'];
          return cabinetsData.map((cabinet) {
            final attributes = cabinet['attributes'] ?? {};
            final adress = attributes['adress'] ?? {};

            return Cabinet(
              id: int.parse(cabinet['id'].toString()),
              documentId: attributes['documentId']?.toString(),
              title: attributes['title'] ?? '',
              description: attributes['description'] ?? '',
              latitude: adress['latitude']?.toDouble() ?? 0.0,
              longitude: adress['longitude']?.toDouble() ?? 0.0,
              openTime: attributes['openTime']?.toString(),
              closeTime: attributes['closeTime']?.toString(),
            );
          }).toList();
        } else {
          throw Exception('No data found in response');
        }
      } else {
        throw Exception('Failed to load cabinets: ${response.statusCode}');
      }
    } catch (e) {
      logger.e('Error fetching cabinets:', error: e);
      return [];
    }
  }

  Future<Cabinet?> fetchCabinetById(String id) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/cabinets/$id?populate=*"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final cabinetData = jsonResponse['data'];

        if (cabinetData != null) {
          final attributes = cabinetData['attributes'] ?? {};
          final adress = attributes['adress'] ?? {};

          return Cabinet(
            id: int.parse(cabinetData['id'].toString()),
            documentId: attributes['documentId']?.toString(),
            title: attributes['title'] ?? '',
            description: attributes['description'] ?? '',
            latitude: adress['latitude']?.toDouble() ?? 0.0,
            longitude: adress['longitude']?.toDouble() ?? 0.0,
            openTime: attributes['openTime']?.toString(),
            closeTime: attributes['closeTime']?.toString(),
          );
        }
      }
      return null;
    } catch (e) {
      logger.e('Error fetching cabinet:', error: e);
      return null;
    }
  }
}
