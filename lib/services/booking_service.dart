import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class BookingService {
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.17:1337/api'
      : 'http://localhost:1337/api';

  final Logger logger = Logger();

  // Centralisation des en-têtes avec gestion améliorée du token
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
    };
  }

  // Récupérer les créneaux disponibles
  Future<List<DateTime>> fetchAvailableDatetimes(String documentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl/available-datetimes/$documentId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'] as List<dynamic>? ?? [];
        return data
            .map((dateStr) => DateTime.parse(dateStr.toString()))
            .toList();
      } else {
        throw Exception('Failed to load available datetimes: ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching available datetimes: $e');
      return [];
    }
  }

  // Créer une réservation
  Future<bool> createReservation({
    required String userID,
    required int cabinetId,
    required DateTime dateTime,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'data': {
          'date': dateTime.toUtc().toIso8601String(),
          'cabinet': {'id': cabinetId},
          'state': 'PENDING',
          'users_permissions_user': {'id': int.parse(userID)},
        }
      });

      logger.i('Request Body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservations'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        logger.w('Unauthorized: Retrying with refreshed token');
        final newHeaders = await _getHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/reservations'),
          headers: newHeaders,
          body: body,
        );
        return retryResponse.statusCode == 201;
      } else {
        throw Exception('Error creating reservation: ${response.body}');
      }
    } catch (e) {
      logger.e('Error creating reservation: $e');
      return false;
    }
  }

  // Récupérer les réservations d'un utilisateur avec pagination
  Future<Map<String, dynamic>> fetchUserBookings({
    required String userID,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse(
                '$baseUrl/reservations?populate=cabinet&filters[user][id][\$eq]=$userID&page=$page&pageSize=$pageSize'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          "data": jsonResponse['data'] as List<dynamic>,
          "meta": jsonResponse['meta'] as Map<String, dynamic>,
        };
      } else {
        throw Exception('Error fetching bookings: ${response.body}');
      }
    } catch (e) {
      logger.e('Error fetching bookings: $e');
      return {"data": [], "meta": {}};
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
