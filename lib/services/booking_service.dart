import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'strapi_auth_service.dart';

class BookingService {
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.242:1337/api'
      : 'http://localhost:1337/api';

  final Logger logger = Logger();
  final AuthService _authService = AuthService();

  // Centralisation des en-têtes avec gestion améliorée du token
  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) {
        print('⚠️ No auth token found');
        throw Exception('Authentication required');
      }

      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    } catch (e) {
      print('❌ Error getting headers: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  // Récupérer les créneaux disponibles
  Future<List<DateTime>> fetchAvailableDatetimes(String cabinetId) async {
    try {
      final headers = await _getHeaders();
      print('🔍 Fetching cabinet details and available times');

      // Get cabinet details with its documentId
      final url = Uri.parse('$baseUrl/cabinets').replace(
        queryParameters: {'filters[id][\$eq]': cabinetId, 'populate': '*'},
      );

      print('🔗 Fetching cabinet URL: $url');
      final cabinetResponse = await http.get(url, headers: headers);
      print('📥 Cabinet response: ${cabinetResponse.body}');

      if (cabinetResponse.statusCode != 200) {
        print('❌ Failed to fetch cabinet: ${cabinetResponse.body}');
        return [];
      }

      final responseData = json.decode(cabinetResponse.body);
      if (responseData['data'] == null || responseData['data'].isEmpty) {
        print('❌ No cabinet found with ID: $cabinetId');
        return [];
      }

      final cabinetData = responseData['data'][0];
      final documentId = cabinetData['documentId'];

      if (documentId == null) {
        print('❌ Cabinet has no documentId');
        return [];
      }

      print('📝 Found cabinet documentId: $documentId');

      // Now fetch available times using documentId
      final timesUrl = Uri.parse('$baseUrl/available-datetimes/$documentId');
      print('🔗 Fetching times URL: $timesUrl');

      final response = await http
          .get(
            timesUrl,
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('📥 Times response status: ${response.statusCode}');
      print('📥 Times response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> slots = jsonResponse['data'] as List<dynamic>;

        final availableSlots = slots
            .map((dateStr) => DateTime.tryParse(dateStr.toString()))
            .where((date) => date != null)
            .cast<DateTime>()
            .toList();

        print('✅ Found ${availableSlots.length} available slots');
        return availableSlots;
      }

      print('❌ Failed to fetch available times: ${response.body}');
      return [];
    } catch (e) {
      print('❌ Error fetching available times: $e');
      return [];
    }
  }

  // Créer une réservation avec la bonne structure pour Strapi v4
  Future<bool> createReservation({
    required String userID,
    required int cabinetId,
    required DateTime dateTime,
  }) async {
    try {
      final headers = await _getHeaders();
      print(
          '📝 Creating reservation - Cabinet: $cabinetId, User: $userID, DateTime: ${dateTime.toIso8601String()}');

      final body = json.encode({
        'data': {
          'date': dateTime.toUtc().toIso8601String(),
          'cabinet': cabinetId,
          'users_permissions_user': userID,
          'state': 'PENDING'
        }
      });

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservations'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('✅ Reservation created successfully');
        return true;
      }

      print('❌ Failed to create reservation: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error creating reservation: $e');
      return false;
    }
  }

  // Récupérer les réservations de l'utilisateur
  Future<Map<String, dynamic>> fetchUserBookings({
    required String userID,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await _getHeaders();

      final url = Uri.parse('$baseUrl/reservations').replace(queryParameters: {
        'populate': '*',
        'filters[users_permissions_user][id][\$eq]': userID,
        'pagination[page]': page.toString(),
        'pagination[pageSize]': pageSize.toString(),
        'sort[0]': 'date:desc'
      });

      print('🔍 Fetching bookings URL: $url');

      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          "data": jsonResponse['data'] ?? [],
          "meta": jsonResponse['meta'] ?? {},
        };
      }

      throw Exception('Error fetching bookings: ${response.body}');
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      return {
        "data": [],
        "meta": {
          "pagination": {"page": 1, "pageCount": 1}
        }
      };
    }
  }

  // Annuler une réservation
  Future<bool> cancelReservation(String reservationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl/reservations/$reservationId'),
            headers: headers,
            body: json.encode({
              'data': {'state': 'CANCELED'}
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Error canceling reservation: ${response.body}');
      }
    } catch (e) {
      logger.e('Error canceling reservation: $e');
      return false;
    }
  }
}
