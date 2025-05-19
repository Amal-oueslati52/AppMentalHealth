import 'dart:io';
import '../models/assessment_session.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AssessmentStorageService {
  final String _baseUrl = Platform.isAndroid
      ? 'http://192.168.0.4:1337/api'
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
      if (session.userId.isEmpty) return;

      // First get patient ID from users_permissions_user
      final patientResponse = await http.get(
        Uri.parse(
            '$_baseUrl/patients?filters[users_permissions_user][id]=${session.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      final patientData = json.decode(patientResponse.body);
      if ((patientData['data'] as List).isEmpty) {
        throw Exception('Patient not found');
      }

      final patientDocumentId = patientData['data'][0]['id'];
      print('📝 Found patient document ID: $patientDocumentId');

      final payload = {
        'data': {
          'type': 'ASSESSMENT',
          'message': {
            'text': session.report,
            'conversation': session.conversation
                .map((m) => {'content': m.content, 'isUser': m.isUser})
                .toList(),
          },
          'patient': patientDocumentId, // Use the document ID directly
          'publishedAt': DateTime.now().toIso8601String()
        }
      };

      print('📤 Sending assessment data: $payload');

      final response = await http.post(
        Uri.parse('$_baseUrl/conversations'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save assessment: ${response.body}');
      }

      print('✅ Assessment saved successfully');
    } catch (e) {
      print('❌ Error saving assessment: $e');
      throw e;
    }
  }
}
