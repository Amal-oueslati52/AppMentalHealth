import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:app/services/strapi_auth_service.dart';

class BookingService {
  final AuthService _authService = AuthService();
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.1.11:1337/api'
      : 'http://localhost:1337/api';

  final Logger logger = Logger();

  // Centralisation des en-têtes avec gestion améliorée du token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _authService.getAuthToken();
    if (token == null) {
      throw Exception('User not logged in');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Gestion d'erreur améliorée
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
      rethrow; // Propager l'erreur pour une meilleure gestion
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
      // Structure correcte pour Strapi
      final body = json.encode({
        'data': {
          'date': dateTime.toUtc().toIso8601String(),
          'users_permissions_user': userID,
          'cabinet': cabinetId,
          'state': 'PENDING'
        }
      });

      logger.i('Creating reservation with body: $body');

      final response = await http
          .post(
            Uri.parse('$baseUrl/reservations'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        logger.e('Reservation failed with status: ${response.statusCode}');
        logger.e('Response body: ${response.body}');
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
