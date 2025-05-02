import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/cabinet.dart';
import 'strapi_auth_service.dart';

class DoctorCabinetService {
  final AuthService _authService = AuthService();
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.11:1337/api'
      : 'http://localhost:1337/api';

  final Logger logger = Logger();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAuthToken();
    if (token == null) {
      throw Exception('Doctor not logged in');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Cabinet> createCabinet({
    required String title,
    required String description,
    required String openTime,
    required String closeTime,
    required double latitude,
    required double longitude,
    required String doctorId,
  }) async {
    try {
      // Validate time format
      final timeRegex =
          RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]\.[0-9]{3}$');

      if (!timeRegex.hasMatch(openTime) || !timeRegex.hasMatch(closeTime)) {
        throw Exception('Invalid time format, expected HH:mm:ss.SSS');
      }

      final headers = await _getHeaders();
      final body = json.encode({
        'data': {
          'title': title,
          'description': description,
          'openTime': openTime,
          'closeTime': closeTime,
          'adress': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'doctor': doctorId, // Simple ID reference for Strapi v4
        }
      });

      final response = await http.post(
        Uri.parse('$baseUrl/cabinets'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        final attributes = data['attributes'] ?? {};
        final adress = attributes['adress'] ?? {};
        return Cabinet(
          id: int.parse(data['id'].toString()),
          title: attributes['title'] ?? '',
          description: attributes['description'] ?? '',
          latitude: adress['latitude'] ?? 0.0,
          longitude: adress['longitude'] ?? 0.0,
          openTime: attributes['openTime'],
          closeTime: attributes['closeTime'],
        );
      } else {
        final error = json.decode(response.body);
        throw Exception(
            'Failed to create cabinet: ${error['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      logger.e('Error creating cabinet: $e');
      rethrow;
    }
  }

  Future<List<Cabinet>> getDoctorCabinets(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
            '$baseUrl/cabinets?filters[doctor][\$eq]=$doctorId&populate=*'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        return data.map((cabinet) {
          final attributes = cabinet['attributes'] ?? {};
          final adress = attributes['adress'] ?? {};
          return Cabinet(
            id: int.parse(cabinet['id'].toString()),
            title: attributes['title'] ?? '',
            description: attributes['description'] ?? '',
            latitude: adress['latitude'] ?? 0.0,
            longitude: adress['longitude'] ?? 0.0,
            openTime: attributes['openTime'],
            closeTime: attributes['closeTime'],
          );
        }).toList();
      } else {
        throw Exception('Failed to load doctor cabinets');
      }
    } catch (e) {
      logger.e('Error fetching doctor cabinets: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCabinetReservations(
      String cabinetId) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      print('🔍 Fetching reservations for cabinet: $cabinetId');

      // Correction de la requête Strapi v4
      final url = Uri.parse('$baseUrl/reservations?populate=*&' +
              'filters[cabinet][id][\$eq]=$cabinetId&' +
              'sort[0]=date:desc')
          .toString();

      print('🔗 Request URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Response status: ${response.statusCode}');
      print('📊 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch reservations');
      }

      final responseData = json.decode(response.body);
      final List<dynamic> reservationsData = responseData['data'] ?? [];

      final reservations = reservationsData.map((item) {
        final attributes = item['attributes'] ?? {};
        final userData =
            attributes['users_permissions_user']?['data']?['attributes'] ?? {};

        return {
          'id': item['id'],
          'date': attributes['date'],
          'state': attributes['state'],
          'users_permissions_user': {
            'username': userData['username'] ?? userData['email'] ?? 'Inconnu',
            'email': userData['email'] ?? '',
          }
        };
      }).toList();

      print('📋 Parsed ${reservations.length} reservations');
      return reservations;
    } catch (e, stackTrace) {
      print('❌ Error in getCabinetReservations: $e');
      print('🔍 Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> updateReservationStatus(
      String reservationId, String newStatus) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/reservations/$reservationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': {
            'state': newStatus,
          }
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating reservation status: $e');
    }
  }
}
