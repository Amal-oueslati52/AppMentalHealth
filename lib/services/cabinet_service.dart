import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cabinet.dart';

class CabinetService {
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.208.250:1337/api'
      : 'http://localhost:1337/api';

  Future<List<Cabinet>> fetchCabinets() async {
    try {
      print('🔍 Fetching all cabinets');

      final response = await http.get(
        Uri.parse("$baseUrl/cabinets?populate=*"),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        print('📦 Raw response: $jsonResponse');

        if (jsonResponse.containsKey('data')) {
          final List<dynamic> cabinetsData = jsonResponse['data'];
          final List<Cabinet> cabinets = [];

          for (var cabinetData in cabinetsData) {
            try {
              final cabinet = Cabinet.fromJson(cabinetData);
              print(
                  '✅ Added cabinet: ${cabinet.title} at ${cabinet.latitude}, ${cabinet.longitude}');
              cabinets.add(cabinet);
            } catch (e) {
              print('❌ Error parsing cabinet: $e');
              continue;
            }
          }

          print('📋 Total valid cabinets: ${cabinets.length}');
          return cabinets;
        }
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
}
