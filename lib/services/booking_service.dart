import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'strapi_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BookingService {
  final String baseUrl = Platform.isAndroid
      ? dotenv.env['API_URL_ANDROID']!
      : dotenv.env['API_URL_IOS']!;

  final Logger logger = Logger();
  final AuthService _authService = AuthService();

  // Centralisation des en-têtes avec gestion améliorée du token
  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) {
        throw Exception('No authentication token available');
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

  // Créer une réservation avec tous les champs nécessaires
  Future<bool> createReservation({
    required String userID,
    required int cabinetId,
    required DateTime dateTime,
    required String consultationType,
    required String paymentStatus,
  }) async {
    try {
      final headers = await _getHeaders();
      print(
          '📝 Creating reservation - Cabinet: $cabinetId, User: $userID, DateTime: ${dateTime.toIso8601String()}');

      final body = json.encode({
        'data': {
          'users_permissions_user': userID,
          'cabinet': cabinetId,
          'date': dateTime.toIso8601String(),
          'Consultation_type': consultationType,
          'payment_status': paymentStatus.toUpperCase(),
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
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('📥 Bookings response data structure: ${responseData.keys}');

        if (responseData['data'] != null) {
          final List<dynamic> bookings = responseData['data'];
          print('📊 Number of bookings: ${bookings.length}');

          if (bookings.isNotEmpty) {
            print('🔍 Raw booking data example: ${bookings[0]}');
            // Transform the data to include attributes
            final transformedData = bookings
                .map((booking) => {'id': booking['id'], 'attributes': booking})
                .toList();

            return {'data': transformedData, 'meta': responseData['meta']};
          }
        }
        return responseData;
      }

      print('❌ Failed to fetch bookings: ${response.body}');
      throw Exception('Error fetching bookings: ${response.body}');
    } catch (e) {
      print('❌ Error fetching bookings: $e');
      return {
        'data': [],
        'meta': {
          'pagination': {'page': 1, 'pageCount': 1, 'total': 0}
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
        print('❌ Failed to cancel reservation: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error canceling reservation: $e');
      return false;
    }
  }

  // Vérifier le statut du paiement d'une réservation
  Future<String?> checkPaymentStatus(String documentId) async {
    try {
      final headers = await _getHeaders();

      // Use direct access with documentId
      final url = Uri.parse('$baseUrl/reservations/$documentId');
      print('🔍 Checking payment status URL: $url');
      final response = await http.get(url, headers: headers);
      final responseData = json.decode(response.body);

      print('📝 Payment status response: ${response.body}');

      if (response.statusCode == 200 && responseData['data'] != null) {
        final status = responseData['data']['payment_status'];
        print('✅ Payment status retrieved: $status');
        return status;
      }

      print('❌ Failed to check payment status: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error checking payment status: $e');
      return null;
    }
  }

  // Mettre à jour le statut de paiement
  Future<bool> updatePaymentStatus(String documentId, String status) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl/reservations/$documentId');

      print('🔍 Updating payment status:');
      print('- documentId: $documentId');
      print('- status: $status');

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode({
          'data': {'payment_status': status.toUpperCase()}
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Payment status updated successfully');
        return true;
      }

      print('❌ Failed to update payment status: ${response.body}');
      return false;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }
}
