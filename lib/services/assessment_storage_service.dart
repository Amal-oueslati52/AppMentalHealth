import 'dart:io';
import '../models/assessment_session.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:app/services/strapi_auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AssessmentStorageService {
  final String _baseUrl = Platform.isAndroid
      ? dotenv.env['API_URL_ANDROID']!
      : dotenv.env['API_URL_IOS']!;

  // Cache for patient document IDs to reduce API calls
  final Map<String, String> _patientDocIdCache = {};

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
    // Check cache first
    if (_patientDocIdCache.containsKey(userId)) {
      return _patientDocIdCache[userId];
    }

    try {
      print('🔍 Getting patient document ID for user ID: $userId');
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
      if (patientId != null) {
        // Cache the ID for future use
        _patientDocIdCache[userId] = patientId;
        print('✅ Found and cached patient document ID: $patientId');
      }
      return patientId;
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

      final patientDocumentId = await getPatientDocumentId(session.userId);
      if (patientDocumentId == null) {
        throw Exception('Patient profile not found');
      }

      final authToken = await AuthService().getAuthToken();
      if (authToken == null) {
        throw Exception('No auth token found');
      } // Structured payload according to Strapi's content-type schema
      final payload = {
        'data': {
          'type': 'ASSESSMENT',
          'message': {
            'data': {
              'text': session.report,
              'conversation': session.conversation
                  .map((m) => {'content': m.content, 'isUser': m.isUser})
                  .toList(),
            }
          },
          'patient': {'id': int.parse(patientDocumentId)},
          'publishedAt': DateTime.now().toIso8601String(),
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
      print(
          '✅ Assessment saved successfully for patient ID: $patientDocumentId');
    } catch (e, stackTrace) {
      print('❌ Error saving assessment: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to save assessment: $e');
    }
  }

  // Improve the history retrieval to focus on reports
  Future<List<Map<String, dynamic>>> getAssessmentHistory(String userId) async {
    try {
      print('🔍 Fetching assessment history for user: $userId');
      final authToken = await AuthService().getAuthToken();
      if (authToken == null) throw Exception('No auth token found');

      final patientDocumentId = await getPatientDocumentId(userId);
      if (patientDocumentId == null) throw Exception('Patient not found');
      final response = await http.get(
        Uri.parse(
            '$_baseUrl/conversations?populate=*&filters[type]=ASSESSMENT&filters[patient][id]=$patientDocumentId&sort=createdAt:desc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Assessment history response: ${response.body}');

        if (data == null || !data.containsKey('data')) {
          print('❌ Invalid API response structure - missing data field');
          return [];
        }

        final List<Map<String, dynamic>> assessments =
            List<Map<String, dynamic>>.from(data['data'] ?? []);

        print('✅ Retrieved ${assessments.length} assessment reports');
        print(
            '📊 First assessment structure (if any): ${assessments.isNotEmpty ? json.encode(assessments.first) : "none"}');

        return assessments;
      }

      print('❌ Failed to fetch assessments: ${response.statusCode}');
      print('📥 Error response body: ${response.body}');
      return [];
    } catch (e) {
      print('❌ Error fetching assessment history: $e');
      return [];
    }
  }
}
