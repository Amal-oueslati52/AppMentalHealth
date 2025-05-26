import 'dart:io';
import '../models/assessment_session.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/services/strapi_auth_service.dart';

class AssessmentStorageService {
  final String _baseUrl = Platform.isAndroid
      ? 'http://192.168.1.242:1337/api'
      : 'http://localhost:1337/api';

  Future<bool> checkPatientExists(String patientId) async {
    try {
      print('🔍 Checking patient existence for ID: $patientId');
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/patients?filters[users_permissions_user][id]=$patientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final exists = (data['data'] as List).isNotEmpty;
        print('✅ Patient exists: $exists');
        return exists;
      }
      print('❌ Failed to check patient existence: ${response.statusCode}');
      return false;
    } catch (e) {
      print('❌ Error checking patient: $e');
      return false;
    }
  }

  Future<String?> getPatientDocumentId(String userId) async {
    try {
      print('🔍 Getting patient document ID for user ID: $userId');
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/patients?filters[users_permissions_user][id]=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['data'] as List).isNotEmpty) {
          final patient = data['data'][0];
          final documentId = patient['id'].toString();
          print('✅ Found patient document ID: $documentId');
          return documentId;
        }
      }
      print('❌ No patient document found');
      return null;
    } catch (e) {
      print('❌ Error getting patient document ID: $e');
      return null;
    }
  }

  Future<void> saveSession(AssessmentSession session) async {
    try {
      if (session.userId.isEmpty) {
        print('❌ Error: User ID is empty');
        throw Exception('User ID cannot be empty');
      }

      final patientDocumentId = await _getPatientDocumentId(session.userId);
      if (patientDocumentId == null) {
        throw Exception('Patient profile not found');
      }

      final authToken = await AuthService().getAuthToken();
      if (authToken == null) {
        throw Exception('No auth token found');
      }

      // Simplified payload without timestamp - let Strapi handle it
      final payload = {
        'data': {
          'type': 'ASSESSMENT',
          'message': {
            'text': session.report // Le message principal
          },
          'patient': patientDocumentId, // ID direct sans connect array
        }
      };

      print('📤 Sending assessment payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode(payload),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save assessment: ${response.statusCode}');
      }

      print('✅ Assessment saved successfully');
    } catch (e, stackTrace) {
      print('❌ Error saving assessment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to save assessment: $e');
    }
  }

  Future<String?> _getPatientDocumentId(String userId) async {
    try {
      print('🔍 Getting patient document ID for user: $userId');

      // Obtenir le token d'authentification
      final authToken = await AuthService().getAuthToken();
      if (authToken == null) {
        throw Exception('No auth token found');
      }

      final response = await http.get(
        Uri.parse(
            '$_baseUrl/patients?filters[users_permissions_user][id]=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      print('📥 Patient API Response: ${response.body}');

      if (response.statusCode == 403) {
        throw Exception('Authentication required');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch patient data: ${response.statusCode}');
      }

      final data = json.decode(response.body);

      if (data == null || !data.containsKey('data')) {
        print('❌ Invalid API response structure');
        return null;
      }

      final List<dynamic> patients = data['data'] ?? [];
      if (patients.isEmpty) {
        print('❌ No patient found for user ID: $userId');
        return null;
      }

      final patientId = patients[0]['id']?.toString();
      print('✅ Found patient document ID: $patientId');
      return patientId;
    } catch (e) {
      print('❌ Error getting patient document ID: $e');
      return null;
    }
  }
}
