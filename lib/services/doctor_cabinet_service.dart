import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/cabinet.dart';
import 'strapi_auth_service.dart';

class DoctorCabinetService {
  final AuthService _authService = AuthService();
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.0.4:1337/api'
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

  String _formatTimeForAPI(String time) {
    try {
      if (RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]\.[0-9]{3}$')
          .hasMatch(time)) {
        return time;
      }
      if (RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$').hasMatch(time)) {
        return '$time:00.000';
      }
      if (RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9]):[0-5][0-9]$')
          .hasMatch(time)) {
        return '$time.000';
      }
      throw Exception(
          'Format d\'heure invalide. Utilisez HH:mm (exemple: 09:30)');
    } catch (e) {
      throw Exception(
          'Format d\'heure invalide. Utilisez HH:mm (exemple: 09:30)');
    }
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
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/cabinets'),
        headers: headers,
        body: json.encode({
          'data': {
            'title': title,
            'description': description,
            'openTime': _formatTimeForAPI(openTime),
            'closeTime': _formatTimeForAPI(closeTime),
            'adress': {'latitude': latitude, 'longitude': longitude},
            'doctor': doctorId
          }
        }),
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
      }
      throw Exception(
          'Failed to create cabinet: ${json.decode(response.body)['error']?['message']}');
    } catch (e) {
      logger.e('Error creating cabinet: $e');
      rethrow;
    }
  }

  Future<List<Cabinet>> getDoctorCabinets(String doctorId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/cabinets').replace(queryParameters: {
        'populate': '*',
        'filters[doctor]': doctorId,
      });

      final response = await http.get(url, headers: headers);

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
      }
      throw Exception('Failed to load doctor cabinets: ${response.statusCode}');
    } catch (e) {
      logger.e('Error fetching cabinets: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCabinetReservations(
      String cabinetId) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final url = Uri.parse('$baseUrl/reservations').replace(queryParameters: {
        'populate': '*',
        'filters[cabinet][id][\$eq]': cabinetId,
        'sort[0]': 'date:desc'
      });

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch reservations');
      }

      final List<dynamic> reservationsData =
          json.decode(response.body)['data'] ?? [];
      return reservationsData
          .map((item) => {
                'id': item['id'],
                'documentId': item['documentId'] ?? '',
                'date': item['date'],
                'state': item['state'] ?? 'PENDING',
                'users_permissions_user': {
                  'username': item['users_permissions_user']?['username'] ??
                      item['users_permissions_user']?['email'] ??
                      'Inconnu',
                  'email': item['users_permissions_user']?['email'] ?? '',
                }
              })
          .toList();
    } catch (e) {
      logger.e('Error fetching reservations: $e');
      return [];
    }
  }

  Future<bool> updateReservationStatus(
      String documentId, String newStatus) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      final response = await http.put(
        Uri.parse('$baseUrl/reservations/$documentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'data': {'state': newStatus.toUpperCase()}
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      logger.e('Error updating reservation status: $e');
      return false;
    }
  }
}
