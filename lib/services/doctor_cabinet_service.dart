import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import '../models/cabinet.dart';
import 'strapi_auth_service.dart';

class DoctorCabinetService {
  final AuthService _authService = AuthService();
  final String baseUrl = Platform.isAndroid
      ? 'http://192.168.0.5:1337/api'
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
      // Si le format est déjà HH:mm:ss.000, le retourner tel quel
      if (RegExp(r'^([0-1][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]\.[0-9]{3}$')
          .hasMatch(time)) {
        return time;
      }

      // Si le format est HH:mm, le convertir en HH:mm:ss.000
      if (RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9])$').hasMatch(time)) {
        return '$time:00.000';
      }

      // Extraire HH:mm de HH:mm:ss
      if (RegExp(r'^([0-1][0-9]|2[0-3]):([0-5][0-9]):[0-5][0-9]$')
          .hasMatch(time)) {
        return '$time.000';
      }

      print('❌ Format invalide reçu: $time');
      throw Exception(
          'Format d\'heure invalide. Utilisez HH:mm (exemple: 09:30)');
    } catch (e) {
      print('❌ Erreur de formatage: $e');
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
    required String doctorId, // Maintenant ceci sera le documentId
  }) async {
    try {
      print('📝 Times reçus - Open: $openTime, Close: $closeTime');

      final formattedOpenTime = _formatTimeForAPI(openTime);
      final formattedCloseTime = _formatTimeForAPI(closeTime);

      print(
          '✅ Times formatés - Open: $formattedOpenTime, Close: $formattedCloseTime');

      final headers = await _getHeaders();

      print('👨‍⚕️ Creating cabinet for doctor DocumentID: $doctorId');

      // Structure Strapi v4 correcte pour la relation bidirectionnelle
      final body = json.encode({
        'data': {
          'title': title,
          'description': description,
          'openTime': formattedOpenTime,
          'closeTime': formattedCloseTime,
          'adress': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'doctor': doctorId // Utilisation directe du documentId
        }
      });

      print('📤 Envoi de la requête avec body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/cabinets'),
        headers: headers,
        body: body,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

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
      print(
          '🔍 Tentative de récupération des cabinets pour le docteur: $doctorId');

      // Modification de la requête pour le filtre
      final url = Uri.parse('$baseUrl/cabinets').replace(queryParameters: {
        'populate': '*',
        'filters[doctor]': doctorId, // Simplification du filtre
      });

      print('🔗 URL de requête: $url');

      final response = await http.get(url, headers: headers);

      print('📊 Status de la réponse: ${response.statusCode}');
      print('📊 Contenu de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'] as List;

        final cabinets = data.map((cabinet) {
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

        print('✅ Nombre de cabinets trouvés: ${cabinets.length}');
        return cabinets;
      } else {
        print('❌ Erreur ${response.statusCode}: ${response.body}');
        throw Exception(
            'Failed to load doctor cabinets: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('❌ Exception lors de la récupération des cabinets: $e');
      print('🔍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCabinetReservations(
      String cabinetId) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      print('🔍 Fetching reservations for cabinet: $cabinetId');

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

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch reservations');
      }

      final responseData = json.decode(response.body);
      final List<dynamic> reservationsData = responseData['data'] ?? [];

      final reservations = reservationsData.map((item) {
        print('🔍 Processing reservation item: $item');

        // The data is directly in the item, not in attributes
        final date = item['date'];
        final documentId = item['documentId'];
        final state = item['state'];
        final userData = item['users_permissions_user'] ?? {};

        print('📅 Extracted date: $date');
        print('🔑 Extracted documentId: $documentId');

        return {
          'id': item['id'],
          'documentId': documentId ?? '',
          'date': date,
          'state': state ?? 'PENDING',
          'users_permissions_user': {
            'username': userData['username'] ?? userData['email'] ?? 'Inconnu',
            'email': userData['email'] ?? '',
          }
        };
      }).toList();

      print(
          '📋 Parsed reservations: ${reservations.map((r) => 'id: ${r['id']}, date: ${r['date']}, documentId: ${r['documentId']}').join('\n')}');
      return reservations;
    } catch (e, stackTrace) {
      print('❌ Error in getCabinetReservations: $e');
      print('🔍 Stack trace: $stackTrace');
      return [];
    }
  }

  Future<bool> updateReservationStatus(
      String documentId, String newStatus) async {
    try {
      final token = await _authService.getAuthToken();
      if (token == null) throw Exception('No authentication token found');

      print(
          '📝 Updating reservation status - DocumentID: $documentId, Status: $newStatus');

      final updateUrl = Uri.parse('$baseUrl/reservations/$documentId');
      final body = json.encode({
        'data': {'state': newStatus.toUpperCase()}
      });

      print('🔗 Update URL: $updateUrl');
      print('📤 Update body: $body');

      final response = await http.put(
        updateUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to update reservation: ${response.body}');
      }

      return true;
    } catch (e) {
      print('❌ Error updating reservation status: $e');
      return false;
    }
  }
}
